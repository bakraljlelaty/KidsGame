import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/settings/app_settings.dart';
import 'sound_effects.dart';
import 'voice_catalog.dart';

/// What games and screens use to make sound. The real implementation is
/// [AudioManager]; tests inject [NoopGameAudio].
abstract class GameAudio {
  Future<void> playEffect(SoundEffect effect);
  Future<void> playInstruction(VoiceInstruction instruction);
}

class NoopGameAudio implements GameAudio {
  final List<SoundEffect> effects = [];
  final List<VoiceInstruction> instructions = [];

  @override
  Future<void> playEffect(SoundEffect effect) async => effects.add(effect);

  @override
  Future<void> playInstruction(VoiceInstruction instruction) async =>
      instructions.add(instruction);
}

/// Central audio service: one looping music channel, one voice channel that
/// never overlaps itself, and a small pool of effect players. Pauses with
/// the app lifecycle and disposes cleanly.
class AudioManager implements GameAudio {
  AudioManager();

  static const double _musicVolume = 0.35;
  static const double _effectVolume = 0.85;
  static const double _voiceVolume = 1.0;
  static const int _effectPoolSize = 3;

  final AudioPlayer _music = AudioPlayer(playerId: 'lww_music');
  final AudioPlayer _voice = AudioPlayer(playerId: 'lww_voice');
  final List<AudioPlayer> _effects = [
    for (var i = 0; i < _effectPoolSize; i++) AudioPlayer(playerId: 'lww_fx$i'),
  ];
  int _nextEffect = 0;

  bool _musicEnabled = true;
  bool _effectsEnabled = true;
  bool _voiceEnabled = true;
  String _languageCode = 'en';

  MusicTrack? _currentTrack;
  bool _musicPausedByLifecycle = false;
  bool _disposed = false;

  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(respectSilence: true).build(),
      );
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(_musicVolume);
      await _voice.setVolume(_voiceVolume);
      for (final p in _effects) {
        await p.setVolume(_effectVolume);
        await p.setReleaseMode(ReleaseMode.stop);
      }
      await preload();
    } catch (e) {
      // Audio must never break the app (e.g. emulator without sound).
      debugPrint('AudioManager init failed: $e');
    }
  }

  /// Warms the asset cache for the small, frequently used files.
  Future<void> preload() async {
    try {
      await AudioCache.instance.loadAll([
        for (final effect in SoundEffect.values) effect.assetPath,
        for (final track in MusicTrack.values) track.assetPath,
      ]);
    } catch (e) {
      debugPrint('Audio preload failed: $e');
    }
  }

  void applySettings(AppSettings settings) {
    _effectsEnabled = settings.soundEffectsEnabled;
    _voiceEnabled = settings.voiceEnabled;
    _languageCode = settings.languageCode;
    final musicWasEnabled = _musicEnabled;
    _musicEnabled = settings.musicEnabled;
    if (!_musicEnabled) {
      _safe(() => _music.pause());
    } else if (!musicWasEnabled && _currentTrack != null) {
      _safe(() => _music.resume());
    }
  }

  Future<void> playMusic(MusicTrack track) async {
    _currentTrack = track;
    if (!_musicEnabled || _disposed) return;
    await _safe(() async {
      await _music.stop();
      await _music.play(AssetSource(track.assetPath), volume: _musicVolume);
    });
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    await _safe(() => _music.stop());
  }

  @override
  Future<void> playEffect(SoundEffect effect) async {
    if (!_effectsEnabled || _disposed) return;
    final player = _effects[_nextEffect];
    _nextEffect = (_nextEffect + 1) % _effects.length;
    await _safe(() async {
      await player.stop();
      await player.play(AssetSource(effect.assetPath), volume: _effectVolume);
    });
  }

  /// Plays a voice instruction, stopping any instruction already speaking so
  /// voices never overlap.
  @override
  Future<void> playInstruction(VoiceInstruction instruction) async {
    if (!_voiceEnabled || _disposed) return;
    await _safe(() async {
      await _voice.stop();
      await _voice.play(
        AssetSource(VoiceCatalog.assetPath(instruction, _languageCode)),
        volume: _voiceVolume,
      );
    });
  }

  Future<void> stopVoice() => _safe(() => _voice.stop());

  /// Call when the app goes to the background.
  Future<void> onAppPaused() async {
    await _safe(() => _voice.stop());
    if (_currentTrack != null && _musicEnabled) {
      _musicPausedByLifecycle = true;
      await _safe(() => _music.pause());
    }
  }

  /// Call when the app returns to the foreground.
  Future<void> onAppResumed() async {
    if (_musicPausedByLifecycle && _musicEnabled && _currentTrack != null) {
      await _safe(() => _music.resume());
    }
    _musicPausedByLifecycle = false;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _safe(() => _music.dispose());
    await _safe(() => _voice.dispose());
    for (final p in _effects) {
      await _safe(() => p.dispose());
    }
  }

  Future<void> _safe(Future<void> Function() action) async {
    if (_disposed) return;
    try {
      await action();
    } catch (e) {
      debugPrint('AudioManager: $e');
    }
  }
}

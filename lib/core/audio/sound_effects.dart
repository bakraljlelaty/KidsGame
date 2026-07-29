/// Bundled sound-effect identifiers. Files live at
/// `assets/audio/effects/<id>.wav`; all are original, programmatically
/// generated placeholders (see tool/gen_audio.py) that can be replaced by
/// dropping in files with the same names.
enum SoundEffect {
  pop('pop'),
  chimeSuccess('chime_success'),
  chimeSoft('chime_soft'),
  boingSoft('boing_soft'),
  waterSplash('water_splash'),
  chew('chew'),
  sparkle('sparkle'),
  yawn('yawn'),
  slide('slide'),
  ding('ding'),
  celebrate('celebrate'),
  sessionReminder('session_reminder'),
  nightCalm('night_calm');

  const SoundEffect(this.fileId);

  final String fileId;

  String get assetPath => 'audio/effects/$fileId.wav';
}

/// Background music tracks at `assets/audio/music/<id>.wav`.
enum MusicTrack {
  calm('calm_loop'),
  lullaby('lullaby_loop');

  const MusicTrack(this.fileId);

  final String fileId;

  String get assetPath => 'audio/music/$fileId.wav';
}

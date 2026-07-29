import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import '../../shared/components/gentle_effects.dart';
import '../../shared/components/tap_target.dart';
import '../../shared/game/toddler_game.dart';
import 'bubble_art.dart';

/// Mini-game 2: Bubble Pop.
///
/// A calm underwater scene. Big soft bubbles, each holding a coloured
/// circle, drift slowly upward. Milo asks for one colour at a time and the
/// child pops the matching bubble; three successful pops complete the
/// activity.
///
///  * Explorer: one very large bubble at a time — always the right one.
///  * Helper: the right bubble plus [StageConfig.distractorCount] others.
///  * Little Thinker: a two-step sequence (blue, then yellow) among 3-4
///    bubbles, followed by one more colour.
class BubblePopGame extends ToddlerGame {
  BubblePopGame(super.gameContext);

  static final math.Random _random = math.Random();

  static const _fishColors = [
    Palette.softOrange,
    Palette.softPink,
    Palette.softPurple,
  ];

  final List<_Round> _rounds = [];
  int _roundIndex = 0;
  int _requestIndex = 0;
  int _totalPops = 0;

  final List<_BubbleTarget> _bubbles = [];

  /// True while a pop is being celebrated and the next request set up.
  bool _transitioning = false;

  /// True while autoAssist is about to pop the bubble for the child.
  bool _assistPending = false;

  @override
  Color backgroundColor() => Palette.underwater;

  // --------------------------------------------------------------- Setup

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(_UnderwaterBackground(size: size.clone(), animate: !reducedMotion));
    await addMilo();

    _buildRounds();
    _spawnRound();

    say(VoiceInstruction.bubbleIntro);
    add(
      TimerComponent(
        period: 2.4,
        removeOnFinish: true,
        onTick: () {
          if (!_transitioning && !isCompleted && _totalPops == 0) {
            _announceCurrent();
          }
        },
      ),
    );

    // Occasional decorative fish drifting through the scene.
    add(
      TimerComponent(
        period: 3.5,
        removeOnFinish: true,
        onTick: _maybeSpawnAmbientFish,
      ),
    );
    add(
      TimerComponent(
        period: 9,
        repeat: true,
        onTick: _maybeSpawnAmbientFish,
      ),
    );

    startHintCountdown();
  }

  /// Three pops per play-through, arranged by stage.
  void _buildRounds() {
    if (stage.usesSequences) {
      // Little Thinker: "pop blue... then yellow!", then one more colour.
      final third = _random.nextBool() ? BubbleHue.red : BubbleHue.green;
      _rounds.add(
        _Round(
          hues: [...BubbleHue.values],
          requests: const [BubbleHue.blue, BubbleHue.yellow],
        ),
      );
      final distractors = BubbleHue.values.where((h) => h != third).toList()
        ..shuffle(_random);
      _rounds.add(
        _Round(
          hues: [third, ...distractors.take(stage.distractorCount)],
          requests: [third],
        ),
      );
    } else {
      // Explorer / Helper: three single requests in a shuffled colour order.
      final order = [...BubbleHue.values]..shuffle(_random);
      for (final hue in order.take(3)) {
        final distractors = BubbleHue.values.where((h) => h != hue).toList()
          ..shuffle(_random);
        _rounds.add(
          _Round(
            hues: [hue, ...distractors.take(stage.distractorCount)],
            requests: [hue],
          ),
        );
      }
    }
  }

  /// Bubble size: relative to the screen so phones and tablets both work,
  /// scaled up for younger stages, never below the toddler minimum.
  double get _bubbleDiameter {
    final base = size.y * 0.32 * stage.itemScale;
    return base.clamp(100.0, size.y * 0.45);
  }

  /// Horizontal play band, keeping Milo's corner clear of bubbles.
  double get _playMinX => gameContext.leftHanded ? size.x * 0.03 : 205.0;
  double get _playMaxX => gameContext.leftHanded ? size.x - 205.0 : size.x * 0.97;

  void _spawnRound() {
    final round = _rounds[_roundIndex];
    final diameter = _bubbleDiameter;
    final r = diameter / 2;
    final hues = [...round.hues]..shuffle(_random);
    final minX = _playMinX + r;
    final maxX = math.max(minX + 1, _playMaxX - r);
    final laneWidth = (maxX - minX) / hues.length;

    for (var i = 0; i < hues.length; i++) {
      final jitter = math.min(laneWidth * 0.14, 30.0);
      final x = (minX +
              laneWidth * (i + 0.5) +
              (_random.nextDouble() * 2 - 1) * jitter)
          .clamp(minX, maxX);
      final yFraction = hues.length == 1
          ? 0.45
          : (i.isEven ? 0.36 : 0.6) + (_random.nextDouble() - 0.5) * 0.08;
      final bubble = _BubbleTarget(
        hue: hues[i],
        position: Vector2(x, size.y * yFraction),
        diameter: diameter,
        random: _random,
      );
      bubble.onPressed = (_) => _onBubblePressed(bubble);
      _bubbles.add(bubble);
      add(bubble);
    }
  }

  // ------------------------------------------------------------ Requests

  BubbleHue? get _currentHue {
    if (_roundIndex >= _rounds.length) return null;
    final round = _rounds[_roundIndex];
    if (_requestIndex >= round.requests.length) return null;
    return round.requests[_requestIndex];
  }

  _BubbleTarget? get _currentBubble {
    final hue = _currentHue;
    if (hue == null) return null;
    for (final bubble in _bubbles) {
      if (bubble.hue == hue) return bubble;
    }
    return null;
  }

  VoiceInstruction _voiceFor(BubbleHue hue) => switch (hue) {
        BubbleHue.blue => VoiceInstruction.popBlue,
        BubbleHue.yellow => VoiceInstruction.popYellow,
        BubbleHue.red => VoiceInstruction.popRed,
        BubbleHue.green => VoiceInstruction.popGreen,
      };

  void _announceCurrent() {
    final hue = _currentHue;
    if (hue == null || isCompleted) return;
    say(_voiceFor(hue));
  }

  // ---------------------------------------------------------- Popping

  void _onBubblePressed(_BubbleTarget bubble) {
    if (isCompleted || _transitioning) return;
    if (bubble.hue == _currentHue) {
      _popCorrect(bubble);
    } else {
      bubble.wobbleGently();
      // While assist is queued the game resolves itself; no escalation.
      if (!_assistPending) handleWrongAttempt();
    }
  }

  /// Pops the requested bubble with the full happy feedback and advances
  /// the round. Used by both the child's tap and [autoAssist].
  void _popCorrect(_BubbleTarget bubble) {
    if (isCompleted || !_bubbles.contains(bubble)) return;
    _assistPending = false;
    _transitioning = true;
    _bubbles.remove(bubble);
    _totalPops++;

    registerCorrectAction();
    playEffect(SoundEffect.pop);
    gameContext.haptics.success();
    add(
      SparkleBurst(
        at: bubble.position.clone(),
        color: bubble.hue.color,
        reducedMotion: reducedMotion,
      ),
    );
    bubble.popAway();
    if (!reducedMotion) _spawnHappyFish(bubble.position.clone());

    final round = _rounds[_roundIndex];
    _requestIndex++;
    final moreInRound = _requestIndex < round.requests.length;
    final moreRounds = _roundIndex + 1 < _rounds.length;

    if (moreInRound) {
      // Sequence continues: same bubbles, next colour ("...then yellow!").
      if (_random.nextDouble() < 0.5) milo?.laugh();
      _setBubblesEnabled(false);
      add(
        TimerComponent(
          period: 0.9,
          removeOnFinish: true,
          onTick: () {
            say(VoiceInstruction.popThenNext);
            add(
              TimerComponent(
                period: 1.7,
                removeOnFinish: true,
                onTick: () {
                  _transitioning = false;
                  _setBubblesEnabled(true);
                  _announceCurrent();
                },
              ),
            );
          },
        ),
      );
    } else if (moreRounds) {
      if (_random.nextDouble() < 0.5) milo?.laugh();
      _clearRemainingBubbles();
      _roundIndex++;
      _requestIndex = 0;
      add(
        TimerComponent(
          period: 1.2,
          removeOnFinish: true,
          onTick: () {
            _spawnRound();
            _transitioning = false;
            _announceCurrent();
          },
        ),
      );
    } else {
      _clearRemainingBubbles();
      milo?.celebrate();
      add(
        TimerComponent(
          period: 0.9,
          removeOnFinish: true,
          onTick: () => completeGame(voice: VoiceInstruction.greatJob),
        ),
      );
    }
  }

  void _clearRemainingBubbles() {
    for (final bubble in [..._bubbles]) {
      bubble.driftAway();
    }
    _bubbles.clear();
  }

  void _setBubblesEnabled(bool value) {
    for (final bubble in _bubbles) {
      bubble.enabled = value;
    }
  }

  // ---------------------------------------------------------------- Fish

  void _maybeSpawnAmbientFish() {
    if (isCompleted) return;
    final ambient =
        children.whereType<_FriendlyFish>().where((f) => !f.darting).length;
    if (ambient >= 2) return;
    final movingRight = _random.nextBool();
    final fishSize = Vector2(78, 48);
    add(
      _FriendlyFish(
        start: Vector2(
          movingRight ? -fishSize.x : size.x + fishSize.x,
          size.y * (0.14 + _random.nextDouble() * 0.5),
        ),
        movingRight: movingRight,
        speed: reducedMotion ? 14 : 22 + _random.nextDouble() * 12,
        size: fishSize,
        color: _fishColors[_random.nextInt(_fishColors.length)],
        darting: false,
        bob: reducedMotion ? 0 : 8,
      ),
    );
  }

  /// A little fish darts happily past the popped bubble.
  void _spawnHappyFish(Vector2 near) {
    final movingRight = near.x < size.x * 0.55;
    final fishSize = Vector2(64, 40);
    final startX = movingRight
        ? math.max(-fishSize.x, near.x - 320)
        : math.min(size.x + fishSize.x, near.x + 320);
    add(
      _FriendlyFish(
        start: Vector2(
          startX,
          (near.y + 34).clamp(40.0, size.y - 60.0),
        ),
        movingRight: movingRight,
        speed: 190,
        size: fishSize,
        color: _fishColors[_random.nextInt(_fishColors.length)],
        darting: true,
        bob: 14,
      ),
    );
  }

  // --------------------------------------------------------------- Hints

  @override
  void showHint() {
    if (isCompleted || _transitioning) return;
    final bubble = _currentBubble;
    if (bubble == null) return;
    bubble.pulse();
    milo?.pointTowards(bubble.position.x >= size.x / 2 ? 1 : -1);
  }

  @override
  void repeatInstruction() => _announceCurrent();

  @override
  void highlightTarget() {
    if (isCompleted || _transitioning) return;
    final bubble = _currentBubble;
    if (bubble == null) return;
    bubble.showHighlight();
    _announceCurrent();
    add(
      TimerComponent(
        period: 2.8,
        removeOnFinish: true,
        onTick: bubble.hideHighlight,
      ),
    );
  }

  @override
  void autoAssist() {
    // Pop the requested bubble for the child so nobody ever gets stuck.
    if (isCompleted || _transitioning || _assistPending) return;
    final bubble = _currentBubble;
    if (bubble == null) return;
    _assistPending = true;

    milo?.pointTowards(bubble.position.x >= size.x / 2 ? 1 : -1);
    bubble.showHighlight();

    // If the bubble drifted off screen, bring it somewhere comfortable.
    final r = bubble.size.x / 2;
    if (bubble.position.y < r * 0.5 || bubble.position.y > size.y - r * 0.5) {
      bubble.relocate(
        Vector2(
          bubble.position.x.clamp(_playMinX + r, _playMaxX - r),
          size.y * 0.45,
        ),
      );
    }

    add(
      TimerComponent(
        period: 0.9,
        removeOnFinish: true,
        onTick: () {
          // The child may have popped it themselves in the meantime.
          if (!_assistPending || isCompleted) return;
          final target = _currentBubble;
          if (target != null) _popCorrect(target);
        },
      ),
    );
  }
}

/// One request set: the bubbles floating on screen and the ordered colours
/// the child pops before the set is cleared.
class _Round {
  const _Round({required this.hues, required this.requests});

  final List<BubbleHue> hues;
  final List<BubbleHue> requests;
}

/// A big, slow bubble the child can pop. Drifts gently upward with a soft
/// sine sway and re-enters from below after leaving the top of the screen.
class _BubbleTarget extends TapTarget {
  _BubbleTarget({
    required this.hue,
    required Vector2 position,
    required double diameter,
    required math.Random random,
  })  : _baseX = position.x,
        _riseSpeed = 20 + random.nextDouble() * 20,
        _swayOmega = 2 * math.pi / (4.5 + random.nextDouble() * 2),
        _swayPhase = random.nextDouble() * 2 * math.pi,
        _swayAmp = math.min(diameter * 0.09, 16),
        super(
          targetId: 'bubble_${hue.name}',
          position: position,
          size: Vector2.all(diameter),
        );

  final BubbleHue hue;

  double _baseX;
  final double _riseSpeed;
  final double _swayOmega;
  final double _swayPhase;
  final double _swayAmp;

  double _time = 0;
  double _opacity = 1;
  bool _popping = false;
  bool _fading = false;
  bool _wobbling = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!game.reducedMotion) {
      scale = Vector2.all(0.05);
      add(GentleEffects.popIn());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_fading) {
      _opacity = math.max(0, _opacity - dt / 0.25);
    }
    if (_popping) return;

    // Slow upward drift with a gentle sway; never fast.
    position.y -= (game.reducedMotion ? 10 : _riseSpeed) * dt;
    if (!game.reducedMotion) {
      position.x = _baseX + math.sin(_time * _swayOmega + _swayPhase) * _swayAmp;
    }

    // Left through the top: quietly re-enter from below.
    if (position.y < -size.y / 2 - 6) {
      position.y = game.size.y + size.y / 2 + 4;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    BubbleArt.paintBubble(
      canvas,
      size,
      hue.color,
      opacity: _opacity,
      highContrast: game.highContrast,
    );
  }

  /// Happy pop: a quick expand-and-fade, then gone.
  void popAway() {
    if (_popping) return;
    _popping = true;
    enabled = false;
    hideHighlight();
    if (game.reducedMotion) {
      removeFromParent();
      return;
    }
    _fading = true;
    add(
      ScaleEffect.by(
        Vector2.all(1.4),
        EffectController(duration: 0.25, curve: Curves.easeOut),
        onComplete: removeFromParent,
      ),
    );
  }

  /// Leftover distractors shrink softly away between rounds.
  void driftAway() {
    if (_popping) return;
    _popping = true;
    enabled = false;
    hideHighlight();
    if (game.reducedMotion) {
      removeFromParent();
      return;
    }
    _fading = true;
    add(
      ScaleEffect.to(
        Vector2.all(0.05),
        EffectController(duration: 0.4, curve: Curves.easeIn),
        onComplete: removeFromParent,
      ),
    );
  }

  /// Wrong-tap reaction: a tiny wobble, never a pop, never a scary sound.
  void wobbleGently() {
    if (_wobbling || _popping) return;
    _wobbling = true;
    add(GentleEffects.wobble());
    add(
      TimerComponent(
        period: 1.15,
        removeOnFinish: true,
        onTick: () => _wobbling = false,
      ),
    );
  }

  /// Moves the bubble (and its sway anchor) to a new spot.
  void relocate(Vector2 to) {
    position.setFrom(to);
    _baseX = to.x;
  }
}

/// A purely decorative fish: either drifting lazily across the scene or
/// darting happily past a freshly popped bubble. Never interactive.
class _FriendlyFish extends PositionComponent
    with HasGameReference<ToddlerGame> {
  _FriendlyFish({
    required Vector2 start,
    required this.movingRight,
    required this.speed,
    required Vector2 size,
    required this.color,
    required this.darting,
    required this.bob,
  })  : _baseY = start.y,
        super(
          position: start,
          size: size,
          anchor: Anchor.center,
          priority: darting ? 20 : 2,
        );

  final bool movingRight;
  final double speed;
  final Color color;
  final bool darting;
  final double bob;

  final double _baseY;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.x += (movingRight ? 1 : -1) * speed * dt;
    if (bob > 0) {
      position.y =
          _baseY + math.sin(_time * 2 * math.pi / (darting ? 0.9 : 3.2)) * bob;
    }
    if (position.x < -size.x * 1.5 ||
        position.x > game.size.x + size.x * 1.5) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    if (!movingRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    final wag = bob > 0 ? math.sin(_time * 2 * math.pi / 0.6) : 0.0;
    BubbleArt.paintFish(canvas, size, color, tailWag: wag);
    canvas.restore();
  }
}

/// Calm underwater backdrop; the only motion is a very slow seaweed sway,
/// frozen entirely under reduced motion. Zero interaction.
class _UnderwaterBackground extends PositionComponent {
  _UnderwaterBackground({required Vector2 size, required this.animate})
      : super(size: size, priority: -10);

  final bool animate;

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (animate) _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    BubbleArt.paintUnderwater(canvas, size, _time);
  }
}

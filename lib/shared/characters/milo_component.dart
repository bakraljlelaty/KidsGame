import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'milo_painter.dart';
import 'milo_state.dart';

/// Milo inside Flame game scenes.
///
/// Placeholder rendering is procedural (MiloPainter). The state API is
/// final; a sprite-sheet implementation later only swaps [render].
class MiloComponent extends PositionComponent {
  MiloComponent({
    super.position,
    Vector2? size,
    this.reducedMotion = false,
    super.anchor = Anchor.bottomCenter,
    super.priority = 50,
  }) : super(size: size ?? Vector2(110, 132));

  final bool reducedMotion;

  MiloState _state = MiloState.idle;
  MiloState get state => _state;

  bool wearsHelmet = false;

  /// -1 points left, 1 points right.
  int pointDirection = 1;

  double _time = 0;
  double _stateTimeLeft = -1;
  MiloState _revertTo = MiloState.idle;

  void setState(MiloState next) {
    _state = next;
    _stateTimeLeft = -1;
  }

  /// Enters [next] for [duration], then returns to [revertTo] (or idle).
  void setStateFor(MiloState next, Duration duration,
      {MiloState? revertTo}) {
    _state = next;
    _revertTo = revertTo ?? MiloState.idle;
    _stateTimeLeft = duration.inMilliseconds / 1000.0;
  }

  void talk({Duration duration = const Duration(seconds: 2)}) =>
      setStateFor(MiloState.talking, duration);

  void celebrate({Duration duration = const Duration(seconds: 2)}) =>
      setStateFor(MiloState.happy, duration);

  void laugh({Duration duration = const Duration(seconds: 2)}) =>
      setStateFor(MiloState.laughing, duration);

  void dance({Duration duration = const Duration(seconds: 3)}) =>
      setStateFor(MiloState.dancing, duration);

  void pointTowards(int direction,
      {Duration duration = const Duration(seconds: 3)}) {
    pointDirection = direction;
    setStateFor(MiloState.pointing, duration);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_stateTimeLeft > 0) {
      _stateTimeLeft -= dt;
      if (_stateTimeLeft <= 0) {
        _state = _revertTo;
        _stateTimeLeft = -1;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    MiloPainter.paint(
      canvas,
      Size(size.x, size.y),
      state: _state,
      time: _time,
      reducedMotion: reducedMotion,
      wearsHelmet: wearsHelmet,
      pointDirection: pointDirection,
    );
  }
}

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// Shared, deliberately calm animation building blocks. Nothing flashes,
/// nothing shakes hard, everything respects reduced-motion callers.
class GentleEffects {
  GentleEffects._();

  /// Slow grow-shrink pulse that repeats a few times (hint attention).
  static Effect attentionPulse({double by = 1.1, int repeats = 3}) =>
      SequenceEffect(
        [
          for (var i = 0; i < repeats; i++) ...[
            ScaleEffect.by(
              Vector2.all(by),
              EffectController(duration: 0.4, curve: Curves.easeInOut),
            ),
            ScaleEffect.by(
              Vector2.all(1 / by),
              EffectController(duration: 0.4, curve: Curves.easeInOut),
            ),
          ],
        ],
      );

  /// Tiny sideways wobble (funny reactions).
  static Effect wobble({double angle = 0.08, int repeats = 3}) =>
      SequenceEffect(
        [
          for (var i = 0; i < repeats; i++) ...[
            RotateEffect.by(angle, EffectController(duration: 0.09)),
            RotateEffect.by(-2 * angle, EffectController(duration: 0.18)),
            RotateEffect.by(angle, EffectController(duration: 0.09)),
          ],
        ],
      );

  /// Pop-in from small to full size (new objects appearing).
  static Effect popIn() => ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.35, curve: Curves.easeOutBack),
      );

  /// A single happy little jump.
  static Effect happyHop({double height = 22}) => SequenceEffect(
        [
          MoveByEffect(
            Vector2(0, -height),
            EffectController(duration: 0.22, curve: Curves.easeOut),
          ),
          MoveByEffect(
            Vector2(0, height),
            EffectController(duration: 0.26, curve: Curves.bounceOut),
          ),
        ],
      );
}

/// A soft, slow burst of pastel star-dust. With reduced motion it becomes a
/// single fading glow instead of moving particles.
class SparkleBurst extends Component {
  SparkleBurst({
    required this.at,
    this.color = Palette.starGold,
    this.reducedMotion = false,
    this.count = 10,
  });

  final Vector2 at;
  final Color color;
  final bool reducedMotion;
  final int count;

  static final math.Random _random = math.Random();

  @override
  Future<void> onLoad() async {
    if (reducedMotion) {
      final glow = CircleComponent(
        radius: 30,
        position: at.clone(),
        anchor: Anchor.center,
        paint: Paint()..color = color.withValues(alpha: 0.45),
        priority: 90,
      );
      glow.add(
        OpacityEffect.fadeOut(
          EffectController(duration: 0.8),
          onComplete: glow.removeFromParent,
        ),
      );
      parent?.add(glow);
      removeFromParent();
      return;
    }

    parent?.add(
      ParticleSystemComponent(
        position: at.clone(),
        priority: 90,
        particle: Particle.generate(
          count: count,
          lifespan: 1.1,
          generator: (i) {
            final angle = (i / count) * 2 * math.pi +
                _random.nextDouble() * 0.6;
            final speed = 40 + _random.nextDouble() * 55;
            return AcceleratedParticle(
              speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
              acceleration: Vector2(0, 60),
              child: CircleParticle(
                radius: 3.2 + _random.nextDouble() * 2.4,
                paint: Paint()
                  ..color = color.withValues(
                      alpha: 0.55 + _random.nextDouble() * 0.35),
              ),
            );
          },
        ),
      ),
    );
    removeFromParent();
  }
}

/// Soft pulsing radial glow used to highlight a correct destination.
class GlowHighlight extends CircleComponent {
  GlowHighlight({required double radius})
      : super(
          radius: radius,
          anchor: Anchor.center,
          priority: -1,
          paint: Paint()
            ..color = Palette.starGold.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );

  bool _dismissed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      ScaleEffect.by(
        Vector2.all(1.15),
        EffectController(
          duration: 0.7,
          reverseDuration: 0.7,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    removeFromParent();
  }
}

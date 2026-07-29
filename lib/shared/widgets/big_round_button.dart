import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme/palette.dart';

/// A very large, soft, round button for the child area. Always at least
/// [AppConfig.minTouchTarget] and reacts on tap-down for instant feedback.
class BigRoundButton extends StatefulWidget {
  const BigRoundButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.diameter = 112,
    this.color = Palette.butter,
    this.child,
    this.highContrast = false,
  });

  final VoidCallback onPressed;
  final String semanticLabel;
  final double diameter;
  final Color color;
  final Widget? child;
  final bool highContrast;

  @override
  State<BigRoundButton> createState() => _BigRoundButtonState();
}

class _BigRoundButtonState extends State<BigRoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final diameter = widget.diameter < AppConfig.minTouchTarget
        ? AppConfig.minTouchTarget
        : widget.diameter;
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.highContrast
                    ? Palette.outlineStrong
                    : Colors.white.withValues(alpha: 0.8),
                width: widget.highContrast ? 4 : 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Palette.outlineStrong.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

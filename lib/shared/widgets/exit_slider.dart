import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// Deliberate exit control for game screens: a small translucent pill whose
/// home-knob must be dragged across the track to leave. A stray toddler tap
/// does nothing (the knob just wiggles a hint), so the control can sit near
/// the play area without being triggered by mistake — and it is much
/// smaller than the old 88px button.
///
/// Screen-reader users can still activate it directly via semantics.
class ExitSlider extends StatefulWidget {
  const ExitSlider({
    super.key,
    required this.onExit,
    required this.semanticLabel,
    this.highContrast = false,
  });

  final VoidCallback onExit;
  final String semanticLabel;
  final bool highContrast;

  static const double _width = 148;
  static const double _height = 52;
  static const double _knob = 44;

  @override
  State<ExitSlider> createState() => _ExitSliderState();
}

class _ExitSliderState extends State<ExitSlider>
    with SingleTickerProviderStateMixin {
  static const double _travel =
      ExitSlider._width - ExitSlider._knob - 8;

  double _drag = 0;
  bool _fired = false;
  late final AnimationController _wiggle;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // The knob always travels toward the arrow (LTR inside the pill).
    setState(() =>
        _drag = (_drag + details.delta.dx).clamp(0.0, _travel));
    if (!_fired && _drag >= _travel * 0.92) {
      _fired = true;
      widget.onExit();
    }
  }

  void _onDragEnd([_]) {
    if (!_fired) setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      onTap: widget.onExit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _wiggle.forward(from: 0),
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _onDragEnd,
        child: Container(
          width: ExitSlider._width,
          height: ExitSlider._height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: widget.highContrast
                  ? Palette.outlineStrong
                  : Colors.white.withValues(alpha: 0.8),
              width: widget.highContrast ? 3 : 2,
            ),
          ),
          child: Stack(
            children: [
              // Destination arrow at the far end of the track.
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 26,
                    color: Palette.textSoft.withValues(alpha: 0.8),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _wiggle,
                builder: (context, child) {
                  final hint = Curves.elasticIn
                          .transform(1 - _wiggle.value) *
                      0;
                  final wiggleOffset = _wiggle.isAnimating
                      ? (8 *
                          (1 - _wiggle.value) *
                          (1 - _wiggle.value) *
                          ((_wiggle.value * 20).floor().isEven ? 1 : -1))
                      : 0.0;
                  return Positioned(
                    left: 4 + _drag + wiggleOffset + hint,
                    top: 4,
                    child: child!,
                  );
                },
                child: Container(
                  width: ExitSlider._knob,
                  height: ExitSlider._knob,
                  decoration: BoxDecoration(
                    color: Palette.butter,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 26,
                    color: Palette.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

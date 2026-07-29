import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'milo_painter.dart';
import 'milo_state.dart';

/// Milo as a Flutter widget (home screen, dashboards, overlays).
class MiloView extends StatefulWidget {
  const MiloView({
    super.key,
    required this.state,
    this.size = const Size(160, 190),
    this.reducedMotion = false,
    this.wearsHelmet = false,
    this.pointDirection = 1,
  });

  final MiloState state;
  final Size size;
  final bool reducedMotion;
  final bool wearsHelmet;
  final int pointDirection;

  @override
  State<MiloView> createState() => _MiloViewState();
}

class _MiloViewState extends State<MiloView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMilliseconds / 1000.0);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: widget.size,
        painter: _MiloCustomPainter(
          state: widget.state,
          time: _time,
          reducedMotion: widget.reducedMotion,
          wearsHelmet: widget.wearsHelmet,
          pointDirection: widget.pointDirection,
        ),
      ),
    );
  }
}

class _MiloCustomPainter extends CustomPainter {
  _MiloCustomPainter({
    required this.state,
    required this.time,
    required this.reducedMotion,
    required this.wearsHelmet,
    required this.pointDirection,
  });

  final MiloState state;
  final double time;
  final bool reducedMotion;
  final bool wearsHelmet;
  final int pointDirection;

  @override
  void paint(Canvas canvas, Size size) {
    MiloPainter.paint(
      canvas,
      size,
      state: state,
      time: time,
      reducedMotion: reducedMotion,
      wearsHelmet: wearsHelmet,
      pointDirection: pointDirection,
    );
  }

  @override
  bool shouldRepaint(_MiloCustomPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.state != state ||
      oldDelegate.wearsHelmet != wearsHelmet;
}

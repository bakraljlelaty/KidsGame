import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme/palette.dart';

/// The parent gate's first barrier: both top corners of the screen must be
/// held at the same time for three seconds. Trivial for an adult reading
/// the parent guide, essentially impossible for a two-year-old to do by
/// accident.
class ParentCornerGate extends StatefulWidget {
  const ParentCornerGate({
    super.key,
    required this.onUnlocked,
    required this.semanticLabel,
  });

  final VoidCallback onUnlocked;
  final String semanticLabel;

  @override
  State<ParentCornerGate> createState() => _ParentCornerGateState();
}

class _ParentCornerGateState extends State<ParentCornerGate> {
  bool _leftHeld = false;
  bool _rightHeld = false;
  Timer? _holdTimer;
  bool _showProgress = false;

  void _updateHold() {
    if (_leftHeld && _rightHeld) {
      _holdTimer ??= Timer(AppConfig.parentGateHold, () {
        _holdTimer = null;
        if (mounted) {
          setState(() => _showProgress = false);
          widget.onUnlocked();
        }
      });
      setState(() => _showProgress = true);
    } else {
      _holdTimer?.cancel();
      _holdTimer = null;
      if (_showProgress) setState(() => _showProgress = false);
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  Widget _corner({required bool isLeft}) {
    return Semantics(
      label: widget.semanticLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          isLeft ? _leftHeld = true : _rightHeld = true;
          _updateHold();
        },
        onPointerUp: (_) {
          isLeft ? _leftHeld = false : _rightHeld = false;
          _updateHold();
        },
        onPointerCancel: (_) {
          isLeft ? _leftHeld = false : _rightHeld = false;
          _updateHold();
        },
        child: SizedBox(
          width: 96,
          height: 96,
          child: Center(
            child: Icon(
              Icons.shield_moon_outlined,
              size: 20,
              color: Palette.outline.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _corner(isLeft: true)),
          Positioned(top: 0, right: 0, child: _corner(isLeft: false)),
          if (_showProgress)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Palette.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

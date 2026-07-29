import 'package:flutter/services.dart';

/// Gentle, optional haptic feedback. Only ever light impacts — no heavy
/// buzzes, and nothing at all when the parent turns haptics off.
class AppHaptics {
  AppHaptics({this.enabled = true});

  bool enabled;

  void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }

  void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}

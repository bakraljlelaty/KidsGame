import 'package:flutter/material.dart';

/// Gentle screen transitions for the child area. Uses a soft fade (or an
/// instant switch when reduced motion is on) — never sharp slides.
class GentlePageRoute<T> extends PageRouteBuilder<T> {
  GentlePageRoute({
    required WidgetBuilder builder,
    bool reducedMotion = false,
  }) : super(
          transitionDuration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 350),
          reverseTransitionDuration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 250),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
}

class AppNavigation {
  AppNavigation._();

  static Future<T?> push<T>(
    BuildContext context,
    WidgetBuilder builder, {
    bool reducedMotion = false,
  }) =>
      Navigator.of(context).push<T>(
        GentlePageRoute<T>(builder: builder, reducedMotion: reducedMotion),
      );

  static Future<T?> replace<T>(
    BuildContext context,
    WidgetBuilder builder, {
    bool reducedMotion = false,
  }) =>
      Navigator.of(context).pushReplacement(
        GentlePageRoute<T>(builder: builder, reducedMotion: reducedMotion),
      );
}

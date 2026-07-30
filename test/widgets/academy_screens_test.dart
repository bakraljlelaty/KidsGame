import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_wonder_world/core/theme/palette.dart';
import 'package:little_wonder_world/features/learning_path/learning_path_screen.dart';
import 'package:little_wonder_world/features/play_rooms/play_rooms_screen.dart';
import 'package:little_wonder_world/l10n/app_localizations_en.dart';

import 'helpers.dart';

/// Pumps the fade route transition after a navigation tap (Milo runs a
/// continuous ticker, so fixed pumps only — never pumpAndSettle).
Future<void> pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 100));
}

/// The engine glyphs an activity bubble can show.
final Set<IconData> kEngineIcons = {
  Icons.touch_app_rounded,
  Icons.move_down_rounded,
  Icons.filter_none_rounded,
  Icons.style_rounded,
  Icons.more_horiz_rounded,
  Icons.exposure_plus_1_rounded,
  Icons.gesture_rounded,
  Icons.sports_esports_rounded,
};

void main() {
  testWidgets(
      'the path button opens the learning path with exactly one current '
      'node bubble', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await pumpRouteTransition(tester);
    expect(find.byType(LearningPathScreen), findsOneWidget);

    // The current node bubble is the only one with the coral highlight ring.
    final currentBubbles = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((widget) {
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      final border = decoration.border;
      return border is Border && border.top.color == Palette.coral;
    }).length;
    expect(currentBubbles, 1,
        reason: 'exactly one node bubble marks where the child continues');
  });

  testWidgets(
      'the rooms button opens the play rooms (no Letters room for the '
      'youngest band) and the Colors room shows its 6 activities',
      (tester) async {
    await pumpApp(tester);
    final l10n = AppLocalizationsEn();

    await tester.tap(find.byIcon(Icons.apps_rounded));
    await pumpRouteTransition(tester);
    expect(find.byType(PlayRoomsScreen), findsOneWidget);

    // The default profile plays in the 2-3 band: letters wait for later.
    expect(find.text(l10n.subjectColors), findsOneWidget);
    expect(find.text(l10n.subjectLetters), findsNothing);

    await tester.tap(find.text(l10n.subjectColors));
    await pumpRouteTransition(tester);
    expect(find.byType(SubjectRoomScreen), findsOneWidget);

    // Six colors activities, each drawn as a bubble with its engine glyph.
    final bubbleCount = tester
        .widgetList<Icon>(find.descendant(
          of: find.byType(SubjectRoomScreen),
          matching: find.byType(Icon),
        ))
        .where((icon) => kEngineIcons.contains(icon.icon))
        .length;
    expect(bubbleCount, 6);
  });
}

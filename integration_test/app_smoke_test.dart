// Device-run smoke test: real services (SharedPreferences store, audio,
// session auto-tick), the real app, and one full Feed the Animals round.
//
// Run on a device/emulator with:
//   flutter test integration_test/app_smoke_test.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:little_wonder_world/app/app.dart';
import 'package:little_wonder_world/app/app_services.dart';
import 'package:little_wonder_world/features/rewards/reward_overlay.dart';
import 'package:little_wonder_world/features/world_map/world_map_screen.dart';
import 'package:little_wonder_world/l10n/app_localizations_en.dart';
import 'package:little_wonder_world/shared/game/mini_game_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('end to end on device: play -> Feed the Animals -> drag food '
      '-> reward -> world map', (tester) async {
    final services = await AppServices.bootstrap();
    // A fresh state keeps the star/completion assertions deterministic even
    // when the device has old data from a previous run.
    await services.deleteAllData();

    await tester.pumpWidget(LittleWonderApp(services: services));
    await tester.pump(const Duration(milliseconds: 400));

    // Home -> world map. (MiloView animates continuously, so fixed pumps
    // only — never pumpAndSettle on child-area screens.)
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(WorldMapScreen), findsOneWidget);

    // World map -> Feed the Animals.
    await tester.tap(find.text(AppLocalizationsEn().gameFeedAnimals));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MiniGameScreen), findsOneWidget);

    // Let the Flame game load and mount its components.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Default explorer stage shows exactly one pair: the food at
    // (0.5w, 0.82h) and the rabbit at (0.5w, 0.36h) of the game canvas.
    // Derive the coordinates from the actual GameWidget rect so the test is
    // independent of the device's screen size.
    final gameFinder = find.byWidgetPredicate((w) => w is GameWidget);
    expect(gameFinder, findsOneWidget);
    final rect = tester.getRect(gameFinder);
    final start = Offset(
      rect.left + rect.width * 0.5,
      rect.top + rect.height * 0.82,
    );
    final end = Offset(
      rect.left + rect.width * 0.5,
      rect.top + rect.height * 0.36,
    );
    await tester.timedDragFrom(
      start,
      end - start,
      const Duration(milliseconds: 600),
    );

    // Snap + eating + celebration (2.6s) + reward dialog push.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(RewardOverlay), findsOneWidget);

    // A tap anywhere dismisses the overlay early.
    await tester.tap(find.byType(RewardOverlay), warnIfMissed: false);
    await tester.pump();

    // Pump well past the overlay's 3.6s auto-continue timer and the route
    // transitions back to the world map.
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byType(RewardOverlay), findsNothing);
    expect(find.byType(MiniGameScreen), findsNothing);
    expect(find.byType(WorldMapScreen), findsOneWidget);

    expect(services.progress.data.totalCompletions, 1);
    expect(services.rewards.data.totalStars, 1);
  });
}

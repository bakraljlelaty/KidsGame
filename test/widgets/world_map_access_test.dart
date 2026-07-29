import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_wonder_world/features/world_map/world_map_screen.dart';
import 'package:little_wonder_world/l10n/app_localizations_en.dart';
import 'package:little_wonder_world/shared/game/mini_game_screen.dart';
import 'package:little_wonder_world/shared/models/game_id.dart';

import 'helpers.dart';

void main() {
  testWidgets('a disabled game tile does not open, an enabled one does',
      (tester) async {
    final services = await pumpApp(
      tester,
      configure: (s) => s.gameAccess.setGameEnabled(GameId.feedAnimals, false),
    );
    expect(services.gameAccess.access.isEnabled(GameId.feedAnimals), isFalse);

    // Tap the big play button on the home screen -> world map.
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(WorldMapScreen), findsOneWidget);

    final l10n = AppLocalizationsEn();

    // The disabled Feed the Animals tile must not open the game.
    await tester.tap(find.text(l10n.gameFeedAnimals), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MiniGameScreen), findsNothing);
    expect(find.byType(WorldMapScreen), findsOneWidget);

    // A different, enabled tile does open the mini-game screen.
    await tester.tap(find.text(l10n.gameBubblePop));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MiniGameScreen), findsOneWidget);
  });
}

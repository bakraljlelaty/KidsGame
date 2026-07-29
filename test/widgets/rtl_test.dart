import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:little_wonder_world/app/app_services.dart';
import 'package:little_wonder_world/core/audio/audio_manager.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/parent_dashboard/game_access_controller.dart';
import 'package:little_wonder_world/features/profiles/profile_controller.dart';
import 'package:little_wonder_world/features/progress/progress_controller.dart';
import 'package:little_wonder_world/features/rewards/rewards_controller.dart';
import 'package:little_wonder_world/features/session_control/session_controller.dart';
import 'package:little_wonder_world/features/settings/settings_controller.dart';
import 'package:little_wonder_world/features/sticker_book/sticker_book_controller.dart';
import 'package:little_wonder_world/l10n/app_localizations.dart';
import 'package:little_wonder_world/l10n/app_localizations_ar.dart';
import 'package:little_wonder_world/shared/game/mini_game_screen.dart';
import 'package:little_wonder_world/shared/models/game_id.dart';

import 'helpers.dart';

void main() {
  testWidgets('Arabic locale renders the parent dashboard right-to-left '
      'with the Arabic title', (tester) async {
    await pumpApp(
      tester,
      configure: (services) => services.settings.setLanguage('ar'),
    );
    await openParentDashboard(tester);

    final arabicTitle = AppLocalizationsAr().dashboardTitle;
    expect(find.text(arabicTitle), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(arabicTitle))),
      TextDirection.rtl,
    );
  });

  testWidgets('game scenes stay left-to-right under the Arabic locale',
      (tester) async {
    setLandscapeView(tester);
    final services = await AppServices.bootstrap(
      store: InMemoryStore(),
      enableAutoTick: false,
      initAudio: false,
    );
    await services.settings.setLanguage('ar');

    // Small harness replicating LittleWonderApp's providers around a single
    // MiniGameScreen, with the app-level locale forced to Arabic.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppServices>.value(value: services),
          Provider<AudioManager>.value(value: services.audio),
          ChangeNotifierProvider<SettingsController>.value(
              value: services.settings),
          ChangeNotifierProvider<ProfileController>.value(
              value: services.profile),
          ChangeNotifierProvider<GameAccessController>.value(
              value: services.gameAccess),
          ChangeNotifierProvider<ProgressController>.value(
              value: services.progress),
          ChangeNotifierProvider<RewardsController>.value(
              value: services.rewards),
          ChangeNotifierProvider<StickerBookController>.value(
              value: services.stickerBook),
          ChangeNotifierProvider<SessionController>.value(
              value: services.session),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MiniGameScreen(gameId: GameId.feedAnimals),
        ),
      ),
    );

    // Known lib issue: MiniGameScreen.initState synchronously notifies
    // ProgressController listeners during the first build ("markNeedsBuild
    // called during build"); absorb the reported error so it does not mask
    // the directionality assertion (see test report).
    tester.takeException();

    // Let the Flame game load; the scene animates continuously (Milo), so
    // fixed pumps only.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final gameWidget = find.byWidgetPredicate((w) => w is GameWidget);
    expect(gameWidget, findsOneWidget);
    expect(
      Directionality.of(tester.element(gameWidget)),
      TextDirection.ltr,
      reason: 'game scenes must never be mirrored for RTL locales',
    );
  });
}

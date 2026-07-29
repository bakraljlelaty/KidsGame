import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_wonder_world/l10n/app_localizations_en.dart';
import 'package:little_wonder_world/shared/models/game_id.dart';

import 'helpers.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('Games tab: toggling the first game switch updates '
      'GameAccessController', (tester) async {
    final services = await pumpApp(tester);
    await openParentDashboard(tester);

    await tester.tap(find.text(l10n.tabGames));
    await tester.pumpAndSettle();

    // The first switch in the games list is Feed the Animals
    // (GameRegistry.all follows GameId.values order).
    expect(services.gameAccess.access.isEnabled(GameId.feedAnimals), isTrue);

    final firstSwitch = find.byType(SwitchListTile).first;
    await tester.ensureVisible(firstSwitch);
    await tester.pumpAndSettle();
    await tester.tap(firstSwitch);
    await tester.pumpAndSettle();

    expect(services.gameAccess.access.isEnabled(GameId.feedAnimals), isFalse);

    // Toggling back re-enables it.
    await tester.tap(firstSwitch);
    await tester.pumpAndSettle();
    expect(services.gameAccess.access.isEnabled(GameId.feedAnimals), isTrue);
  });

  testWidgets('Session tab: choosing a session-length chip updates '
      'SessionController.config', (tester) async {
    final services = await pumpApp(tester);
    await openParentDashboard(tester);

    await tester.tap(find.text(l10n.tabSession));
    await tester.pumpAndSettle();

    expect(services.session.config.sessionMinutes, 10); // default

    // '5 minutes' only occurs in the session-length row (daily limit offers
    // 20/30/45/60), so the finder is unambiguous.
    await tester.tap(find.text(l10n.sessionMinutesOption(5)));
    await tester.pumpAndSettle();

    expect(services.session.config.sessionMinutes, 5);
  });

  testWidgets('Settings tab: toggling the music switch updates '
      'SettingsController', (tester) async {
    final services = await pumpApp(tester);
    await openParentDashboard(tester);

    await tester.tap(find.text(l10n.tabSettings));
    await tester.pumpAndSettle();

    expect(services.settings.settings.musicEnabled, isTrue);

    final musicSwitch = find.widgetWithText(SwitchListTile, l10n.settingsMusic);
    await tester.ensureVisible(musicSwitch);
    await tester.pumpAndSettle();
    await tester.tap(musicSwitch);
    await tester.pumpAndSettle();

    expect(services.settings.settings.musicEnabled, isFalse);
  });
}

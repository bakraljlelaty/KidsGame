import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:little_wonder_world/app/app_services.dart';
import 'package:little_wonder_world/content/activity_definitions.dart';
import 'package:little_wonder_world/core/audio/audio_manager.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/learning_path/path_progress.dart';
import 'package:little_wonder_world/features/parent_dashboard/game_access_controller.dart';
import 'package:little_wonder_world/features/profiles/profile_controller.dart';
import 'package:little_wonder_world/features/progress/progress_controller.dart';
import 'package:little_wonder_world/features/rewards/reward_overlay.dart';
import 'package:little_wonder_world/features/rewards/rewards_controller.dart';
import 'package:little_wonder_world/features/session_control/session_controller.dart';
import 'package:little_wonder_world/features/settings/settings_controller.dart';
import 'package:little_wonder_world/l10n/app_localizations.dart';
import 'package:little_wonder_world/shared/game/activity_screen.dart';
import 'package:little_wonder_world/shared/game/activity_spec.dart';
import 'package:little_wonder_world/shared/game/toddler_game.dart';
import 'package:little_wonder_world/shared/models/age_band.dart';
import 'package:little_wonder_world/shared/models/subject.dart';

/// STRESS SWEEP: machine-completes every single activity in the catalog
/// through the same auto-assist path a stuck child would get, and fails on
/// any thrown exception, missing reward flow, or non-completion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppServices> makeServices(AgeBand band) async {
    final services = await AppServices.bootstrap(
      store: InMemoryStore(),
      enableAutoTick: false,
      initAudio: false,
    );
    await services.profile.setBand(band);
    return services;
  }

  Widget harness(AppServices services, ActivitySpec spec) {
    return MultiProvider(
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
        ChangeNotifierProvider<SessionController>.value(
            value: services.session),
        ChangeNotifierProvider<PathProgressController>.value(
            value: services.pathProgress),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _Launcher(spec: spec),
      ),
    );
  }

  Future<void> completeSpec(
    WidgetTester tester,
    AgeBand band,
    ActivitySpec spec,
  ) async {
    final services = await makeServices(band);
    await tester.pumpWidget(harness(services, spec));
    await tester.tap(find.byKey(const Key('launch')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull,
        reason: '${spec.id}: exception during open');

    // Let the game load and its intro timers run.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }

    final gameWidget = tester.widget<GameWidget>(
      find.byWidgetPredicate((w) => w is GameWidget),
    );
    final game = (gameWidget as dynamic).game as ToddlerGame;

    // Drive to completion through auto-assist.
    for (var i = 0; i < 90 && !game.isCompleted; i++) {
      game.assistForTesting();
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.takeException(), isNull,
          reason: '${spec.id}: exception during assist $i');
    }
    expect(game.isCompleted, isTrue,
        reason: '${spec.id} never completed under repeated assistance');

    // Celebration -> reward overlay -> back to the launcher.
    for (var i = 0;
        i < 24 && find.byType(RewardOverlay).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(RewardOverlay), findsOneWidget,
        reason: '${spec.id}: reward overlay never appeared');
    await tester.tap(find.byType(RewardOverlay), warnIfMissed: false);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(ActivityScreen), findsNothing,
        reason: '${spec.id}: did not leave the activity after the reward');
    expect(tester.takeException(), isNull,
        reason: '${spec.id}: exception during reward flow');

    // Progress must have been recorded somewhere meaningful.
    expect(
      services.progress.data.totalCompletions,
      greaterThan(0),
      reason: '${spec.id}: completion not recorded',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  setUp(() {
    // Landscape child area.
  });

  for (final subject in Subject.values) {
    testWidgets('stress sweep: every ${subject.storageKey} activity '
        'completes without errors (band 2-3)', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final spec in ActivityDefinitions.forSubject(subject)) {
        await completeSpec(tester, AgeBand.twoToThree, spec);
      }
    });
  }

  testWidgets('stress sweep: engine activities at the hardest band (5-6)',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final subject in [
      Subject.colors,
      Subject.numbers,
      Subject.letters,
    ]) {
      for (final spec in ActivityDefinitions.forSubject(subject)) {
        await completeSpec(tester, AgeBand.fiveToSix, spec);
      }
    }
  });
}

class _Launcher extends StatelessWidget {
  const _Launcher({required this.spec});

  final ActivitySpec spec;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('launch'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ActivityScreen(spec: spec),
            ),
          ),
          child: const Text('launch'),
        ),
      ),
    );
  }
}

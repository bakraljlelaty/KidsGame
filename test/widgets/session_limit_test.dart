import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/session_control/session_controller.dart';
import 'package:little_wonder_world/features/session_control/session_data.dart';

import 'helpers.dart';

void main() {
  testWidgets('with today\'s daily limit exhausted the play button is gone '
      'until a parent allows an extra session', (tester) async {
    // Seed the store BEFORE bootstrap with an exhausted day.
    final store = InMemoryStore();
    final repository = SessionRepository(store);
    await repository.saveUsage(
      SessionUsage(
        dayKey: dayKeyOf(DateTime.now()),
        playedTodayMs: 999 * 60000,
      ),
    );
    await repository.saveConfig(
      const SessionConfig(
        sessionMinutes: 10,
        dailyLimitMinutes: 30,
        breakMinutes: 30,
      ),
    );

    final services = await pumpApp(tester, store: store);

    // The limit is spent: the session is blocked and the child cannot start.
    expect(services.session.phase, SessionPhase.blocked);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    // Parent explicitly allows one more session.
    await services.session.parentAllowExtraSession();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(services.session.phase, SessionPhase.ready);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}

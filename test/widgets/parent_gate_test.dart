import 'package:flutter_test/flutter_test.dart';

import 'package:little_wonder_world/features/parent_dashboard/parent_dashboard_screen.dart';
import 'package:little_wonder_world/features/parent_gate/pin_screen.dart';
import 'package:little_wonder_world/l10n/app_localizations_en.dart';

import 'helpers.dart';

void main() {
  testWidgets('holding both top corners for 3 seconds opens the PIN screen',
      (tester) async {
    await pumpApp(tester);
    expect(find.byType(PinScreen), findsNothing);

    await holdParentCorners(tester);

    expect(find.byType(PinScreen), findsOneWidget);
    expect(find.byType(ParentDashboardScreen), findsNothing);
  });

  testWidgets('holding a single corner does not open the PIN screen',
      (tester) async {
    await pumpApp(tester);

    final gesture = await tester.startGesture(const Offset(20, 20));
    await tester.pump(const Duration(seconds: 3, milliseconds: 300));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PinScreen), findsNothing);
  });

  testWidgets('a wrong PIN shows the incorrect message and stays on the '
      'PIN screen', (tester) async {
    await pumpApp(tester);
    await holdParentCorners(tester);
    expect(find.byType(PinScreen), findsOneWidget);

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.pinIncorrect), findsNothing);

    await enterPin(tester, '1111');

    expect(find.byType(PinScreen), findsOneWidget);
    expect(find.text(l10n.pinIncorrect), findsOneWidget);
    expect(find.byType(ParentDashboardScreen), findsNothing);
  });

  testWidgets('the correct default PIN opens the parent dashboard',
      (tester) async {
    await pumpApp(tester);
    await openParentDashboard(tester);

    expect(find.byType(ParentDashboardScreen), findsOneWidget);
    expect(find.byType(PinScreen), findsNothing);
    expect(find.text(AppLocalizationsEn().dashboardTitle), findsOneWidget);
  });
}

/// Shared helpers for the widget test suite.
///
/// Conventions used everywhere:
///  * The child area is landscape-first: tests run at 1600x900 logical px.
///  * MiloView runs a continuous Ticker, so screens that show Milo (home,
///    reward overlay, sleepy screen, in-game) are pumped with fixed
///    durations — never pumpAndSettle. Once an opaque route (PIN screen /
///    parent dashboard) covers the home screen its tickers are muted, so
///    pumpAndSettle is safe on dashboard screens only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_wonder_world/app/app.dart';
import 'package:little_wonder_world/app/app_services.dart';
import 'package:little_wonder_world/config/app_config.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/parent_dashboard/parent_dashboard_screen.dart';
import 'package:little_wonder_world/features/parent_gate/pin_screen.dart';

/// Landscape child-area viewport used by every widget test.
const Size kChildViewport = Size(1600, 900);

/// Forces the test surface to the landscape child-area size.
void setLandscapeView(WidgetTester tester) {
  tester.view.physicalSize = kChildViewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Boots [AppServices] on an in-memory store (no audio, no auto tick) and
/// pumps the full [LittleWonderApp].
///
/// [configure] runs after bootstrap but before the first frame, so tests can
/// pre-set state (language, game access, ...) that the first build must see.
Future<AppServices> pumpApp(
  WidgetTester tester, {
  InMemoryStore? store,
  Future<void> Function(AppServices services)? configure,
}) async {
  setLandscapeView(tester);
  final services = await AppServices.bootstrap(
    store: store ?? InMemoryStore(),
    enableAutoTick: false,
    initAudio: false,
  );
  if (configure != null) {
    await configure(services);
  }
  await tester.pumpWidget(LittleWonderApp(services: services));
  // First frame + the post-frame greeting callback. Milo is on screen, so
  // only fixed pumps from here on.
  await tester.pump(const Duration(milliseconds: 50));
  return services;
}

/// Holds both top corners simultaneously for the 3-second parent-gate hold,
/// then releases and pumps the [PinScreen] route transition.
Future<void> holdParentCorners(WidgetTester tester) async {
  final g1 = await tester.startGesture(const Offset(20, 20));
  final g2 = await tester.startGesture(const Offset(1580, 20));
  await tester.pump(const Duration(seconds: 3, milliseconds: 300));
  await g1.up();
  await g2.up();
  await tester.pump();
  // MaterialPageRoute transition onto the PIN screen.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Types [pin] on the PIN pad by tapping the digit keys, then pumps the
/// route transition that follows a completed (4-digit) entry.
Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Full parent gate flow from the child home screen: corner hold, then the
/// default PIN. Ends on the [ParentDashboardScreen].
Future<void> openParentDashboard(WidgetTester tester) async {
  await holdParentCorners(tester);
  expect(find.byType(PinScreen), findsOneWidget,
      reason: 'corner hold should open the PIN screen');
  await enterPin(tester, AppConfig.defaultParentPin);
  expect(find.byType(ParentDashboardScreen), findsOneWidget,
      reason: 'the default PIN should open the parent dashboard');
}

/// Day key in exactly the format SessionController uses internally
/// (yyyy-mm-dd with padLeft).
String dayKeyOf(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-'
    '${time.month.toString().padLeft(2, '0')}-'
    '${time.day.toString().padLeft(2, '0')}';

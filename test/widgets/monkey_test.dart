import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// MONKEY STRESS TEST: hammers the whole app with seeded random taps and
/// drags — wherever they land (games, path, rooms, overlays, sticker book).
/// The app must never throw. A single pointer can never trigger the
/// dual-corner parent gate, so the monkey stays in the child area by
/// construction.
void main() {
  testWidgets('300 random taps and drags never crash the child area',
      (tester) async {
    await pumpApp(tester);
    final random = Random(20260730);
    const size = Size(1600, 900);

    for (var i = 0; i < 300; i++) {
      final x = 20 + random.nextDouble() * (size.width - 40);
      final y = 20 + random.nextDouble() * (size.height - 40);
      final point = Offset(x, y);

      switch (random.nextInt(4)) {
        case 0:
        case 1:
          await tester.tapAt(point);
        case 2:
          final delta = Offset(
            (random.nextDouble() - 0.5) * 500,
            (random.nextDouble() - 0.5) * 500,
          );
          await tester.dragFrom(point, delta);
        case 3:
          final gesture = await tester.startGesture(point);
          await tester.pump(const Duration(milliseconds: 120));
          await gesture.up();
      }

      await tester.pump(const Duration(milliseconds: 90));
      final exception = tester.takeException();
      expect(exception, isNull,
          reason: 'monkey iteration $i threw: $exception');

      // Every ~40 actions, let timers settle a little.
      if (i % 40 == 39) {
        for (var j = 0; j < 10; j++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        expect(tester.takeException(), isNull,
            reason: 'settling after iteration $i threw');
      }
    }

    // Final settle: no pending exceptions anywhere.
    for (var j = 0; j < 12; j++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.takeException(), isNull);
  });
}

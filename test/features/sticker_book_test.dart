import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/sticker_book/sticker_book_controller.dart';
import 'package:little_wonder_world/features/sticker_book/sticker_placements.dart';

void main() {
  group('StickerBookController', () {
    test('placeSticker clamps coordinates to 0..1 and persists', () async {
      final store = InMemoryStore();
      final controller = StickerBookController(StickerBookRepository(store));
      await controller.init();

      await controller.placeSticker('feed_carrot', 'meadow', -0.4, 1.7);
      await controller.placeSticker('pop_bubble', 'meadow', 0.25, 0.75);

      expect(controller.data.placements, hasLength(2));
      final clamped = controller.data.placements[0];
      expect(clamped.stickerId, 'feed_carrot');
      expect(clamped.sceneId, 'meadow');
      expect(clamped.x, 0.0);
      expect(clamped.y, 1.0);
      final inRange = controller.data.placements[1];
      expect(inRange.x, 0.25);
      expect(inRange.y, 0.75);

      // Persisted, not just in memory.
      final stored = await StickerBookRepository(store).load();
      expect(stored.placements, hasLength(2));
      expect(stored.placements[0].x, 0.0);
      expect(stored.placements[0].y, 1.0);
    });

    test('movePlacement updates coordinates (clamped) and persists', () async {
      final store = InMemoryStore();
      final controller = StickerBookController(StickerBookRepository(store));
      await controller.init();
      await controller.placeSticker('feed_carrot', 'meadow', 0.5, 0.5);

      await controller.movePlacement(0, 0.1, 0.9);
      expect(controller.data.placements.single.x, 0.1);
      expect(controller.data.placements.single.y, 0.9);

      await controller.movePlacement(0, 2.0, -3.0);
      expect(controller.data.placements.single.x, 1.0);
      expect(controller.data.placements.single.y, 0.0);

      // Out-of-range indices are ignored.
      await controller.movePlacement(5, 0.2, 0.2);
      await controller.movePlacement(-1, 0.2, 0.2);
      expect(controller.data.placements.single.x, 1.0);

      final stored = await StickerBookRepository(store).load();
      expect(stored.placements.single.x, 1.0);
      expect(stored.placements.single.y, 0.0);
    });

    test('removePlacement removes exactly the indexed sticker', () async {
      final store = InMemoryStore();
      final controller = StickerBookController(StickerBookRepository(store));
      await controller.init();
      await controller.placeSticker('feed_carrot', 'meadow', 0.1, 0.1);
      await controller.placeSticker('pop_bubble', 'sky', 0.2, 0.2);
      await controller.placeSticker('pig_soap', 'sea', 0.3, 0.3);

      await controller.removePlacement(1);

      expect(controller.data.placements, hasLength(2));
      expect(
        controller.data.placements.map((p) => p.stickerId),
        ['feed_carrot', 'pig_soap'],
      );
      expect(controller.placementsFor('sky'), isEmpty);
      expect(controller.placementsFor('meadow'), hasLength(1));

      // Out-of-range indices are ignored.
      await controller.removePlacement(7);
      expect(controller.data.placements, hasLength(2));
    });

    test('data survives a new controller on the same store', () async {
      final store = InMemoryStore();
      final controller = StickerBookController(StickerBookRepository(store));
      await controller.init();
      await controller.placeSticker('bed_moon', 'sky', 0.6, 0.4);
      await controller.placeSticker('bed_teddy', 'meadow', 0.3, 0.8);

      final revived = StickerBookController(StickerBookRepository(store));
      await revived.init();

      expect(revived.data.placements, hasLength(2));
      final moon = revived.data.placements[0];
      expect(moon.stickerId, 'bed_moon');
      expect(moon.sceneId, 'sky');
      expect(moon.x, 0.6);
      expect(moon.y, 0.4);
      expect(revived.placementsFor('meadow').single.stickerId, 'bed_teddy');
    });
  });
}

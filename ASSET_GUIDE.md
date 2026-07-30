# Asset Guide

**Every visual in this project is procedural placeholder art** — original vector drawings made in
code with `CustomPainter` (widgets) or direct canvas rendering (Flame components). Nothing is
copied from any existing brand, show, or app. Each drawing sits behind a small painter class or a
`paintItem` callback, so real illustrations and sprite sheets can replace it later **without
touching game logic**.

`assets/images/` and `assets/sprites/` exist (empty) as the landing place for real artwork;
remember to add them to the `assets:` section of `pubspec.yaml` when you start using them.
`assets/config/placeholder_assets.txt` is just a pointer back to this guide.

## Where each drawing lives

| Visual | File | Painter / swap point |
|---|---|---|
| Milo (all 8 states, helmet, pointing) | `lib/shared/characters/milo_painter.dart` | `MiloPainter.paint(canvas, size, state:, time:, ...)` — the single drawing routine used by both hosts below |
| Milo in Flame scenes | `lib/shared/characters/milo_component.dart` | `MiloComponent.render` calls `MiloPainter.paint` |
| Milo in Flutter screens | `lib/shared/characters/milo_view.dart` | `MiloView` (ticker-driven `CustomPaint` on `MiloPainter`) |
| Milo state list | `lib/shared/characters/milo_state.dart` | `MiloState` enum — maps 1:1 onto future sprite-sheet rows |
| **Every academy content item** (color blobs, shapes, letter/number tiles, animals, foods, vehicles, toys) | `lib/shared/items/item_art.dart` | `ItemArt.paint(canvas, size, item, highContrast:)` — one switch on `ContentItem.artId` (see "The ItemArt catalog" below) |
| Subject-room icons (one per concept area) | `lib/shared/widgets/subject_icon.dart` | `SubjectIcon` / `_SubjectIconPainter`, keyed by `Subject` — composes `ItemArt` drawings (and `MiloPainter` for Milo's World) |
| Sticker art (all 18 collectible stickers) | `lib/shared/widgets/sticker_art.dart` | `StickerArtView` / `_StickerPainter`, keyed by the `StickerArt` enum (`lib/features/rewards/sticker_catalog.dart`) |
| World-map tile icons (one per bespoke game) | `lib/shared/widgets/world_icon.dart` | `WorldIcon` / `_WorldIconPainter`, keyed by `GameId` |
| Farm animals + foods (Feed the Animals) | `lib/features/feed_animals/animal_art.dart` | `AnimalArt` static paint methods (e.g. `paintFood`), used by the game's zones and draggables |
| Feed the Animals scene background | `lib/features/feed_animals/feed_animals_game.dart` | `_FarmBackground` component |
| Bubbles, fish, underwater backdrop (Bubble Pop) | `lib/features/bubble_pop/bubble_art.dart` | `BubbleArt` painters keyed by `BubbleHue` |
| Socks + bedroom (Dancing Socks) | `lib/features/dancing_socks/sock_art.dart` | `SockArt.paintSock` / `SockArt.paintBedroom`, styles in `SockStyles` |
| Pig, bucket, towel, sponge (Muddy Pig Bath) | `lib/features/muddy_pig/pig_art.dart` | `PigArt` static paint methods |
| Rocket parts, silhouettes, workshop (Build the Rocket) | `lib/features/build_rocket/rocket_art.dart` | `RocketArt` / `WorkshopArt`, parts keyed by `RocketPart` |
| Bedroom, bed, lamp, teddy, window (Bedtime Routine) | `lib/features/bedtime_routine/bedtime_art.dart` | `BedtimeArt` static paint methods |
| Mud blobs (swipe-clean) | `lib/shared/components/swipe_clean_layer.dart` | `SwipeCleanLayer` blob rendering |
| Hint glow, sparkles, pulses | `lib/shared/components/gentle_effects.dart` | `GlowHighlight`, `SparkleBurst`, `GentleEffects` |
| Sticker-book scenes (meadow / sky / sea) | `lib/features/sticker_book/sticker_book_screen.dart` | `_ScenePainter` |
| Reward star badge | `lib/features/rewards/reward_overlay.dart` | `_StarBadge` |
| Colour palette | `lib/core/theme/palette.dart` | `Palette` constants used by every painter |

## The ItemArt catalog (academy content items)

Every teachable item the activity engines show — a `ContentItem` from `ItemCatalog`
(`lib/content/items/item_catalog.dart`) — is drawn by **one** class:
`ItemArt` (`lib/shared/items/item_art.dart`). `ItemArt.paint` switches on
`ContentItem.artId` (which defaults to the item's `id`), so all item drawing stays swappable
for sprites later without touching any engine.

- **Design box:** all item painters draw into a fixed **100 × 100** box scaled and centred to
  the requested size; strokes are rounded and soften to ~50 % opacity (thicker + full opacity
  under `highContrast`).
- **Generic painters:** `'blob'` (a soft organic blob filled with `ContentItem.color` — the
  colors pack) and `'glyph'` (a rounded tile in `ContentItem.color` showing
  `ContentItem.glyph` — numbers, English letters, and Arabic letters all use it, so the whole
  alphabet costs no extra art).
- **Specific painters:** `shape_*` (circle, square, triangle, star, heart, rectangle, oval,
  diamond), `animal_*` (rabbit, cow, monkey, duck, fish, cat, dog, bee, butterfly, ladybug),
  `food_*` (apple, banana, strawberry, orange, pear, grapes, bread, milk, cheese, egg, carrot,
  cookie), `vehicle_*` (car, bus, boat, rocket), `toy_*` (ball, block, teddy, drum, train).
  Unknown ids fall back to the blob rather than crashing.

**Adding an `artId`:**

1. Add the `ContentItem` to its pack in `ItemCatalog` (omit `artId` to reuse the item `id`).
2. Add a `case 'your_art_id':` to the switch in `ItemArt.paint`, drawing inside the 100 × 100
   box with the provided `stroke` paint and `item.color`. Follow the art direction rules below.
3. Nothing else — every engine (and `SubjectIcon`) picks the drawing up through the catalog.

**Silhouette recipe (ShadowMatch):** silhouettes are *not* separate art. `_ShadowZone`
(`lib/features/activities/shadow_match/shadow_match_game.dart`) renders the normal
`ItemArt` drawing inside a `canvas.saveLayer`, then fills the bounds with a dark translucent
color using `BlendMode.srcIn`, which masks the fill to the drawing's exact outline. Any new
`artId` therefore gets a correct silhouette for free — keep item drawings a single filled
silhouette-friendly form (no floating disconnected specks) so the shadow reads clearly.

## Replacing placeholder art with sprites later

The state and layout APIs are final; only the drawing changes.

**Milo → sprite animations.** Produce one animation (sprite-sheet row) per `MiloState` — the enum
was designed for exactly this. Then:

- In Flame scenes, swap `MiloComponent.render` for a `SpriteAnimationComponent` keyed by
  `MiloState` (e.g. hold a `Map<MiloState, SpriteAnimation>`, switch the current animation inside
  `setState`/`setStateFor`). Everything that drives Milo (`talk()`, `dance()`,
  `pointTowards()`, the state timers) stays untouched.
- In widgets, change `MiloView`'s paint call to draw the corresponding animation frames (or wrap
  a `SpriteAnimationWidget`). Keep the `reducedMotion` flag honoured: slower/static frames, no
  large bounces.

**Per-painter swaps.** Each `CustomPainter` (`sticker_art.dart`, `world_icon.dart`,
`_ScenePainter`) can be replaced by an `Image`/`Sprite` lookup keyed by the same enum without
touching callers — the widgets (`StickerArtView`, `WorldIcon`) keep their constructors. For Flame
components using `paintItem` callbacks (`TapTarget`, `DraggableItem`), pass a sprite-drawing
callback (or subclass and override `render`) instead of the procedural one.

**Scaling contract.** Painters draw in a fixed design box (Milo: 100 × 120; stickers/icons and
`ItemArt` items: 100 × 100) scaled to the requested size — author sprites with the same aspect
ratios so positions and hit areas keep working. Interactive object sizes are multiplied by
`BandConfig.itemScale` (activity engines) or `StageConfig.itemScale` (bespoke games); never
bake sizes into art assumptions.

## Art direction rules

- **Soft and rounded.** No sharp corners, spikes, or hard black outlines — the placeholders use
  rounded strokes at ~55 % opacity (`Palette.outline` / `outlineStrong`). Follow that softness.
- **Warm pastel palette.** Build on `Palette` (`lib/core/theme/palette.dart`): cream backgrounds,
  peach/mint/lavender accents, "soft" object colours that stay distinguishable for matching games.
  Avoid saturated alarm colours (pure red especially) and harsh contrast — except when
  **high-contrast mode** is on, which thickens borders using `Palette.outlineStrong`; interactive
  art must remain legible in both modes.
- **Nothing scary or startling.** Friendly faces, closed gentle mouths, no teeth/claws, no
  darkness beyond the cosy night sky of the sleepy screen. Animations stay slow and small
  (see `GentleEffects` — nothing flashes or shakes hard), and must respect `reducedMotion`.
- **No brand imitation.** Do not draw characters, logos, colour schemes, or styles that evoke
  existing children's brands or shows (this also matters for Google Play; see
  [GOOGLE_PLAY_RELEASE_CHECKLIST.md](GOOGLE_PLAY_RELEASE_CHECKLIST.md)). Milo is an original,
  deliberately generic small round animal — keep him that way.
- **Originality and licensing.** Every replacement asset must be original work or properly
  licensed for commercial use in a children's app, with the license recorded. No stock art with
  unclear provenance, no AI output trained to mimic a specific artist or franchise.
- **Toddler legibility.** One clear silhouette per object, large forms, minimal interior detail.
  Interactive objects must read at `AppConfig.minTouchTarget` (88 logical px) and up.

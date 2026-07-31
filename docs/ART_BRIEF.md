# Art Brief — Little Wonder Academy

A complete, illustrator-ready inventory of every visual the app needs.
Hand this to a children's illustrator (or use it to evaluate a purchased
art pack). The codebase was built for this swap: every drawing below has a
single integration point (see ASSET_GUIDE.md), so art can arrive in batches
and ship incrementally.

## Style guide

- **Audience:** children aged 2–6 and their parents. Warm, soft, safe.
- **Look:** rounded storybook shapes, thick soft outlines, flat colors with
  gentle gradient shading, big expressive eyes with catchlights. No sharp
  angles, no realistic anatomy, nothing scary, aggressive or brand-derived.
  Must be 100% original — no resemblance to existing characters
  (Bluey, Peppa, Disney, Bimi Boo etc.).
- **Palette (anchor colors, hex):** cream `FFF6EA`, sky `BEE3F0`, meadow
  `CDE8C4`, peach `FFD9B8`, coral `FFB59E`, butter `FFE9A8`, mint `BFE8D2`,
  lavender `DCCDF0`, blush `F8CFDA`, soft red `F29E97`, soft blue `8FBEE8`,
  soft yellow `F7DD84`, soft green `A5D6A0`, soft orange `F7BE8B`, soft
  purple `C3A8E0`, soft pink `F2B8CE`, brown `C9A186`, outline `5D4E42`
  (used at ~50% opacity). Item colors must stay distinguishable for basic
  color-learning activities.
- **Formats:** SVG preferred (the app scales everything); otherwise PNG
  with transparency at 512×512 for items and 1024+ for characters/scenes.
  Deliver on transparent backgrounds except scene backdrops.
- **Silhouette rule:** every item must read as ONE connected filled shape
  (the shadow-matching game auto-generates silhouettes from the art).

## 1. Milo — the guide character (highest priority)

A small, friendly, original animal (currently a round peachy creature with
tall ears). Keep species ambiguous and ownable. Needed as **either** a
sprite-sheet set **or** (much better) a **Rive** file — Flutter plays Rive
natively and it gives professional squash-and-stretch animation.

States (one animation each, loopable, ~1–2 s):
idle (gentle breathing/blink) · talking (mouth cycle) · pointing (left and
right) · happy (bounce) · laughing · surprised · dancing · sleepy (with
drifting Zs). Plus a space-helmet accessory variant.

## 2. Content items (42) — one illustration each

Drawn to be recognizable at 100 px. Grouped by pack:

- **Shapes (8):** circle, square, triangle, star, heart, rectangle, oval,
  diamond — flat friendly shapes with the soft outline; color applied per
  activity, so deliver in white/neutral with a tint layer or as per-color
  variants of one neutral master.
- **Animals (10):** rabbit, cow, monkey, duck, fish, cat, dog, bee,
  butterfly, ladybug — full-body chibi, front-facing, smiling.
- **Food (12):** apple, banana, strawberry, orange, pear, grapes, bread,
  milk (carton/bottle), cheese, egg, carrot, cookie.
- **Vehicles (4):** car, bus, boat, rocket.
- **Toys (5):** ball, building block, teddy bear, drum, toy train.
- **Letter/number tiles:** no art needed (typeset in-app on rounded tiles);
  optionally a decorative tile frame.

## 3. Scene backdrops (landscape 16:9, calm, uncluttered center)

- Home meadow (sky, sun, hills, flowers — hero scene with room for Milo)
- Farm (Feed the Animals) · Underwater (Bubble Pop) · Bedroom (Dancing
  Socks) · Bath yard (Muddy Pig) · Space workshop (Build the Rocket) ·
  Evening bedroom (Bedtime Routine)
- Generic activity backdrop (soft gradient + minimal props) used by the
  seven engine activities — 2–3 variants
- Sticker-book scenes: meadow, sky, sea
- Bespoke game props: pig + bucket + towel + sponge, rocket parts (4),
  socks (3 pair designs), bubbles, farm foods, bedtime props (toy, basket,
  toothbrush, pajamas, teddy, lamp, bed)

## 4. UI kit

- Room "door" cards (8 subject accents) · path node bubbles (3 states) ·
  unit header bands · big round buttons (play/rooms/sticker book) ·
  slide-to-exit pill · reward star badge · trophy badge · 18 sticker
  designs (3 per original game + extras welcome) · subject icons (colors,
  shapes, animals, food, numbers, letters, art, Milo's World) · app icon +
  Play Store feature graphic.

## 5. Delivery & integration

Name files by the ids in ASSET_GUIDE.md / ItemCatalog (e.g.
`animal_cat.svg`, `food_apple.svg`). Any subset can ship: each delivered
asset replaces its procedural placeholder at one code point, the rest keep
working. Figma is a fine delivery medium — a file with one frame per asset,
named by id, can be pulled directly.

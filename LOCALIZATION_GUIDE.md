# Localization Guide

The app ships in **English (`en`) and Arabic (`ar`)** using Flutter's `gen-l10n` tooling. All
parent-facing and child-facing *text* lives in ARB files; all *spoken* audio is addressed by
language-independent `VoiceInstruction` ids (see [AUDIO_GUIDE.md](AUDIO_GUIDE.md)).

## gen-l10n workflow

Configuration in `l10n.yaml` (repo root):

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

- Source of truth: `lib/l10n/app_en.arb` (template) and `lib/l10n/app_ar.arb`. Every key added to
  the template **must** also be added to `app_ar.arb`, or `flutter gen-l10n` reports it missing.
- Generated files (`lib/l10n/app_localizations*.dart`) are produced automatically on every build
  because `pubspec.yaml` sets `generate: true`. Regenerate on demand with:

  ```bash
  flutter gen-l10n
  ```

- Usage: `AppLocalizations.of(context).sessionTitle`, placeholders as in
  `l10n.sessionMinutesOption(10)`. `nullable-getter: false` means `of(context)` is non-null —
  no `!` scattering.
- The active locale comes from the parent's language setting:
  `MaterialApp(locale: Locale(settings.languageCode))` in `lib/app/app.dart`, so the app language
  is a parent choice rather than blindly following the system locale.

## Arabic and RTL: two deliberate zones

**Parent screens are automatically RTL.** The dashboard, gate/PIN screens, and dialogs are plain
Material widgets; when the locale is Arabic, Flutter flips the layout direction for free. Nothing
special is needed when writing parent UI — just use `AppLocalizations` strings and directional
padding (`EdgeInsetsDirectional`) where it matters.

**Game scenes are deliberately LTR — never mirrored.** Physical play spaces (a farm, a bathtub, a
rocket pad) have no reading direction, and mirroring would flip coordinates under Flame scenes and
confuse spatial voice prompts. Therefore:

- `MiniGameScreen` (`lib/shared/game/mini_game_screen.dart`) wraps the whole game host in
  `Directionality(textDirection: TextDirection.ltr, ...)`.
- Child screens outside the games (e.g. `ChildHomeScreen`, the sticker book) wrap their bodies in
  the same LTR `Directionality`, since they are also spatial rather than textual.
- Consequence for contributors: never rely on `Directionality.of(context)` inside game scenes,
  and keep child screens essentially text-free (icons + audio) so nothing needs flipping. Any new
  child-area screen should follow the same wrapper pattern.

Arabic *text* (the few labels a child might see, and everything the parent sees) still renders as
proper RTL text within its own widgets — only the *layout* of play areas is pinned.

## Voice ids are separate from display text

Spoken instructions are **not** localized through ARB. Games call
`say(VoiceInstruction.feedIntro)`; `VoiceCatalog` (`lib/core/audio/voice_catalog.dart`) resolves
the id to `assets/audio/voices/<lang>/<id>.wav` using the language from settings. This keeps:

- recordings swappable per language without touching code or ARB files,
- ARB files purely textual (parent UI, semantics labels, game titles),
- the child experience fully audio-driven — a toddler never needs to read.

If a prompt's wording changes, re-record the WAVs; the enum id stays stable.

## Letters are a per-language content pack (v2)

The academy's letters subject teaches the **alphabet of the app language** — the English
alphabet in English, the **Arabic alphabet (28 letters, ا through ي)** in Arabic. This is
content, not translation:

- `ItemCatalog` (`lib/content/items/item_catalog.dart`) ships two letter packs:
  `letters_en` (A–Z) and `letters_ar` (`ar_alif` … `ar_ya`), each item carrying its glyph and
  its own `VoiceInstruction` name clip (`letter_a` …, `ar_alif` …).
- Letter `ActivitySpec`s in `lib/content/activity_definitions.dart` reference the *virtual*
  pack name **`'letters'`**. Engines resolve it at runtime via
  **`ItemCatalog.lettersFor(languageCode)`**, using `GameContext.languageCode` — `'ar'` returns
  the Arabic pack, everything else currently falls back to English. Path progress and room
  listings are unaffected by the language switch because the spec ids stay the same.
- Letter tiles are drawn by the generic `'glyph'` painter in `ItemArt`, so Arabic letter forms
  render exactly as the font shapes them — no per-letter art is needed.
- Letter activities only appear in age bands where `BandConfig.lettersEnabled` is true
  (every band except 2–3).

## New l10n keys in v2 (subjects and bands)

Parent-facing (and semantics) text for the academy lives in the ARB files like everything else.
When touching these, remember every key must exist in **both** `app_en.arb` and `app_ar.arb`:

- **Subjects:** `subjectColors`, `subjectShapes`, `subjectAnimals`, `subjectFood`,
  `subjectNumbers`, `subjectLetters`, `subjectMilosWorld` — used by the play rooms, the parent
  progress section, and room semantics labels.
- **Age bands:** `profileBand`, `bandTwoThree` … `bandFiveSix` plus their
  `band…Description` counterparts — used by the profile section's band selector.
- **Child-area semantics:** `semanticsPath` ("Learning path") and `semanticsRooms`
  ("Play rooms") for the two home buttons.

## Adding a language end-to-end

Example: French (`fr`).

1. **Translate the ARB.** Copy `lib/l10n/app_en.arb` to `lib/l10n/app_fr.arb`, set
   `"@@locale": "fr"`, translate every value (keep keys and placeholder definitions identical).
2. **Regenerate localizations:** `flutter gen-l10n`. `AppLocalizations.supportedLocales` now
   includes `fr` automatically.
3. **Register the voice language.** Add `'fr'` to `VoiceCatalog.supportedLanguages`
   (`lib/core/audio/voice_catalog.dart`). Until this is done the audio layer falls back to
   English clips even when the UI is French.
4. **Provide voice audio.** Create `assets/audio/voices/fr/` with one WAV per `VoiceInstruction`
   (exact snake_case names — see the table in [AUDIO_GUIDE.md](AUDIO_GUIDE.md)). For interim
   placeholders, add `"fr"` to the language tuple in `tool/gen_audio.py` (`main()`) and run
   `python3 tool/gen_audio.py`; replace with real calm recordings before release.
5. **Declare the asset folder.** Add to `pubspec.yaml`:

   ```yaml
   flutter:
     assets:
       - assets/audio/voices/fr/
   ```

6. **Expose the choice to parents.** Add the language to the pickers (profile / settings
   sections under `lib/features/parent_dashboard/sections/`) with a native-name label
   (`languageFrench` key in all ARB files).
7. **Decide on letters content.** `ItemCatalog.lettersFor` returns the English pack for any
   non-Arabic language; to teach the new language's own alphabet, add a `letters_<code>` pack
   in `lib/content/items/item_catalog.dart` (glyphs + per-letter `VoiceInstruction` ids) and
   extend `lettersFor`.
8. **Verify:** run the app, switch to the new language, confirm parent UI text, correct layout
   direction (RTL languages: parent screens flip, game scenes must not), and that every voice
   line plays from the new folder. Then run the relevant parts of
   [docs/TODDLER_USABILITY_CHECKLIST.md](docs/TODDLER_USABILITY_CHECKLIST.md) in that language.

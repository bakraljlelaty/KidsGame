# Privacy Checklist

## Principle

**All data stays on the device.** The app has no backend, no accounts, and no network features;
the Android manifest requests **no permissions at all** — not even `INTERNET` (see the comment at
the top of `android/app/src/main/AndroidManifest.xml`, and keep it that way). Everything the app
remembers lives in local `SharedPreferences` (keys prefixed `lww.`, written via
`lib/core/persistence/local_store.dart`) and is fully erased by the parent's
*Delete all child data* action (`AppServices.deleteAllData`).

## Exactly what is stored (locally only)

| Store key | Contents |
|---|---|
| `lww.profile` | Child profile: **nickname** (free text chosen by the parent — the UI asks for a nickname, not a real name), **age group** (only "around two" / "around three", never a birth date), **avatar id**, **language code**, **development stage**, auto-stage-progression flag |
| `lww.settings` | App settings: music / sound-effects / voice toggles, language, reduced motion, high contrast, haptics, left-handed layout, and the **parent PIN** (stored locally; protects the dashboard, not sensitive data) |
| `lww.game_access` | Which games are enabled, free vs guided play mode, guided order |
| `lww.progress` | Per-game play counts: attempts, completions, completions without hints, **hints shown**, accumulated **play duration** (ms); per-skill play counts; relaxed-completion streak |
| `lww.rewards` | **Stars** per game, earned **sticker** ids, decoration points |
| `lww.sticker_book` | Sticker **placements**: sticker id, scene id, relative x/y positions |
| `lww.session_config` | Parent session rules: session minutes, daily limit, break minutes |
| `lww.session_usage` | **Session usage**: current day key (yyyy-mm-dd), milliseconds played today, last session end time, parent-unlock timestamp |

That is the complete list. Every document is a versioned JSON envelope (`{"v": …, "data": …}`);
nothing else is written anywhere.

## What the app does NOT do

- No user **accounts**, sign-in, or cloud sync
- No **ads** of any kind
- No **analytics**, crash reporting, or telemetry
- No **tracking** or advertising identifiers, no **fingerprinting**
- No **network features** (and no `INTERNET` permission to enable any)
- No **camera** or **microphone** access
- No access to **contacts**, **location**, photos, or files
- No **social** features, **chat**, or user-generated content sharing
- No **external links** in the child area (the only outward-facing surface is the PIN-protected
  parent area, which currently contains no links either)
- No in-app **purchases** or payment flows
- No collection of real names, birth dates, photos, or voice recordings

## Permissions

**None beyond the Android platform defaults.** The manifest declares no `<uses-permission>`
entries; the only additions are Flutter's standard `PROCESS_TEXT` intent *query* (part of the
Flutter engine template, not a permission). Any future dependency that introduces a permission
(especially `INTERNET`, which plugins commonly merge in) must be caught in review — inspect the
merged manifest of release builds (`build/app/outputs/logs/manifest-merger-release-report.txt` or
`aapt dump permissions` on the APK) before shipping.

## Not legal advice — pre-release professional review

This checklist describes the app's technical behaviour. It is **not legal advice**, and the
authors are not lawyers. Before releasing this app (even free, even collecting nothing), have a
qualified professional review compliance with, at minimum:

- [ ] **COPPA** (US Children's Online Privacy Protection Act) — applicability and obligations for
      child-directed apps
- [ ] **GDPR / GDPR-K** (EU, children's provisions) and the UK Age-Appropriate Design Code
- [ ] **Local child-privacy and consumer laws** of every market you publish in (including the
      Arabic-speaking markets this app targets)
- [ ] **Google Play Families self-certification** — target-audience declaration, Families Policy
      requirements, ads and data-practice attestations
- [ ] **Privacy policy** — Play requires a hosted privacy policy URL for Families apps even when
      no data is collected; have counsel review its wording
- [ ] **Store declarations** — Data safety form, content ratings, and any other attestation must
      match the app's actual behaviour exactly (they are legally significant statements)
- [ ] **Payments** — if purchases, subscriptions, or any monetization are *ever* added, the
      entire assessment above must be redone first (children's payment rules are strict)

Re-run this review whenever a dependency, feature, or store policy changes.

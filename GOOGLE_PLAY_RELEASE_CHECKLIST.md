# Google Play Release Checklist

Work through this list **in order** before uploading anything to the Play Console. Several items
(application id, signing, Families declarations) are hard blockers.

## 1. Identity

- [ ] Choose the final product name; set `AppConfig.appName` (`lib/config/app_config.dart`) and
      `android:label` in `android/app/src/main/AndroidManifest.xml`.
- [ ] Replace the placeholder **application id** `com.example.little_wonder_world`: set
      `applicationId` **and** `namespace` in `android/app/build.gradle.kts` (Play rejects
      `com.example.*`, and the id can never change after the first upload). Keep the Kotlin
      `MainActivity` package in sync with the namespace.
- [ ] Provide a real launcher icon (all `mipmap` densities) — original artwork, per
      [ASSET_GUIDE.md](ASSET_GUIDE.md).

## 2. Signing

- [ ] Create a release **upload keystore** (`keytool -genkey ...`) and store it *outside* the
      repo; back it up.
- [ ] Add `android/key.properties` (git-ignored) and a release `signingConfig` in
      `android/app/build.gradle.kts`, replacing the current debug-signing fallback (marked
      `TODO` in that file). Guide: <https://docs.flutter.dev/deployment/android#sign-the-app>.
- [ ] Enroll in **Play App Signing** at first upload.

## 3. Versioning

- [ ] Bump `version:` in `pubspec.yaml` (`x.y.z+n` → versionName `x.y.z`, versionCode `n`).
      Every upload needs a **strictly higher versionCode**; keep a changelog.

## 4. Build

- [ ] `flutter analyze` and `flutter test` are clean; run the device integration test
      (`flutter test integration_test`).
- [ ] Regenerate/verify assets if anything changed (`python3 tool/gen_audio.py` only for
      placeholders — release should ship real recordings, see [AUDIO_GUIDE.md](AUDIO_GUIDE.md)).
- [ ] `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
- [ ] Install the release build on a real device (e.g. via
      `flutter run --release`) and confirm no debug banner, sane startup time, and that the
      merged manifest still requests **no permissions** (see
      [PRIVACY_CHECKLIST.md](PRIVACY_CHECKLIST.md)).

## 5. Test matrix

Run the app (release build) across:

- [ ] A **small phone** (~5", low DPI) — touch targets still ≥ 88 px, nothing clipped in landscape
- [ ] A **tablet** (7–10") — layouts scale, corner gate still reachable by adult hands only
- [ ] **Several Android versions** — at minimum the `minSdk`, one mid-range (e.g. Android 10–12),
      and the latest (Android SDK 36 target)
- [ ] **Offline mode** — airplane mode from a cold start: everything must work identically
- [ ] **RTL** — Arabic selected: parent screens flip correctly, game scenes remain LTR, voice
      lines play in Arabic
- [ ] Interruptions: rotation ignored in child area, incoming call/backgrounding pauses audio and
      commits session time, process kill loses no progress

## 6. Google Play Families Policy

- [ ] In Play Console, complete the **target audience** declaration — this app is *designed for
      children* (ages up to 5) → the Families Policy applies in full.
- [ ] **Ads declaration: the app contains no ads.** Keep it that way; any future ad SDK would
      trigger certified-ad-SDK requirements.
- [ ] **Data safety form: no data collected, no data shared.** This must exactly match reality —
      re-verify no dependency phones home (the app has no `INTERNET` permission, which makes this
      easy to defend).
- [ ] Complete the Families self-certification questionnaire; review the current policy text —
      it changes regularly.
- [ ] Confirm with counsel that COPPA/GDPR-K review is done
      ([PRIVACY_CHECKLIST.md](PRIVACY_CHECKLIST.md) — the app's design intends compliance, but
      certification is a legal call, not a technical one).

## 7. Content rating

- [ ] Fill the IARC **content rating questionnaire** truthfully (no violence, no user
      interaction, no data collection, no purchases) — should yield the lowest age ratings
      (Everyone / PEGI 3).

## 8. Privacy policy

- [ ] Host a privacy policy at a stable public URL (required for Families apps even with zero
      collection) and link it in the store listing **and** keep its statements consistent with
      [PRIVACY_CHECKLIST.md](PRIVACY_CHECKLIST.md).

## 9. Accessibility pass

- [ ] TalkBack: parent screens fully navigable; child-area elements have meaningful semantic
      labels (`Semantics` widgets are in place — verify none regressed).
- [ ] High-contrast mode renders all interactive objects legibly; reduced-motion mode removes
      particles and large movements.
- [ ] Font scaling: parent screens survive large system font sizes without overflow.
- [ ] Touch targets: nothing interactive in the child area below `AppConfig.minTouchTarget`
      (88 px).

## 10. Store listing

- [ ] Screenshots/feature graphic from the real app; description honest about offline,
      ad-free, no-data behaviour.
- [ ] **Originality check:** name, icon, screenshots, and description must not imitate or evoke
      existing children's brands, shows, or well-known apps (no lookalike characters, logos,
      fonts, or color schemes) — both a Play impersonation-policy and a trademark issue.
- [ ] Localized listing for every supported language (EN + AR at launch).

## 11. Final manual toddler-usability pass

- [ ] Run the full checklist in
      [docs/TODDLER_USABILITY_CHECKLIST.md](docs/TODDLER_USABILITY_CHECKLIST.md) on a real device
      with the release build — ideally observing a real child in the target age range — and file
      issues for every "no" before submitting.

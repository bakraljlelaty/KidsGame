// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get gameFeedAnimals => 'Feed the Animals';

  @override
  String get gameBubblePop => 'Bubble Pop';

  @override
  String get gameDancingSocks => 'Dancing Socks';

  @override
  String get gameMuddyPig => 'Muddy Pig Bath';

  @override
  String get gameBuildRocket => 'Build the Rocket';

  @override
  String get gameBedtimeRoutine => 'Bedtime Routine';

  @override
  String get semanticsPlay => 'Play';

  @override
  String get semanticsPath => 'Learning path';

  @override
  String get semanticsRooms => 'Play rooms';

  @override
  String get semanticsStickerBook => 'Sticker book';

  @override
  String get subjectColors => 'Colors';

  @override
  String get subjectShapes => 'Shapes';

  @override
  String get subjectAnimals => 'Animals';

  @override
  String get subjectFood => 'Food';

  @override
  String get subjectNumbers => 'Numbers';

  @override
  String get subjectLetters => 'Letters';

  @override
  String get subjectArt => 'Art';

  @override
  String get subjectMilosWorld => 'Milo\'s World';

  @override
  String get profileBand => 'Age band';

  @override
  String get bandTwoThree => 'Ages 2–3';

  @override
  String get bandThreeFour => 'Ages 3–4';

  @override
  String get bandFourFive => 'Ages 4–5';

  @override
  String get bandFiveSix => 'Ages 5–6';

  @override
  String get bandTwoThreeDescription =>
      'First discoveries: two big choices, lots of help, colours and shapes.';

  @override
  String get bandThreeFourDescription =>
      'Three choices, first letters, counting to five.';

  @override
  String get bandFourFiveDescription =>
      'Four choices, patterns, counting to seven, first tracing.';

  @override
  String get bandFiveSixDescription =>
      'Longer patterns, counting to ten, the full alphabet and finer tracing.';

  @override
  String get skillMemory => 'Memory';

  @override
  String get skillPatterns => 'Patterns';

  @override
  String get semanticsBack => 'Go back';

  @override
  String get semanticsHome => 'Go home';

  @override
  String get semanticsParentCorner =>
      'Parent area corner. Hold both top corners to open.';

  @override
  String get semanticsMilo => 'Milo the friendly animal';

  @override
  String get semanticsWorldMap => 'Choose a game';

  @override
  String get parentGateTitle => 'Grown-ups only';

  @override
  String get parentGateInstruction =>
      'Hold both top corners of the screen at the same time for three seconds.';

  @override
  String get pinEnterTitle => 'Enter the parent PIN';

  @override
  String get pinIncorrect => 'That PIN does not match. Please try again.';

  @override
  String pinDefaultHint(String pin) {
    return 'The default PIN is $pin. Please change it in Settings.';
  }

  @override
  String get pinChangeTitle => 'Change parent PIN';

  @override
  String get pinCurrent => 'Current PIN';

  @override
  String get pinNew => 'New PIN';

  @override
  String get pinConfirmNew => 'Repeat new PIN';

  @override
  String get pinChanged => 'The parent PIN was updated.';

  @override
  String get pinMismatch => 'The two PINs do not match.';

  @override
  String get pinTooShort => 'The PIN needs four digits.';

  @override
  String get dashboardTitle => 'Parent dashboard';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabGames => 'Games';

  @override
  String get tabSession => 'Session';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabSettings => 'Settings';

  @override
  String get profileTitle => 'Child profile';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileNicknameHint => 'A nickname only — no real names needed.';

  @override
  String get profileAgeGroup => 'Age group';

  @override
  String get ageGroupTwo => 'Around 2 years';

  @override
  String get ageGroupThree => 'Around 3 years';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get profileStage => 'Development stage';

  @override
  String get stageExplorer => 'Explorer';

  @override
  String get stageHelper => 'Helper';

  @override
  String get stageLittleThinker => 'Little Thinker';

  @override
  String get stageExplorerDescription =>
      'One thing at a time. Tapping, very large objects, quick help.';

  @override
  String get stageHelperDescription =>
      'Tap and drag. Two or three choices, simple matching, small puzzles.';

  @override
  String get stageLittleThinkerDescription =>
      'Up to five objects, four-piece puzzles, counting to three, little routines.';

  @override
  String get stageAutoProgress => 'Adjust stage automatically';

  @override
  String get stageAutoProgressHint =>
      'Moves up gently after several relaxed, hint-free sessions. Never based on speed.';

  @override
  String get gamesAccessTitle => 'Game access';

  @override
  String get gamesAccessHint => 'Choose which games appear on the world map.';

  @override
  String get playModeTitle => 'Play order';

  @override
  String get playModeFree => 'Free choice';

  @override
  String get playModeFreeDescription => 'Your child can pick any enabled game.';

  @override
  String get playModeGuided => 'Guided order';

  @override
  String get playModeGuidedDescription =>
      'Games open one after another in a gentle order.';

  @override
  String get unlockAllGames => 'Enable all games';

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetProgressConfirmTitle => 'Reset all progress?';

  @override
  String get resetProgressConfirmBody =>
      'Stars, stickers and play history will be removed from this device. Settings and the profile are kept.';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get sessionTitle => 'Session time';

  @override
  String get sessionLength => 'Session length';

  @override
  String get sessionNoTimer => 'No timer';

  @override
  String sessionMinutesOption(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get dailyLimitTitle => 'Daily limit';

  @override
  String get dailyLimitNone => 'No daily limit';

  @override
  String get breakTitle => 'Break between sessions';

  @override
  String breakMinutesOption(int minutes) {
    return '$minutes minute break';
  }

  @override
  String get sessionEndBehaviourNote =>
      'A soft sound plays shortly before time is up. Your child may always finish the mini-game they are playing; then Milo gets sleepy and the day winds down calmly.';

  @override
  String get sessionAllowExtra => 'Allow another session now';

  @override
  String get sessionAllowExtraDone => 'A new session is available.';

  @override
  String sessionTodayPlayed(int minutes) {
    return 'Played today: $minutes min';
  }

  @override
  String get progressTitle => 'Progress';

  @override
  String progressIntro(String name) {
    return 'A relaxed look at how $name likes to play. This is a play overview, not an assessment.';
  }

  @override
  String get totalPlayTime => 'Approximate play time';

  @override
  String playTimeValue(int minutes) {
    return 'About $minutes minutes';
  }

  @override
  String get gamesAttempted => 'Games tried';

  @override
  String get gamesCompleted => 'Games finished';

  @override
  String get hintsShown => 'Hints shown';

  @override
  String get favoriteGames => 'Often chosen';

  @override
  String get skillsPractised => 'Skills practised';

  @override
  String get currentStageLabel => 'Current stage';

  @override
  String get noPlayYet => 'No play sessions yet — everything starts fresh!';

  @override
  String get skillTapping => 'Tapping';

  @override
  String get skillDragging => 'Dragging';

  @override
  String get skillSwiping => 'Swiping';

  @override
  String get skillMatching => 'Matching';

  @override
  String get skillColors => 'Colours';

  @override
  String get skillShapes => 'Shapes';

  @override
  String get skillCounting => 'Counting';

  @override
  String get skillSequencing => 'Sequencing';

  @override
  String get skillRoutines => 'Daily routines';

  @override
  String get skillAttention => 'Attention';

  @override
  String get skillAnimals => 'Animals';

  @override
  String get skillSpatial => 'Spatial play';

  @override
  String get skillFineMotor => 'Fine motor play';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsMusic => 'Music';

  @override
  String get settingsSoundEffects => 'Sound effects';

  @override
  String get settingsVoice => 'Voice instructions';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsReducedMotion => 'Reduce motion';

  @override
  String get settingsReducedMotionHint =>
      'Calmer animations and no particle effects.';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsHighContrastHint =>
      'Stronger outlines and colours for interactive objects.';

  @override
  String get settingsHaptics => 'Gentle vibration';

  @override
  String get settingsLeftHanded => 'Left-handed layout';

  @override
  String get settingsLeftHandedHint =>
      'Moves helper buttons in games to the left side.';

  @override
  String get settingsRestoreDefaults => 'Restore default settings';

  @override
  String get settingsRestored => 'Default settings restored.';

  @override
  String get settingsChangePin => 'Change parent PIN';

  @override
  String get settingsDeleteData => 'Delete all child data';

  @override
  String get deleteDataConfirmTitle => 'Delete all data?';

  @override
  String get deleteDataConfirmBody =>
      'Profile, settings, progress, stars and stickers will be removed from this device permanently. Nothing is stored anywhere else.';

  @override
  String get deleteDataDone => 'All local data was deleted.';

  @override
  String get privacyNote =>
      'Everything stays on this device. This app has no accounts, no ads, no analytics and no internet features.';

  @override
  String get stickerBookTitle => 'Sticker book';

  @override
  String get stickerSceneMeadow => 'Meadow';

  @override
  String get stickerSceneSky => 'Sky';

  @override
  String get stickerSceneSea => 'Sea';

  @override
  String get stickerTrayEmpty => 'Play the games to collect stickers!';

  @override
  String get worldLocked => 'This game is resting right now.';

  @override
  String get sessionOverParentNote =>
      'Play time is over for now. A new session opens after the break, or you can allow one from the parent dashboard.';
}

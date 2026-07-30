import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @gameFeedAnimals.
  ///
  /// In en, this message translates to:
  /// **'Feed the Animals'**
  String get gameFeedAnimals;

  /// No description provided for @gameBubblePop.
  ///
  /// In en, this message translates to:
  /// **'Bubble Pop'**
  String get gameBubblePop;

  /// No description provided for @gameDancingSocks.
  ///
  /// In en, this message translates to:
  /// **'Dancing Socks'**
  String get gameDancingSocks;

  /// No description provided for @gameMuddyPig.
  ///
  /// In en, this message translates to:
  /// **'Muddy Pig Bath'**
  String get gameMuddyPig;

  /// No description provided for @gameBuildRocket.
  ///
  /// In en, this message translates to:
  /// **'Build the Rocket'**
  String get gameBuildRocket;

  /// No description provided for @gameBedtimeRoutine.
  ///
  /// In en, this message translates to:
  /// **'Bedtime Routine'**
  String get gameBedtimeRoutine;

  /// No description provided for @semanticsPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get semanticsPlay;

  /// No description provided for @semanticsPath.
  ///
  /// In en, this message translates to:
  /// **'Learning path'**
  String get semanticsPath;

  /// No description provided for @semanticsRooms.
  ///
  /// In en, this message translates to:
  /// **'Play rooms'**
  String get semanticsRooms;

  /// No description provided for @semanticsStickerBook.
  ///
  /// In en, this message translates to:
  /// **'Sticker book'**
  String get semanticsStickerBook;

  /// No description provided for @subjectColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get subjectColors;

  /// No description provided for @subjectShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get subjectShapes;

  /// No description provided for @subjectAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get subjectAnimals;

  /// No description provided for @subjectFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get subjectFood;

  /// No description provided for @subjectNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get subjectNumbers;

  /// No description provided for @subjectLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get subjectLetters;

  /// No description provided for @subjectArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get subjectArt;

  /// No description provided for @subjectMilosWorld.
  ///
  /// In en, this message translates to:
  /// **'Milo\'s World'**
  String get subjectMilosWorld;

  /// No description provided for @profileBand.
  ///
  /// In en, this message translates to:
  /// **'Age band'**
  String get profileBand;

  /// No description provided for @bandTwoThree.
  ///
  /// In en, this message translates to:
  /// **'Ages 2–3'**
  String get bandTwoThree;

  /// No description provided for @bandThreeFour.
  ///
  /// In en, this message translates to:
  /// **'Ages 3–4'**
  String get bandThreeFour;

  /// No description provided for @bandFourFive.
  ///
  /// In en, this message translates to:
  /// **'Ages 4–5'**
  String get bandFourFive;

  /// No description provided for @bandFiveSix.
  ///
  /// In en, this message translates to:
  /// **'Ages 5–6'**
  String get bandFiveSix;

  /// No description provided for @bandTwoThreeDescription.
  ///
  /// In en, this message translates to:
  /// **'First discoveries: two big choices, lots of help, colours and shapes.'**
  String get bandTwoThreeDescription;

  /// No description provided for @bandThreeFourDescription.
  ///
  /// In en, this message translates to:
  /// **'Three choices, first letters, counting to five.'**
  String get bandThreeFourDescription;

  /// No description provided for @bandFourFiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Four choices, patterns, counting to seven, first tracing.'**
  String get bandFourFiveDescription;

  /// No description provided for @bandFiveSixDescription.
  ///
  /// In en, this message translates to:
  /// **'Longer patterns, counting to ten, the full alphabet and finer tracing.'**
  String get bandFiveSixDescription;

  /// No description provided for @skillMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get skillMemory;

  /// No description provided for @skillPatterns.
  ///
  /// In en, this message translates to:
  /// **'Patterns'**
  String get skillPatterns;

  /// No description provided for @semanticsBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get semanticsBack;

  /// No description provided for @semanticsHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get semanticsHome;

  /// No description provided for @semanticsParentCorner.
  ///
  /// In en, this message translates to:
  /// **'Parent area corner. Hold both top corners to open.'**
  String get semanticsParentCorner;

  /// No description provided for @semanticsMilo.
  ///
  /// In en, this message translates to:
  /// **'Milo the friendly animal'**
  String get semanticsMilo;

  /// No description provided for @semanticsWorldMap.
  ///
  /// In en, this message translates to:
  /// **'Choose a game'**
  String get semanticsWorldMap;

  /// No description provided for @parentGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Grown-ups only'**
  String get parentGateTitle;

  /// No description provided for @parentGateInstruction.
  ///
  /// In en, this message translates to:
  /// **'Hold both top corners of the screen at the same time for three seconds.'**
  String get parentGateInstruction;

  /// No description provided for @pinEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the parent PIN'**
  String get pinEnterTitle;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'That PIN does not match. Please try again.'**
  String get pinIncorrect;

  /// No description provided for @pinDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'The default PIN is {pin}. Please change it in Settings.'**
  String pinDefaultHint(String pin);

  /// No description provided for @pinChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change parent PIN'**
  String get pinChangeTitle;

  /// No description provided for @pinCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get pinCurrent;

  /// No description provided for @pinNew.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get pinNew;

  /// No description provided for @pinConfirmNew.
  ///
  /// In en, this message translates to:
  /// **'Repeat new PIN'**
  String get pinConfirmNew;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'The parent PIN was updated.'**
  String get pinChanged;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two PINs do not match.'**
  String get pinMismatch;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'The PIN needs four digits.'**
  String get pinTooShort;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent dashboard'**
  String get dashboardTitle;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get tabGames;

  /// No description provided for @tabSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get tabSession;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Child profile'**
  String get profileTitle;

  /// No description provided for @profileNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNickname;

  /// No description provided for @profileNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'A nickname only — no real names needed.'**
  String get profileNicknameHint;

  /// No description provided for @profileAgeGroup.
  ///
  /// In en, this message translates to:
  /// **'Age group'**
  String get profileAgeGroup;

  /// No description provided for @ageGroupTwo.
  ///
  /// In en, this message translates to:
  /// **'Around 2 years'**
  String get ageGroupTwo;

  /// No description provided for @ageGroupThree.
  ///
  /// In en, this message translates to:
  /// **'Around 3 years'**
  String get ageGroupThree;

  /// No description provided for @profileAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get profileAvatar;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @profileStage.
  ///
  /// In en, this message translates to:
  /// **'Development stage'**
  String get profileStage;

  /// No description provided for @stageExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get stageExplorer;

  /// No description provided for @stageHelper.
  ///
  /// In en, this message translates to:
  /// **'Helper'**
  String get stageHelper;

  /// No description provided for @stageLittleThinker.
  ///
  /// In en, this message translates to:
  /// **'Little Thinker'**
  String get stageLittleThinker;

  /// No description provided for @stageExplorerDescription.
  ///
  /// In en, this message translates to:
  /// **'One thing at a time. Tapping, very large objects, quick help.'**
  String get stageExplorerDescription;

  /// No description provided for @stageHelperDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap and drag. Two or three choices, simple matching, small puzzles.'**
  String get stageHelperDescription;

  /// No description provided for @stageLittleThinkerDescription.
  ///
  /// In en, this message translates to:
  /// **'Up to five objects, four-piece puzzles, counting to three, little routines.'**
  String get stageLittleThinkerDescription;

  /// No description provided for @stageAutoProgress.
  ///
  /// In en, this message translates to:
  /// **'Adjust stage automatically'**
  String get stageAutoProgress;

  /// No description provided for @stageAutoProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Moves up gently after several relaxed, hint-free sessions. Never based on speed.'**
  String get stageAutoProgressHint;

  /// No description provided for @gamesAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Game access'**
  String get gamesAccessTitle;

  /// No description provided for @gamesAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which games appear on the world map.'**
  String get gamesAccessHint;

  /// No description provided for @playModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Play order'**
  String get playModeTitle;

  /// No description provided for @playModeFree.
  ///
  /// In en, this message translates to:
  /// **'Free choice'**
  String get playModeFree;

  /// No description provided for @playModeFreeDescription.
  ///
  /// In en, this message translates to:
  /// **'Your child can pick any enabled game.'**
  String get playModeFreeDescription;

  /// No description provided for @playModeGuided.
  ///
  /// In en, this message translates to:
  /// **'Guided order'**
  String get playModeGuided;

  /// No description provided for @playModeGuidedDescription.
  ///
  /// In en, this message translates to:
  /// **'Games open one after another in a gentle order.'**
  String get playModeGuidedDescription;

  /// No description provided for @unlockAllGames.
  ///
  /// In en, this message translates to:
  /// **'Enable all games'**
  String get unlockAllGames;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetProgressConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress?'**
  String get resetProgressConfirmTitle;

  /// No description provided for @resetProgressConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Stars, stickers and play history will be removed from this device. Settings and the profile are kept.'**
  String get resetProgressConfirmBody;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session time'**
  String get sessionTitle;

  /// No description provided for @sessionLength.
  ///
  /// In en, this message translates to:
  /// **'Session length'**
  String get sessionLength;

  /// No description provided for @sessionNoTimer.
  ///
  /// In en, this message translates to:
  /// **'No timer'**
  String get sessionNoTimer;

  /// No description provided for @sessionMinutesOption.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String sessionMinutesOption(int minutes);

  /// No description provided for @dailyLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily limit'**
  String get dailyLimitTitle;

  /// No description provided for @dailyLimitNone.
  ///
  /// In en, this message translates to:
  /// **'No daily limit'**
  String get dailyLimitNone;

  /// No description provided for @breakTitle.
  ///
  /// In en, this message translates to:
  /// **'Break between sessions'**
  String get breakTitle;

  /// No description provided for @breakMinutesOption.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minute break'**
  String breakMinutesOption(int minutes);

  /// No description provided for @sessionEndBehaviourNote.
  ///
  /// In en, this message translates to:
  /// **'A soft sound plays shortly before time is up. Your child may always finish the mini-game they are playing; then Milo gets sleepy and the day winds down calmly.'**
  String get sessionEndBehaviourNote;

  /// No description provided for @sessionAllowExtra.
  ///
  /// In en, this message translates to:
  /// **'Allow another session now'**
  String get sessionAllowExtra;

  /// No description provided for @sessionAllowExtraDone.
  ///
  /// In en, this message translates to:
  /// **'A new session is available.'**
  String get sessionAllowExtraDone;

  /// No description provided for @sessionTodayPlayed.
  ///
  /// In en, this message translates to:
  /// **'Played today: {minutes} min'**
  String sessionTodayPlayed(int minutes);

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressIntro.
  ///
  /// In en, this message translates to:
  /// **'A relaxed look at how {name} likes to play. This is a play overview, not an assessment.'**
  String progressIntro(String name);

  /// No description provided for @totalPlayTime.
  ///
  /// In en, this message translates to:
  /// **'Approximate play time'**
  String get totalPlayTime;

  /// No description provided for @playTimeValue.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} minutes'**
  String playTimeValue(int minutes);

  /// No description provided for @gamesAttempted.
  ///
  /// In en, this message translates to:
  /// **'Games tried'**
  String get gamesAttempted;

  /// No description provided for @gamesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Games finished'**
  String get gamesCompleted;

  /// No description provided for @hintsShown.
  ///
  /// In en, this message translates to:
  /// **'Hints shown'**
  String get hintsShown;

  /// No description provided for @favoriteGames.
  ///
  /// In en, this message translates to:
  /// **'Often chosen'**
  String get favoriteGames;

  /// No description provided for @skillsPractised.
  ///
  /// In en, this message translates to:
  /// **'Skills practised'**
  String get skillsPractised;

  /// No description provided for @currentStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Current stage'**
  String get currentStageLabel;

  /// No description provided for @noPlayYet.
  ///
  /// In en, this message translates to:
  /// **'No play sessions yet — everything starts fresh!'**
  String get noPlayYet;

  /// No description provided for @skillTapping.
  ///
  /// In en, this message translates to:
  /// **'Tapping'**
  String get skillTapping;

  /// No description provided for @skillDragging.
  ///
  /// In en, this message translates to:
  /// **'Dragging'**
  String get skillDragging;

  /// No description provided for @skillSwiping.
  ///
  /// In en, this message translates to:
  /// **'Swiping'**
  String get skillSwiping;

  /// No description provided for @skillMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get skillMatching;

  /// No description provided for @skillColors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get skillColors;

  /// No description provided for @skillShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get skillShapes;

  /// No description provided for @skillCounting.
  ///
  /// In en, this message translates to:
  /// **'Counting'**
  String get skillCounting;

  /// No description provided for @skillSequencing.
  ///
  /// In en, this message translates to:
  /// **'Sequencing'**
  String get skillSequencing;

  /// No description provided for @skillRoutines.
  ///
  /// In en, this message translates to:
  /// **'Daily routines'**
  String get skillRoutines;

  /// No description provided for @skillAttention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get skillAttention;

  /// No description provided for @skillAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get skillAnimals;

  /// No description provided for @skillSpatial.
  ///
  /// In en, this message translates to:
  /// **'Spatial play'**
  String get skillSpatial;

  /// No description provided for @skillFineMotor.
  ///
  /// In en, this message translates to:
  /// **'Fine motor play'**
  String get skillFineMotor;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusic;

  /// No description provided for @settingsSoundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSoundEffects;

  /// No description provided for @settingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice instructions'**
  String get settingsVoice;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguage;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReducedMotion;

  /// No description provided for @settingsReducedMotionHint.
  ///
  /// In en, this message translates to:
  /// **'Calmer animations and no particle effects.'**
  String get settingsReducedMotionHint;

  /// No description provided for @settingsHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get settingsHighContrast;

  /// No description provided for @settingsHighContrastHint.
  ///
  /// In en, this message translates to:
  /// **'Stronger outlines and colours for interactive objects.'**
  String get settingsHighContrastHint;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Gentle vibration'**
  String get settingsHaptics;

  /// No description provided for @settingsLeftHanded.
  ///
  /// In en, this message translates to:
  /// **'Left-handed layout'**
  String get settingsLeftHanded;

  /// No description provided for @settingsLeftHandedHint.
  ///
  /// In en, this message translates to:
  /// **'Moves helper buttons in games to the left side.'**
  String get settingsLeftHandedHint;

  /// No description provided for @settingsRestoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore default settings'**
  String get settingsRestoreDefaults;

  /// No description provided for @settingsRestored.
  ///
  /// In en, this message translates to:
  /// **'Default settings restored.'**
  String get settingsRestored;

  /// No description provided for @settingsChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change parent PIN'**
  String get settingsChangePin;

  /// No description provided for @settingsDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Delete all child data'**
  String get settingsDeleteData;

  /// No description provided for @deleteDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteDataConfirmTitle;

  /// No description provided for @deleteDataConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Profile, settings, progress, stars and stickers will be removed from this device permanently. Nothing is stored anywhere else.'**
  String get deleteDataConfirmBody;

  /// No description provided for @deleteDataDone.
  ///
  /// In en, this message translates to:
  /// **'All local data was deleted.'**
  String get deleteDataDone;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this device. This app has no accounts, no ads, no analytics and no internet features.'**
  String get privacyNote;

  /// No description provided for @stickerBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticker book'**
  String get stickerBookTitle;

  /// No description provided for @stickerSceneMeadow.
  ///
  /// In en, this message translates to:
  /// **'Meadow'**
  String get stickerSceneMeadow;

  /// No description provided for @stickerSceneSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get stickerSceneSky;

  /// No description provided for @stickerSceneSea.
  ///
  /// In en, this message translates to:
  /// **'Sea'**
  String get stickerSceneSea;

  /// No description provided for @stickerTrayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Play the games to collect stickers!'**
  String get stickerTrayEmpty;

  /// No description provided for @worldLocked.
  ///
  /// In en, this message translates to:
  /// **'This game is resting right now.'**
  String get worldLocked;

  /// No description provided for @sessionOverParentNote.
  ///
  /// In en, this message translates to:
  /// **'Play time is over for now. A new session opens after the break, or you can allow one from the parent dashboard.'**
  String get sessionOverParentNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

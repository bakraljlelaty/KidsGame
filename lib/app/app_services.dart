import '../core/audio/audio_manager.dart';
import '../core/persistence/local_store.dart';
import '../features/learning_path/path_progress.dart';
import '../features/parent_dashboard/game_access.dart';
import '../features/parent_dashboard/game_access_controller.dart';
import '../features/profiles/child_profile.dart';
import '../features/profiles/profile_controller.dart';
import '../features/progress/progress_controller.dart';
import '../features/progress/progress_data.dart';
import '../features/rewards/reward_data.dart';
import '../features/rewards/rewards_controller.dart';
import '../features/session_control/session_controller.dart';
import '../features/session_control/session_data.dart';
import '../features/settings/app_settings.dart';
import '../features/settings/settings_controller.dart';
import '../features/sticker_book/sticker_book_controller.dart';
import '../features/sticker_book/sticker_placements.dart';

/// Builds and owns every service and controller. One instance per app run;
/// tests construct it with an [InMemoryStore].
class AppServices {
  AppServices._({
    required this.store,
    required this.audio,
    required this.settings,
    required this.profile,
    required this.gameAccess,
    required this.progress,
    required this.rewards,
    required this.stickerBook,
    required this.session,
    required this.pathProgress,
  });

  final LocalStore store;
  final AudioManager audio;
  final SettingsController settings;
  final ProfileController profile;
  final GameAccessController gameAccess;
  final ProgressController progress;
  final RewardsController rewards;
  final StickerBookController stickerBook;
  final SessionController session;
  final PathProgressController pathProgress;

  static Future<AppServices> bootstrap({
    LocalStore? store,
    DateTime Function()? clock,
    bool enableAutoTick = true,
    bool initAudio = true,
  }) async {
    final localStore = store ?? await SharedPreferencesStore.open();

    final audio = AudioManager();
    final settings = SettingsController(SettingsRepository(localStore));
    final profile = ProfileController(ProfileRepository(localStore));
    final gameAccess =
        GameAccessController(GameAccessRepository(localStore));
    final progress =
        ProgressController(ProgressRepository(localStore), profile);
    final rewards = RewardsController(RewardRepository(localStore));
    final stickerBook =
        StickerBookController(StickerBookRepository(localStore));
    final session = SessionController(
      SessionRepository(localStore),
      clock: clock,
      enableAutoTick: enableAutoTick,
    );
    final pathProgress =
        PathProgressController(PathProgressRepository(localStore));

    await settings.init();
    await profile.init();
    await gameAccess.init();
    await progress.init();
    await rewards.init();
    await stickerBook.init();
    await session.init();
    await pathProgress.init();

    if (initAudio) {
      await audio.init();
    }
    audio.applySettings(settings.settings);
    settings.addListener(() => audio.applySettings(settings.settings));

    return AppServices._(
      store: localStore,
      audio: audio,
      settings: settings,
      profile: profile,
      gameAccess: gameAccess,
      progress: progress,
      rewards: rewards,
      stickerBook: stickerBook,
      session: session,
      pathProgress: pathProgress,
    );
  }

  /// Removes progress, stars and stickers but keeps profile and settings.
  Future<void> resetProgress() async {
    await progress.reset();
    await rewards.reset();
    await stickerBook.reset();
    await pathProgress.reset();
  }

  /// "Delete all child data": wipes every locally stored key, then reloads
  /// all controllers with fresh defaults.
  Future<void> deleteAllData() async {
    await store.clearAll();
    await settings.reloadFromStore();
    await profile.reloadFromStore();
    await gameAccess.reloadFromStore();
    await progress.reloadFromStore();
    await rewards.reloadFromStore();
    await stickerBook.reloadFromStore();
    await session.reloadFromStore();
    await pathProgress.reloadFromStore();
  }

  Future<void> dispose() async {
    session.dispose();
    await audio.dispose();
  }
}

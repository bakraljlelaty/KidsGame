import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/audio/audio_manager.dart';
import '../core/audio/sound_effects.dart';
import '../core/theme/app_theme.dart';
import '../features/child_home/child_home_screen.dart';
import '../features/parent_dashboard/game_access_controller.dart';
import '../features/profiles/profile_controller.dart';
import '../features/progress/progress_controller.dart';
import '../features/rewards/rewards_controller.dart';
import '../features/session_control/session_controller.dart';
import '../features/settings/settings_controller.dart';
import '../features/sticker_book/sticker_book_controller.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';

class LittleWonderApp extends StatefulWidget {
  const LittleWonderApp({super.key, required this.services});

  final AppServices services;

  @override
  State<LittleWonderApp> createState() => _LittleWonderAppState();
}

class _LittleWonderAppState extends State<LittleWonderApp>
    with WidgetsBindingObserver {
  AppServices get services => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    services.session.onWarning =
        () => services.audio.playEffect(SoundEffect.sessionReminder);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        services.audio.onAppPaused();
        services.session.onAppPaused();
      case AppLifecycleState.resumed:
        services.audio.onAppResumed();
        services.session.onAppResumed();
      case AppLifecycleState.detached:
        services.audio.onAppPaused();
        services.session.onAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        Provider<AudioManager>.value(value: services.audio),
        ChangeNotifierProvider<SettingsController>.value(
            value: services.settings),
        ChangeNotifierProvider<ProfileController>.value(
            value: services.profile),
        ChangeNotifierProvider<GameAccessController>.value(
            value: services.gameAccess),
        ChangeNotifierProvider<ProgressController>.value(
            value: services.progress),
        ChangeNotifierProvider<RewardsController>.value(
            value: services.rewards),
        ChangeNotifierProvider<StickerBookController>.value(
            value: services.stickerBook),
        ChangeNotifierProvider<SessionController>.value(
            value: services.session),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(
              highContrast: settings.settings.highContrast,
            ),
            locale: Locale(settings.settings.languageCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const ChildHomeScreen(),
          );
        },
      ),
    );
  }
}

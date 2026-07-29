import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'sections/games_section.dart';
import 'sections/profile_section.dart';
import 'sections/progress_section.dart';
import 'sections/session_section.dart';
import 'sections/settings_section.dart';

/// The PIN-protected parent area. Portrait or landscape (unlike the child
/// area, which is landscape-first); orientation is restored on exit.
class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      const ProfileSection(),
      const GamesSection(),
      const SessionSection(),
      const ProgressSection(),
      const SettingsSection(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.semanticsBack,
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(child: sections[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.face_rounded),
            label: l10n.tabProfile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.extension_rounded),
            label: l10n.tabGames,
          ),
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            label: l10n.tabSession,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_rounded),
            label: l10n.tabProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}

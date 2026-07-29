import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/game/game_registry.dart';
import '../../../shared/widgets/world_icon.dart';
import '../game_access.dart';
import '../game_access_controller.dart';

/// Enable/disable games, choose free vs guided play, reset progress.
class GamesSection extends StatelessWidget {
  const GamesSection({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = context.read<AppServices>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetProgressConfirmTitle),
        content: Text(l10n.resetProgressConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await services.resetProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<GameAccessController>();
    final access = controller.access;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.playModeTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                RadioListTile<PlayMode>(
                  value: PlayMode.free,
                  // ignore: deprecated_member_use
                  groupValue: access.playMode,
                  // ignore: deprecated_member_use
                  onChanged: (mode) =>
                      controller.setPlayMode(mode ?? PlayMode.free),
                  title: Text(l10n.playModeFree),
                  subtitle: Text(l10n.playModeFreeDescription),
                ),
                RadioListTile<PlayMode>(
                  value: PlayMode.guided,
                  // ignore: deprecated_member_use
                  groupValue: access.playMode,
                  // ignore: deprecated_member_use
                  onChanged: (mode) =>
                      controller.setPlayMode(mode ?? PlayMode.free),
                  title: Text(l10n.playModeGuided),
                  subtitle: Text(l10n.playModeGuidedDescription),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.gamesAccessTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l10n.gamesAccessHint,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                for (final definition in GameRegistry.all)
                  SwitchListTile(
                    secondary:
                        WorldIcon(gameId: definition.id, size: 44),
                    title: Text(definition.title(l10n)),
                    value: access.isEnabled(definition.id),
                    onChanged: (value) => controller.setGameEnabled(
                        definition.id, value),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: controller.enableAllGames,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(l10n.unlockAllGames),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: Text(l10n.resetProgress),
            onTap: () => _confirmReset(context),
          ),
        ),
      ],
    );
  }
}

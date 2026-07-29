import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_services.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/settings_controller.dart';

/// Audio, motion, contrast, haptics, layout, language, PIN and data controls.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  Future<void> _changePin(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsController>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final repeatController = TextEditingController();

    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.pinChangeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(labelText: l10n.pinCurrent),
              ),
              TextField(
                controller: newController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(labelText: l10n.pinNew),
              ),
              TextField(
                controller: repeatController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration:
                    InputDecoration(labelText: l10n.pinConfirmNew),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style: TextStyle(
                          color:
                              Theme.of(dialogContext).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (!settings.checkPin(currentController.text)) {
                  setState(() => error = l10n.pinIncorrect);
                  return;
                }
                if (newController.text.length != 4) {
                  setState(() => error = l10n.pinTooShort);
                  return;
                }
                if (newController.text != repeatController.text) {
                  setState(() => error = l10n.pinMismatch);
                  return;
                }
                await settings.setParentPin(newController.text);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(l10n.pinChanged)),
                  );
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final services = context.read<AppServices>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteDataConfirmTitle),
        content: Text(l10n.deleteDataConfirmBody),
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
      await services.deleteAllData();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteDataDone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.music_note_rounded),
                title: Text(l10n.settingsMusic),
                value: settings.musicEnabled,
                onChanged: controller.setMusicEnabled,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.graphic_eq_rounded),
                title: Text(l10n.settingsSoundEffects),
                value: settings.soundEffectsEnabled,
                onChanged: controller.setSoundEffectsEnabled,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.record_voice_over_rounded),
                title: Text(l10n.settingsVoice),
                value: settings.voiceEnabled,
                onChanged: controller.setVoiceEnabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.animation_rounded),
                title: Text(l10n.settingsReducedMotion),
                subtitle: Text(l10n.settingsReducedMotionHint),
                value: settings.reducedMotion,
                onChanged: controller.setReducedMotion,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.contrast_rounded),
                title: Text(l10n.settingsHighContrast),
                subtitle: Text(l10n.settingsHighContrastHint),
                value: settings.highContrast,
                onChanged: controller.setHighContrast,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration_rounded),
                title: Text(l10n.settingsHaptics),
                value: settings.hapticsEnabled,
                onChanged: controller.setHapticsEnabled,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.back_hand_outlined),
                title: Text(l10n.settingsLeftHanded),
                subtitle: Text(l10n.settingsLeftHandedHint),
                value: settings.leftHanded,
                onChanged: controller.setLeftHanded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: Text(l10n.settingsChangePin),
                onTap: () => _changePin(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore_rounded),
                title: Text(l10n.settingsRestoreDefaults),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await controller.restoreDefaults();
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.settingsRestored)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded),
                title: Text(l10n.settingsDeleteData),
                onTap: () => _confirmDeleteAll(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            l10n.privacyNote,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

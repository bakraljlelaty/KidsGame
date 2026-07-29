import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/palette.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/development_stage.dart';
import '../../profiles/child_profile.dart';
import '../../profiles/profile_controller.dart';
import '../../settings/settings_controller.dart';

/// Child profile: nickname, approximate age group, avatar, language, stage.
/// Deliberately collects no real personal data.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileController = context.watch<ProfileController>();
    final profile = profileController.profile;
    final settings = context.watch<SettingsController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.profileTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: profile.nickname,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: l10n.profileNickname,
                    helperText: l10n.profileNicknameHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: profileController.setNickname,
                ),
                const SizedBox(height: 12),
                Text(l10n.profileAgeGroup),
                const SizedBox(height: 8),
                SegmentedButton<AgeGroup>(
                  segments: [
                    ButtonSegment(
                      value: AgeGroup.aroundTwo,
                      label: Text(l10n.ageGroupTwo),
                    ),
                    ButtonSegment(
                      value: AgeGroup.aroundThree,
                      label: Text(l10n.ageGroupThree),
                    ),
                  ],
                  selected: {profile.ageGroup},
                  onSelectionChanged: (selection) =>
                      profileController.setAgeGroup(selection.first),
                ),
                const SizedBox(height: 16),
                Text(l10n.profileAvatar),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final avatar in const [
                      ('star', Icons.star_rounded, Palette.starGold),
                      ('flower', Icons.local_florist_rounded,
                          Palette.softPink),
                      ('cloud', Icons.cloud_rounded, Palette.babyBlue),
                      ('leaf', Icons.eco_rounded, Palette.softGreen),
                    ])
                      _AvatarChoice(
                        id: avatar.$1,
                        icon: avatar.$2,
                        color: avatar.$3,
                        selected: profile.avatarId == avatar.$1,
                        onTap: () =>
                            profileController.setAvatar(avatar.$1),
                      ),
                  ],
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
                Text(l10n.profileLanguage,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'en', label: Text(l10n.languageEnglish)),
                    ButtonSegment(
                        value: 'ar', label: Text(l10n.languageArabic)),
                  ],
                  selected: {profile.languageCode},
                  onSelectionChanged: (selection) {
                    final code = selection.first;
                    profileController.setLanguage(code);
                    settings.setLanguage(code);
                  },
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
                Text(l10n.profileStage,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final stage in DevelopmentStage.values)
                  RadioListTile<DevelopmentStage>(
                    value: stage,
                    // ignore: deprecated_member_use
                    groupValue: profile.stage,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        profileController.setStage(value);
                      }
                    },
                    title: Text(switch (stage) {
                      DevelopmentStage.explorer => l10n.stageExplorer,
                      DevelopmentStage.helper => l10n.stageHelper,
                      DevelopmentStage.littleThinker =>
                        l10n.stageLittleThinker,
                    }),
                    subtitle: Text(switch (stage) {
                      DevelopmentStage.explorer =>
                        l10n.stageExplorerDescription,
                      DevelopmentStage.helper =>
                        l10n.stageHelperDescription,
                      DevelopmentStage.littleThinker =>
                        l10n.stageLittleThinkerDescription,
                    }),
                  ),
                SwitchListTile(
                  value: profile.autoStageProgression,
                  onChanged: profileController.setAutoStageProgression,
                  title: Text(l10n.stageAutoProgress),
                  subtitle: Text(l10n.stageAutoProgressHint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.id,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: id,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.3),
            border: Border.all(
              color: selected ? Palette.outlineStrong : Colors.transparent,
              width: 3,
            ),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/palette.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/game/game_registry.dart';
import '../../../shared/models/development_stage.dart';
import '../../../shared/models/skill.dart';
import '../../../shared/widgets/world_icon.dart';
import '../../profiles/profile_controller.dart';
import '../../progress/progress_controller.dart';

/// Neutral play overview for parents. Never grades, never diagnoses.
class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key});

  String _skillName(AppLocalizations l10n, Skill skill) => switch (skill) {
        Skill.tapping => l10n.skillTapping,
        Skill.dragging => l10n.skillDragging,
        Skill.swiping => l10n.skillSwiping,
        Skill.matching => l10n.skillMatching,
        Skill.colors => l10n.skillColors,
        Skill.shapes => l10n.skillShapes,
        Skill.counting => l10n.skillCounting,
        Skill.sequencing => l10n.skillSequencing,
        Skill.routines => l10n.skillRoutines,
        Skill.attention => l10n.skillAttention,
        Skill.animals => l10n.skillAnimals,
        Skill.spatial => l10n.skillSpatial,
        Skill.fineMotor => l10n.skillFineMotor,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = context.watch<ProgressController>().data;
    final profile = context.watch<ProfileController>().profile;

    final stageName = switch (profile.stage) {
      DevelopmentStage.explorer => l10n.stageExplorer,
      DevelopmentStage.helper => l10n.stageHelper,
      DevelopmentStage.littleThinker => l10n.stageLittleThinker,
    };
    final nickname = profile.nickname.isEmpty ? '—' : profile.nickname;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.progressIntro(nickname),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (progress.totalAttempts == 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.noPlayYet)),
            ),
          )
        else ...[
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(l10n.totalPlayTime),
                  trailing: Text(
                    l10n.playTimeValue(
                        (progress.totalPlayMs / 60000).round()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sports_esports_rounded),
                  title: Text(l10n.gamesAttempted),
                  trailing: Text('${progress.totalAttempts}'),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: Text(l10n.gamesCompleted),
                  trailing: Text('${progress.totalCompletions}'),
                ),
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline_rounded),
                  title: Text(l10n.hintsShown),
                  trailing: Text('${progress.totalHintsShown}'),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_graph_rounded),
                  title: Text(l10n.currentStageLabel),
                  trailing: Text(stageName),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.favoriteGames,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final id in progress.favourites.take(3))
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WorldIcon(gameId: id, size: 56),
                            Text(
                              GameRegistry.of(id).title(l10n),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Palette.textSoft),
                            ),
                          ],
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
                  Text(l10n.skillsPractised,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final skill in progress.practisedSkills)
                        Chip(label: Text(_skillName(l10n, skill))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

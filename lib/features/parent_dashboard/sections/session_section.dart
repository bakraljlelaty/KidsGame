import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../session_control/session_controller.dart';

/// Session length, daily limit, break duration and "allow one more session".
class SessionSection extends StatelessWidget {
  const SessionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<SessionController>();
    final config = session.config;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.sessionLength,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final minutes in const [5, 10, 15, 20])
                      ChoiceChip(
                        label: Text(l10n.sessionMinutesOption(minutes)),
                        selected: config.sessionMinutes == minutes,
                        onSelected: (_) => session.updateConfig(
                          config.copyWith(sessionMinutes: () => minutes),
                        ),
                      ),
                    ChoiceChip(
                      label: Text(l10n.sessionNoTimer),
                      selected: config.sessionMinutes == null,
                      onSelected: (_) => session.updateConfig(
                        config.copyWith(sessionMinutes: () => null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.dailyLimitTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final minutes in const [20, 30, 45, 60])
                      ChoiceChip(
                        label: Text(l10n.sessionMinutesOption(minutes)),
                        selected: config.dailyLimitMinutes == minutes,
                        onSelected: (_) => session.updateConfig(
                          config.copyWith(
                              dailyLimitMinutes: () => minutes),
                        ),
                      ),
                    ChoiceChip(
                      label: Text(l10n.dailyLimitNone),
                      selected: config.dailyLimitMinutes == null,
                      onSelected: (_) => session.updateConfig(
                        config.copyWith(dailyLimitMinutes: () => null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.breakTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final minutes in const [15, 30, 60, 120])
                      ChoiceChip(
                        label: Text(l10n.breakMinutesOption(minutes)),
                        selected: config.breakMinutes == minutes,
                        onSelected: (_) => session.updateConfig(
                          config.copyWith(breakMinutes: minutes),
                        ),
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
                Text(
                  l10n.sessionTodayPlayed(
                      session.playedToday.inMinutes),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(l10n.sessionEndBehaviourNote,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await session.parentAllowExtraSession();
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(l10n.sessionAllowExtraDone)),
                    );
                  },
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(l10n.sessionAllowExtra),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

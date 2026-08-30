import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/highscore/cubit/highscore_sync_cubit.dart';
import 'package:flutter_and_friends/highscore/widgets/highscore_name_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This device's own standing: how many people it has collected, where
/// that puts it on the board, and, while the badge has no name, the field
/// that gets it onto the board in the first place.
class MyScoreCard extends StatelessWidget {
  const MyScoreCard({
    required this.count,
    required this.rank,
    required this.hasName,
    required this.syncStatus,
    super.key,
  });

  final int count;

  /// This device's position on the board, or null while it is not on it.
  final int? rank;

  /// Whether the badge carries a name, which the highscore needs.
  final bool hasName;

  final HighscoreSyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final people = count == 1 ? '1 person' : '$count people';
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have collected $people',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (hasName) ...[
              Text(
                _standing,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              if (syncStatus == HighscoreSyncStatus.failure) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your score could not be published. Check your '
                        'connection.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<HighscoreSyncCubit?>()?.sync(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ] else ...[
              Text(
                'The highscore shows the name on your badge. Add yours to '
                'get on the board.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              HighscoreNameField(
                onSubmit: context.read<BadgeIdentityCubit>().updateName,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _standing {
    if (rank case final rank?) return '#$rank on the highscore';
    if (count == 0) return 'Tap a badge to get on the board';
    return switch (syncStatus) {
      HighscoreSyncStatus.idle ||
      HighscoreSyncStatus.syncing => 'Publishing your score...',
      HighscoreSyncStatus.synced => 'Your score is on its way to the board',
      HighscoreSyncStatus.failure => 'Not on the board yet',
    };
  }
}

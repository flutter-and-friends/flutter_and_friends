import 'package:flutter/material.dart';
import 'package:flutter_and_friends/highscore/models/models.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart' show RankMedal;

/// One person on the highscore, styled like the pub quiz scoreboard rows.
class HighscoreRow extends StatelessWidget {
  const HighscoreRow({required this.entry, required this.rank, super.key});

  final HighscoreEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = entry.isMine
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: entry.isMine
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            RankMedal(rank: rank),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: entry.isMine ? FontWeight.w700 : null,
                  color: foreground,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.count}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/cubit/pub_quiz_cubit.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/animated_scoreboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The final standings once the last question has been played: a podium
/// for the top three and the full board below it.
class FinishedView extends StatelessWidget {
  const FinishedView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<PubQuizCubit>().state;
    final ranked = rankScoreboard(state.scoreboard, (entry) => entry.to);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Final results',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (ranked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Podium(entries: ranked.take(3).toList()),
          ),
        Expanded(
          child: AnimatedScoreboard(entries: state.scoreboard, animate: false),
        ),
      ],
    );
  }
}

/// The top three, tallest in the middle, each rising into place.
class Podium extends StatelessWidget {
  const Podium({required this.entries, super.key});

  /// Best first, at most three.
  final List<ScoreboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    ScoreboardEntry? at(int index) =>
        index < entries.length ? entries[index] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumStep(entry: at(1), rank: 2, height: 100)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(entry: at(0), rank: 1, height: 140)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(entry: at(2), rank: 3, height: 80)),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.height,
  });

  final ScoreboardEntry? entry;
  final int rank;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = this.entry;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + rank * 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: value, child: child),
          const SizedBox(height: 6),
          SizedBox(
            height: height,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height * value,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                child: RankMedal(rank: rank),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            entry?.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: entry?.isMine ?? false ? FontWeight.w800 : null,
            ),
          ),
          Text(
            entry == null ? '' : '${entry.to} pts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

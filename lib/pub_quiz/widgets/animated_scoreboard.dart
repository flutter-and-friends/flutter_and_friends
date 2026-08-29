import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/award_badge.dart';

/// The standings, played as a short sequence when a question has just been
/// revealed: the award badges pop in on the teams that scored, the numbers
/// count up from the previous score, and then the rows slide into their new
/// order. With [animate] false the board is simply drawn in its final state.
///
/// Give it a key that changes per reveal (see `PubQuizState.revealKey`) so
/// the sequence starts over for each question and only for each question.
class AnimatedScoreboard extends StatefulWidget {
  const AnimatedScoreboard({
    required this.entries,
    this.animate = true,
    this.rowHeight = 64,
    super.key,
  });

  final List<ScoreboardEntry> entries;
  final bool animate;
  final double rowHeight;

  @override
  State<AnimatedScoreboard> createState() => _AnimatedScoreboardState();
}

class _AnimatedScoreboardState extends State<AnimatedScoreboard>
    with SingleTickerProviderStateMixin {
  static const _reorderAt = 0.65;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final Animation<double> _badge = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.25, curve: Curves.elasticOut),
  );
  late final Animation<double> _score = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, _reorderAt, curve: Curves.easeOutCubic),
  );
  bool _rankByNewScore = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller
        ..addListener(_maybeReorder)
        ..forward();
    } else {
      _controller.value = 1;
      _rankByNewScore = true;
    }
  }

  void _maybeReorder() {
    if (!_rankByNewScore && _controller.value >= _reorderAt) {
      setState(() => _rankByNewScore = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ranked = rankScoreboard(
      widget.entries,
      (entry) => _rankByNewScore ? entry.to : entry.from,
    );
    final rankOf = {
      for (var i = 0; i < ranked.length; i++) ranked[i].teamId: i,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: widget.entries.length * widget.rowHeight,
        child: Stack(
          children: [
            for (final entry in widget.entries)
              AnimatedPositioned(
                key: ValueKey(entry.teamId),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                top: rankOf[entry.teamId]! * widget.rowHeight,
                left: 0,
                right: 0,
                height: widget.rowHeight,
                child: ScoreRow(
                  entry: entry,
                  rank: rankOf[entry.teamId]! + 1,
                  scoreProgress: _score,
                  badgeProgress: _badge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One team on the board. The score follows [scoreProgress] from the old to
/// the new value and the award badge scales in with [badgeProgress].
class ScoreRow extends StatelessWidget {
  const ScoreRow({
    required this.entry,
    required this.rank,
    required this.scoreProgress,
    required this.badgeProgress,
    super.key,
  });

  final ScoreboardEntry entry;
  final int rank;
  final Animation<double> scoreProgress;
  final Animation<double> badgeProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final award = entry.award;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
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
                  color: entry.isMine
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (award != null && award.points > 0) ...[
              ScaleTransition(
                scale: badgeProgress,
                child: FadeTransition(
                  opacity: badgeProgress,
                  child: AwardBadge(award: award),
                ),
              ),
              const SizedBox(width: 12),
            ],
            AnimatedBuilder(
              animation: scoreProgress,
              builder: (context, _) {
                final value =
                    entry.from + (entry.to - entry.from) * scoreProgress.value;
                return Text(
                  '${value.round()}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: entry.isMine
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The rank number, in gold, silver or bronze for the top three.
class RankMedal extends StatelessWidget {
  const RankMedal({required this.rank, super.key});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (rank) {
      1 => const Color(0xFFFFC107),
      2 => const Color(0xFFB0BEC5),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: medal ?? theme.colorScheme.surface,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: medal != null ? Colors.black87 : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

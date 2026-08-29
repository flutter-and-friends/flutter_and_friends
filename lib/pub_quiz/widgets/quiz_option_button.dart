import 'package:flutter/material.dart';

/// One color per answer slot, kept the same on every phone and on the big
/// screen so "the blue one" means the same thing to everybody at the table.
const quizOptionColors = [
  Color(0xFFE21B3C),
  Color(0xFF1368CE),
  Color(0xFFD89E00),
  Color(0xFF26890C),
];

const quizOptionLetters = ['A', 'B', 'C', 'D'];

enum QuizOptionStyle {
  /// Pickable, or shown neutrally before the reveal.
  normal,

  /// The option this device picked, before the answer is known.
  selected,

  /// Revealed as the correct answer.
  correct,

  /// This device picked it and it was wrong.
  wrong,

  /// Neither picked nor correct, faded into the background.
  dimmed,
}

/// A big tappable answer, doubling as the revealed result once the answer is
/// known: [count] and [share] show how many teams picked it, as a number
/// with a percentage and as a bar under the label.
class QuizOptionButton extends StatelessWidget {
  const QuizOptionButton({
    required this.index,
    required this.label,
    this.style = QuizOptionStyle.normal,
    this.onPressed,
    this.count,
    this.share,
    super.key,
  });

  final int index;
  final String label;
  final QuizOptionStyle style;
  final VoidCallback? onPressed;

  /// How many teams picked this option, shown after the reveal.
  final int? count;

  /// [count] as a fraction of all answers, drawn as a bar under the label
  /// and written as a percentage. Drawn as given, so the caller decides how
  /// the bar grows in.
  final double? share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = quizOptionColors[index % quizOptionColors.length];
    final dimmed = style == QuizOptionStyle.dimmed;
    final background = switch (style) {
      QuizOptionStyle.normal || QuizOptionStyle.selected => color,
      QuizOptionStyle.correct => const Color(0xFF26890C),
      QuizOptionStyle.wrong => const Color(0xFFE21B3C),
      QuizOptionStyle.dimmed => color.withValues(alpha: 0.35),
    };
    final trailing = switch (style) {
      QuizOptionStyle.selected => Icons.check_circle,
      QuizOptionStyle.correct => Icons.check_circle,
      QuizOptionStyle.wrong => Icons.cancel,
      _ => null,
    };
    final foreground = Colors.white.withValues(alpha: dimmed ? 0.7 : 1);
    return Semantics(
      button: onPressed != null,
      selected: style == QuizOptionStyle.selected,
      label: '${quizOptionLetters[index]}: $label',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: style == QuizOptionStyle.selected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _Letter(letter: quizOptionLetters[index], dimmed: dimmed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (share case final share?) ...[
                          const SizedBox(height: 8),
                          _ShareBar(share: share, color: foreground),
                        ],
                      ],
                    ),
                  ),
                  if (count case final count?) ...[
                    const SizedBox(width: 12),
                    _VoteCount(count: count, share: share, color: foreground),
                  ],
                  if (trailing case final trailing?) ...[
                    const SizedBox(width: 8),
                    Icon(trailing, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slim track under the label, filled from the left by [share].
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share, required this.color});

  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: color.withValues(alpha: 0.3)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: share.clamp(0, 1),
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How many teams picked the option, with the percentage underneath.
class _VoteCount extends StatelessWidget {
  const _VoteCount({
    required this.count,
    required this.share,
    required this.color,
  });

  final int count;
  final double? share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (share case final share?)
          Text(
            '${(share * 100).round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.letter, required this.dimmed});

  final String letter;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dimmed ? 0.15 : 0.25),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

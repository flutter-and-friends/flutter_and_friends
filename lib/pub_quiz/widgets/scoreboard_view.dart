import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/cubit/pub_quiz_cubit.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/animated_scoreboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The standings a few seconds after each reveal.
class ScoreboardView extends StatelessWidget {
  const ScoreboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<PubQuizCubit>().state;
    final quiz = state.quiz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scoreboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (quiz != null)
                Text(
                  'After question ${quiz.questionIndex + 1} of '
                  '${quiz.questionCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedScoreboard(
            key: ValueKey(state.revealKey),
            entries: state.scoreboard,
          ),
        ),
      ],
    );
  }
}

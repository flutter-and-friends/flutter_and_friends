import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/cubit/pub_quiz_cubit.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/award_badge.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/question_view.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/vote_statistics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The moment after a question closes: how many teams chose each option
/// grows in bar by bar, then the correct answer lights up, this device's
/// pick is marked right or wrong, and the team learns what it just earned.
class RevealView extends StatelessWidget {
  const RevealView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PubQuizCubit>().state;
    final quiz = state.quiz;
    final question = quiz?.question;
    if (quiz == null || question == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final myChoice = state.myAward?.choice ?? state.myAnswer?.choice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionHeader(quiz: quiz),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: VoteStatistics(
              key: ValueKey(state.revealKey),
              question: question,
              myChoice: myChoice,
              result: _MyResult(award: state.myAward),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyResult extends StatelessWidget {
  const _MyResult({required this.award});

  final PubQuizAward? award;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final award = this.award;
    final (String title, String subtitle) = switch (award) {
      null => ('Scores coming up…', 'Sit tight, the standings are next.'),
      PubQuizAward(correct: true, fastRank: final rank?) => (
        'Correct, and fast!',
        'Number $rank to get it right earns a bonus point.',
      ),
      PubQuizAward(correct: true) => ('Correct!', 'Two points in the bag.'),
      PubQuizAward(answered: false) => (
        'No answer',
        'Nothing this round, but the next one is coming.',
      ),
      _ => ('Not this time', 'Better luck on the next question.'),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (award != null && award.points > 0) ...[
            const SizedBox(width: 12),
            AwardBadge(award: award, large: true),
          ],
        ],
      ),
    );
  }
}

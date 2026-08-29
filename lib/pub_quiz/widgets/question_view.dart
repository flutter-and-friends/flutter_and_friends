import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_and_friends/pub_quiz/cubit/pub_quiz_cubit.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';
import 'package:flutter_and_friends/pub_quiz/widgets/quiz_option_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The open question: the text, the four answers to pick from, and once
/// this device has answered, how many teams are still to go.
class QuestionView extends StatelessWidget {
  const QuestionView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PubQuizCubit>().state;
    final quiz = state.quiz;
    final question = quiz?.question;
    if (quiz == null || question == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final myChoice = state.myAnswer?.choice;
    final canAnswer =
        quiz.phase == PubQuizPhase.answering &&
        myChoice == null &&
        state.submission != PubQuizSubmission.submitting &&
        state.submission != PubQuizSubmission.tooLate;
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
            child: Column(
              children: [
                for (var i = 0; i < question.options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Expanded(
                    child: QuizOptionButton(
                      index: i,
                      label: question.options[i],
                      style: myChoice == i
                          ? QuizOptionStyle.selected
                          : QuizOptionStyle.normal,
                      onPressed: canAnswer
                          ? () {
                              HapticFeedback.mediumImpact();
                              context.read<PubQuizCubit>().answer(i);
                            }
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AnswerStatus(quiz: quiz, state: state),
        ],
      ),
    );
  }
}

/// "Question 3 of 10" for the current question.
class QuestionHeader extends StatelessWidget {
  const QuestionHeader({required this.quiz, super.key});

  final PubQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Question ${quiz.questionIndex + 1} of ${quiz.questionCount}',
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _AnswerStatus extends StatelessWidget {
  const _AnswerStatus({required this.quiz, required this.state});

  final PubQuiz quiz;
  final PubQuizState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = state.myAnswer != null;
    final (
      IconData icon,
      String title,
      String? subtitle,
    ) = switch (state.submission) {
      PubQuizSubmission.tooLate => (
        Icons.timer_off_outlined,
        'Too late',
        'The question closed before your answer arrived.',
      ),
      PubQuizSubmission.failure => (
        Icons.error_outline,
        'Could not send your answer',
        'Check your connection and try again.',
      ),
      _ when quiz.phase == PubQuizPhase.closed => (
        Icons.hourglass_top,
        'Answers are in',
        'Revealing the answer…',
      ),
      _ when answered => (
        Icons.lock_outline,
        'Answer locked in',
        'Waiting for the other teams…',
      ),
      PubQuizSubmission.submitting => (Icons.send, 'Sending…', null),
      _ => (Icons.touch_app_outlined, 'Pick an answer', null),
    };
    final showProgress = answered || quiz.phase == PubQuizPhase.closed;
    final progress = quiz.teamCount == 0
        ? 0.0
        : quiz.answeredCount / quiz.teamCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (showProgress) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, _) =>
                  LinearProgressIndicator(value: value, minHeight: 8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${quiz.answeredCount} of ${quiz.teamCount} teams answered',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

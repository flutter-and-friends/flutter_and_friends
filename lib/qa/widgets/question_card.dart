import 'package:flutter/material.dart';
import 'package:flutter_and_friends/qa/qa.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({required this.question, super.key});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.body, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${question.authorName ?? 'Anonymous'} · '
                          '${_relativeTime(question.createdAt)}',
                          style: metaStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (question.isMine)
                        _DeleteQuestionButton(question: question),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            UpvoteButton(question: question),
          ],
        ),
      ),
    );
  }
}

class _DeleteQuestionButton extends StatelessWidget {
  const _DeleteQuestionButton({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: 'Delete your question',
      icon: Icon(
        Icons.delete_outline,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: () async {
        final cubit = context.read<QaCubit>();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete your question?'),
            content: const Text(
              'It will be removed for everyone, along with its upvotes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed ?? false) await cubit.deleteQuestion(question);
      },
    );
  }
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time.toLocal());
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return DateFormat.MMMd().format(time.toLocal());
}

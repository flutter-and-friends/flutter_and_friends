import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_and_friends/qa/qa.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpvoteButton extends StatelessWidget {
  const UpvoteButton({required this.question, super.key});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = question.hasVoted
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      toggled: question.hasVoted,
      label: '${question.voteCount} upvotes',
      child: Material(
        color: question.hasVoted
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () {
            unawaited(context.read<QaCubit>().toggleVote(question));
            unawaited(HapticFeedback.mediumImpact());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, size: 20, color: foreground),
                Text(
                  '${question.voteCount}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

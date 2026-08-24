import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/qa/qa.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom sheet for submitting a new question. Opened with [show], which
/// hands the page's [QaCubit] to the sheet since modal routes live outside
/// the page's widget subtree.
class AskQuestionSheet extends StatefulWidget {
  const AskQuestionSheet({super.key});

  static const maxQuestionLength = 500;
  static const maxNameLength = 60;

  static Future<void> show(BuildContext context) {
    final cubit = context.read<QaCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const AskQuestionSheet(),
      ),
    );
  }

  @override
  State<AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<AskQuestionSheet> {
  final _questionController = TextEditingController();
  late final _nameController = TextEditingController(
    text: context.read<QaCubit>().state.lastAuthorName,
  );

  @override
  void initState() {
    super.initState();
    _questionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _questionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    unawaited(
      context.read<QaCubit>().ask(
        body: _questionController.text,
        authorName: _nameController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submissionStatus = context.select(
      (QaCubit cubit) => cubit.state.submissionStatus,
    );
    final isSubmitting = submissionStatus == QaSubmissionStatus.submitting;
    final canSubmit =
        !isSubmitting && _questionController.text.trim().isNotEmpty;
    return BlocListener<QaCubit, QaState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus &&
          current.submissionStatus == QaSubmissionStatus.success,
      listener: (context, state) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Your question has been submitted')),
          );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask a question', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              autofocus: true,
              enabled: !isSubmitting,
              minLines: 2,
              maxLines: 5,
              maxLength: AskQuestionSheet.maxQuestionLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Your question',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: !isSubmitting,
              maxLength: AskQuestionSheet.maxNameLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => canSubmit ? _submit() : null,
              decoration: const InputDecoration(
                labelText: 'Your name (optional)',
                helperText: 'Leave empty to ask anonymously',
                border: OutlineInputBorder(),
              ),
            ),
            if (submissionStatus == QaSubmissionStatus.failure) ...[
              const SizedBox(height: 8),
              Text(
                'Could not submit your question, please try again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canSubmit ? _submit : null,
              icon: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Submit question'),
            ),
          ],
        ),
      ),
    );
  }
}

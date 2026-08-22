import 'package:flutter/material.dart';
import 'package:flutter_and_friends/config/config.dart';
import 'package:flutter_and_friends/qa/qa.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QaPage extends StatelessWidget {
  const QaPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const QaPage());
  }

  @override
  Widget build(BuildContext context) {
    if (!isQaConfigured) {
      return Scaffold(appBar: FFAppBar(), body: const QaUnavailableView());
    }
    return BlocProvider(
      create: (context) => QaCubit(
        repository: context.read<QaRepository>(),
        session: flutterCoreTeamQaSession,
      )..init(),
      child: const QaView(),
    );
  }
}

class QaView extends StatelessWidget {
  const QaView({super.key});

  @override
  Widget build(BuildContext context) {
    final hasQuestions = context.select(
      (QaCubit cubit) => cubit.state.questions.isNotEmpty,
    );
    final status = context.select((QaCubit cubit) => cubit.state.status);
    final canAsk = hasQuestions || status == QaStatus.loaded;
    return BlocListener<QaCubit, QaState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage &&
          current.questions.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Something went wrong, please try again.'),
            ),
          );
      },
      child: Scaffold(
        appBar: FFAppBar(),
        floatingActionButton: canAsk
            ? FloatingActionButton.extended(
                onPressed: () => AskQuestionSheet.show(context),
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Ask a question'),
              )
            : null,
        body: const _QaBody(),
      ),
    );
  }
}

class _QaBody extends StatelessWidget {
  const _QaBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QaCubit>().state;
    final session = context.read<QaCubit>().session;

    if (state.questions.isEmpty) {
      switch (state.status) {
        case QaStatus.initial:
        case QaStatus.loading:
          return const Center(child: CircularProgressIndicator());
        case QaStatus.error:
          return QaErrorView(
            message: state.errorMessage,
            onRetry: () => context.read<QaCubit>().init(),
          );
        case QaStatus.loaded:
          break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        QaSessionHeader(session: session),
        const SizedBox(height: 16),
        if (state.questions.isEmpty)
          const _NoQuestionsYet()
        else
          for (final question in state.questions)
            QuestionCard(question: question),
      ],
    );
  }
}

class _NoQuestionsYet extends StatelessWidget {
  const _NoQuestionsYet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to ask the panel something!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class QaErrorView extends StatelessWidget {
  const QaErrorView({required this.onRetry, this.message, super.key});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load the questions',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (message case final message?) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in builds that cannot reach a Firebase project (see
/// `isQaConfigured`), so the tab still explains itself instead of failing.
class QaUnavailableView extends StatelessWidget {
  const QaUnavailableView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Q&A is not available in this build',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

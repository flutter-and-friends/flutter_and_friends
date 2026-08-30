import 'package:flutter/material.dart';
import 'package:flutter_and_friends/config/config.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PubQuizPage extends StatelessWidget {
  const PubQuizPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const PubQuizPage());
  }

  @override
  Widget build(BuildContext context) {
    if (!isPubQuizConfigured) {
      return Scaffold(
        appBar: FFAppBar(),
        body: const PubQuizMessageView(
          icon: Icons.quiz_outlined,
          title: 'The pub quiz is not available in this build',
        ),
      );
    }
    return BlocProvider(
      create: (context) =>
          PubQuizCubit(repository: context.read<PubQuizRepository>())..init(),
      child: const PubQuizView(),
    );
  }
}

class PubQuizView extends StatelessWidget {
  const PubQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PubQuizCubit, PubQuizState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage &&
          current.status == PubQuizStatus.loaded,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Something went wrong, please try again.'),
            ),
          );
      },
      child: Scaffold(appBar: FFAppBar(), body: const _PubQuizBody()),
    );
  }
}

class _PubQuizBody extends StatelessWidget {
  const _PubQuizBody();

  @override
  Widget build(BuildContext context) {
    final status = context.select((PubQuizCubit cubit) => cubit.state.status);
    final screen = context.select(
      (PubQuizCubit cubit) => cubit.state.screen,
    );
    final child = switch (status) {
      PubQuizStatus.initial || PubQuizStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      PubQuizStatus.error => PubQuizMessageView(
        icon: Icons.cloud_off,
        title: 'Could not load the quiz',
        subtitle: 'Check your connection and try again.',
        action: FilledButton.icon(
          onPressed: () => context.read<PubQuizCubit>().init(),
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ),
      PubQuizStatus.loaded => switch (screen) {
        PubQuizScreen.notReady => const PubQuizMessageView(
          icon: Icons.quiz_outlined,
          title: 'The pub quiz has not opened yet',
          subtitle: 'Come back when the host is ready to start.',
        ),
        PubQuizScreen.setup => const TeamSetupView(),
        PubQuizScreen.lobby => const LobbyView(),
        PubQuizScreen.question => const QuestionView(),
        PubQuizScreen.reveal => const RevealView(),
        PubQuizScreen.scoreboard => const ScoreboardView(),
        PubQuizScreen.finished => const FinishedView(),
      },
    };
    final connection = context.select(
      (PubQuizCubit cubit) => cubit.state.connection,
    );
    return Column(
      children: [
        if (status == PubQuizStatus.loaded)
          ConnectionBanner(connection: connection),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(key: ValueKey((status, screen)), child: child),
          ),
        ),
      ],
    );
  }
}

/// A centered icon, title and optional subtitle and action, for every state
/// that has nothing else to show (unavailable, not open yet, failed).
class PubQuizMessageView extends StatelessWidget {
  const PubQuizMessageView({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle case final subtitle?) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action case final action?) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

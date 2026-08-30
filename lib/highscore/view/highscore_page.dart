import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/config/config.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/highscore/cubit/highscore_cubit.dart';
import 'package:flutter_and_friends/highscore/cubit/highscore_sync_cubit.dart';
import 'package:flutter_and_friends/highscore/repository/highscore_repository.dart';
import 'package:flutter_and_friends/highscore/widgets/widgets.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart'
    show PubQuizMessageView;
import 'package:flutter_bloc/flutter_bloc.dart';

class HighscorePage extends StatelessWidget {
  const HighscorePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const HighscorePage());
  }

  @override
  Widget build(BuildContext context) {
    if (!isHighscoreConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Highscore')),
        body: const PubQuizMessageView(
          icon: Icons.emoji_events_outlined,
          title: 'The highscore is not available in this build',
        ),
      );
    }
    return BlocProvider(
      create: (context) =>
          HighscoreCubit(repository: context.read<HighscoreRepository>())
            ..init(),
      child: const HighscoreView(),
    );
  }
}

class HighscoreView extends StatefulWidget {
  const HighscoreView({super.key});

  @override
  State<HighscoreView> createState() => _HighscoreViewState();
}

class _HighscoreViewState extends State<HighscoreView> {
  @override
  void initState() {
    super.initState();
    // Opening the board is the natural moment to get this device's own
    // entry onto it, in case an earlier publish failed while offline.
    unawaited(context.read<HighscoreSyncCubit?>()?.sync());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Highscore')),
      body: const _HighscoreBody(),
    );
  }
}

class _HighscoreBody extends StatelessWidget {
  const _HighscoreBody();

  @override
  Widget build(BuildContext context) {
    final status = context.select(
      (HighscoreCubit cubit) => cubit.state.status,
    );
    return switch (status) {
      HighscoreStatus.initial || HighscoreStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      HighscoreStatus.error => PubQuizMessageView(
        icon: Icons.cloud_off,
        title: 'Could not load the highscore',
        subtitle: 'Check your connection and try again.',
        action: FilledButton.icon(
          onPressed: () => context.read<HighscoreCubit>().init(),
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ),
      HighscoreStatus.loaded => const HighscoreBoard(),
    };
  }
}

/// This device's own score on top and everybody's entries below it.
class HighscoreBoard extends StatelessWidget {
  const HighscoreBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<HighscoreCubit>().state;
    final count = context.select(
      (CollectedPeopleCubit cubit) => cubit.state.people.length,
    );
    final name = context.select(
      (BadgeIdentityCubit cubit) => cubit.state.name.trim(),
    );
    final syncStatus =
        context.watch<HighscoreSyncCubit?>()?.state.status ??
        HighscoreSyncStatus.idle;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MyScoreCard(
          count: count,
          rank: state.myRank,
          hasName: name.isNotEmpty,
          syncStatus: syncStatus,
        ),
        const SizedBox(height: 24),
        Text(
          'Most people collected',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (state.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nobody has collected anyone yet. Tap a badge to be the first!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var i = 0; i < state.entries.length; i++)
            HighscoreRow(entry: state.entries[i], rank: i + 1),
      ],
    );
  }
}

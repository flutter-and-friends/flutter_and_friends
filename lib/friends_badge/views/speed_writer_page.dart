import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Organizer-only mode for flashing every badge before the conference from
/// a CSV roster. Reached by holding the Friends Badge entry on the More
/// page for five seconds.
class SpeedWriterPage extends StatefulWidget {
  const SpeedWriterPage({super.key});

  static Route<void> route() => MaterialPageRoute(
    builder: (_) => const SpeedWriterPage(),
  );

  @override
  State<SpeedWriterPage> createState() => _SpeedWriterPageState();
}

class _SpeedWriterPageState extends State<SpeedWriterPage> {
  BadgeListenerCubit? _listener;

  /// The app-wide listener would collect every badge that lies on the phone
  /// after a write, filling the organizer's collected people (and the
  /// highscore) with the whole roster, so it stays off while writing.
  @override
  void initState() {
    super.initState();
    _listener = context.read<BadgeListenerCubit?>();
    unawaited(_listener?.stop());
  }

  @override
  void dispose() {
    unawaited(_listener?.rearm());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SpeedWriterCubit(),
    child: const SpeedWriterView(),
  );
}

class SpeedWriterView extends StatelessWidget {
  const SpeedWriterView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SpeedWriterCubit>();
    final state = cubit.state;
    final badge = state.badge;
    final entry = state.current;
    return BlocListener<SpeedWriterCubit, SpeedWriterState>(
      listenWhen: (previous, current) =>
          previous.errorCount != current.errorCount,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error ?? 'Something went wrong')),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Speed Writer'),
          actions: [
            if (state.entries.isNotEmpty) const PickRosterButton(compact: true),
          ],
        ),
        floatingActionButton:
            badge != null &&
                entry != null &&
                state.status == SpeedWriterStatus.ready
            ? WriteToBadgeButton(
                badge,
                ndef: buildPreparedBadgeNdefMessage(
                  name: entry.name,
                  role: entry.role,
                  badgeId: state.badgeId ?? '',
                  link: entry.email,
                  capybaraId: state.capybaraId,
                ),
                onWritten: cubit.markWritten,
                rearmsListener: false,
              )
            : null,
        bottomNavigationBar:
            state.status == SpeedWriterStatus.composing ||
                state.status == SpeedWriterStatus.ready
            ? _PersonNavigation(state: state)
            : null,
        body: switch (state.status) {
          SpeedWriterStatus.empty => const _RosterPicker(),
          SpeedWriterStatus.done => _Finished(state: state),
          SpeedWriterStatus.composing ||
          SpeedWriterStatus.ready => _PersonWriter(state: state),
        },
      ),
    );
  }
}

class _RosterPicker extends StatelessWidget {
  const _RosterPicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Icon(Icons.bolt, size: 64, color: theme.colorScheme.primary),
          Text(
            'Write badges from a CSV',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            'Pick a CSV with the columns name, role and email. Every person '
            'gets a random font and capybara, and after a badge is written '
            'the next person comes up.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const PickRosterButton(),
        ],
      ),
    );
  }
}

class _PersonWriter extends StatelessWidget {
  const _PersonWriter({required this.state});

  final SpeedWriterState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = state.current;
    final badge = state.badge;
    if (entry == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 8,
        children: [
          LinearProgressIndicator(
            value: state.writtenIndices.length / state.entries.length,
          ),
          Text(
            '${state.index + 1} of ${state.entries.length} · '
            '${state.writtenIndices.length} written',
            style: theme.textTheme.labelMedium,
          ),
          Text(
            entry.name,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (entry.role.isNotEmpty)
            Text(entry.role, style: theme.textTheme.titleMedium),
          if (entry.email.isNotEmpty)
            Text(entry.email, style: theme.textTheme.bodySmall),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(state.font.label)),
              if (state.capybaraId case final capybaraId?)
                Chip(label: Text(capybaraId)),
              if (state.isCurrentWritten)
                const Chip(
                  avatar: Icon(Icons.check),
                  label: Text('Written'),
                ),
            ],
          ),
          Expanded(
            child: Center(
              child: badge == null
                  ? const CircularProgressIndicator()
                  : Image.memory(badge.previewPng, gaplessPlayback: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonNavigation extends StatelessWidget {
  const _PersonNavigation({required this.state});

  final SpeedWriterState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpeedWriterCubit>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: state.hasPrevious ? cubit.previous : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            IconButton.outlined(
              tooltip: 'New random look',
              onPressed: cubit.reroll,
              icon: const Icon(Icons.shuffle),
            ),
            OutlinedButton.icon(
              onPressed: state.hasNext ? cubit.next : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.state});

  final SpeedWriterState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          Text(
            '${state.writtenIndices.length} of ${state.entries.length} '
            'badges written',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          OutlinedButton.icon(
            onPressed: context.read<SpeedWriterCubit>().reroll,
            icon: const Icon(Icons.replay),
            label: const Text('Write the last one again'),
          ),
          const PickRosterButton(),
        ],
      ),
    );
  }
}

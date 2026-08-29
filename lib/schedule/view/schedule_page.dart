import 'package:flutter/material.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduleCubit(),
      child: const ScheduleView(),
    );
  }
}

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final dataState = context.watch<ScheduleDataCubit>().state;
    final days = dataState.schedule.days;

    if (dataState.status == ScheduleDataStatus.initial && days.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (days.isEmpty) {
      return Scaffold(
        appBar: FFAppBar(),
        body: _ScheduleError(
          message: dataState.errorMessage,
          onRetry: () => context.read<ScheduleDataCubit>().fetchSchedule(),
        ),
      );
    }

    final tabIndex = context.watch<ScheduleCubit>().state.clamp(
      0,
      days.length - 1,
    );

    return DefaultTabController(
      initialIndex: tabIndex,
      length: days.length,
      child: Scaffold(
        appBar: FFAppBar(
          bottom: TabBar(
            isScrollable: days.length > 3,
            onTap: (index) => context.read<ScheduleCubit>().toggleTab(index),
            tabs: [
              for (final day in days)
                Tab(child: Text(DateFormat.MMMEd().format(day.date))),
            ],
          ),
        ),
        body: Column(
          children: [
            if (dataState.isStale)
              _StaleBanner(generatedAt: dataState.generatedAt),
            Expanded(
              child: TabBarView(
                children: [
                  for (final day in days) ScheduleListView(events: day.events),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.generatedAt});

  final DateTime? generatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generatedAt = this.generatedAt;
    final message = generatedAt == null
        ? "Couldn't refresh the schedule. Showing the last saved version."
        : "Couldn't refresh the schedule. Showing schedule from "
              '${DateFormat.MMMd().format(generatedAt)}.';
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              size: 16,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleError extends StatelessWidget {
  const _ScheduleError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 16),
            const Text("Couldn't load the schedule."),
            const SizedBox(height: 8),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class ScheduleListView extends StatelessWidget {
  const ScheduleListView({required this.events, super.key});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) =>
          EventCard(event: events[index], showDate: false),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpeakersPage extends StatelessWidget {
  const SpeakersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FFAppBar(),
      body: const SpeakersView(),
    );
  }
}

/// Speakers are remote data, on the same footing as sessions (last-minute
/// speaker changes happen) - sourced from [ScheduleDataCubit] rather than a
/// build-time list, and fetched/cached/replaced atomically alongside the
/// schedule (see [ScheduleDataState.speakers]).
class SpeakersView extends StatelessWidget {
  const SpeakersView({super.key});

  @override
  Widget build(BuildContext context) {
    final speakers = context.select(
      (ScheduleDataCubit cubit) => cubit.state.speakers,
    );
    final sorted = [...speakers]..sort((a, b) => a.name.compareTo(b.name));
    return SpeakersGridView(speakers: sorted);
  }
}

class SpeakersGridView extends StatelessWidget {
  const SpeakersGridView({required this.speakers, super.key});

  final List<Speaker> speakers;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.crossAxisCount,
        mainAxisSpacing: 12,
      ),
      padding: const EdgeInsets.all(12),
      itemCount: speakers.length,
      itemBuilder: (context, index) => SpeakerAvatar(speaker: speakers[index]),
    );
  }
}

extension on BuildContext {
  int get crossAxisCount {
    final width = MediaQuery.of(this).size.width;
    if (width < 600) return 2;
    if (width < 800) return 3;
    return 4;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_and_friends/favorites/favorites.dart';
import 'package:flutter_and_friends/launchpad/launchpad.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:flutter_and_friends/sponsors/sponsors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LaunchpadPage extends StatelessWidget {
  const LaunchpadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LaunchpadCubit(),
      child: const LaunchpadView(),
    );
  }
}

class LaunchpadView extends StatelessWidget {
  const LaunchpadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, shadowColor: Colors.transparent),
      body: const _LaunchpadBody(),
      bottomNavigationBar: const _BottomNavigationBar(),
    );
  }
}

class _LaunchpadBody extends StatelessWidget {
  const _LaunchpadBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LaunchpadCubit>().state;
    switch (state) {
      case LaunchpadState.favorites:
        return const FavoritesPage();
      case LaunchpadState.schedule:
        return const SchedulePage();
      case LaunchpadState.speakers:
        return const SpeakersPage();
      case LaunchpadState.sponsors:
        return const SponsorsPage();
    }
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LaunchpadCubit>().state;
    return BottomNavigationBar(
      useLegacyColorScheme: false,
      onTap: (index) {
        context.read<LaunchpadCubit>().toggleTab(index);
        unawaited(HapticFeedback.mediumImpact());
      },
      currentIndex: state.index,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_rounded),
          label: 'Speakers',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Sponsors'),
      ],
    );
  }
}

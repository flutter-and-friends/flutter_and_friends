import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_and_friends/collected_people/cubit/collected_people_cubit.dart';
import 'package:flutter_and_friends/collected_people/models/models.dart';
import 'package:flutter_and_friends/collected_people/services/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:friends_badge/friends_badge.dart';

part 'badge_listener_state.dart';

/// Collects badges tapped anywhere in the app while it is in the foreground.
///
/// Android only (see [enabled]): holds a continuous
/// [BadgeCollector] session for as long as the app is resumed, so a tap
/// lands in the dex from any page, and a badge that is still on the phone
/// after a write or a collect is never handed to the system's own NFC
/// handler ("New tag collected"). iOS shows a modal system sheet for every
/// session, so it keeps the explicit collect button instead.
///
/// The badge write flow runs its own NFC session, which silently replaces
/// this one, so callers that finish a write must [rearm] the listener.
class BadgeListenerCubit extends Cubit<BadgeListenerState>
    with WidgetsBindingObserver {
  BadgeListenerCubit({
    required CollectedPeopleCubit people,
    BadgeCollector collector = const BadgeCollector(),
    String? Function()? ownInstallId,
    bool? enabled,
  }) : this._(
         people: people,
         collector: collector,
         ownInstallId: ownInstallId,
         enabled: enabled ?? Platform.isAndroid,
       );

  BadgeListenerCubit._({
    required this._people,
    required this._collector,
    required this._ownInstallId,
    required this.enabled,
  }) : super(const BadgeListenerState()) {
    if (enabled) WidgetsBinding.instance.addObserver(this);
  }

  final CollectedPeopleCubit _people;
  final BadgeCollector _collector;

  /// This installation's own badge ID, so tapping one's own badge (for
  /// example while it still lies on the phone after a write) is not
  /// collected.
  final String? Function()? _ownInstallId;

  /// Whether this listener does anything on the current platform.
  final bool enabled;

  BadgeCollectSession? _session;
  int _sequence = 0;

  /// Starts (or restarts) the continuous session.
  Future<void> start() async {
    if (!enabled || isClosed) return;
    await _dropSession();
    try {
      final session = await _collector.start(
        onCollected: _onCollected,
        continuous: true,
      );
      if (isClosed) {
        await session.cancel();
        return;
      }
      _session = session;
      emit(state.copyWith(listening: true));
      unawaited(
        session.result.then((_) {
          if (!isClosed && identical(_session, session)) {
            _session = null;
            emit(state.copyWith(listening: false));
          }
        }),
      );
    } on Exception catch (e) {
      debugPrint('Badge listener could not start: $e');
      emit(state.copyWith(listening: false));
      // NFC unavailable surfaces as a StateError from BadgeCollector.
      // ignore: avoid_catching_errors
    } on StateError catch (e) {
      debugPrint('Badge listener could not start: ${e.message}');
      emit(state.copyWith(listening: false));
    }
  }

  /// Stops listening until the next [start] or [rearm].
  Future<void> stop() async {
    await _dropSession();
    if (!isClosed) emit(state.copyWith(listening: false));
  }

  /// Restarts the session after another NFC session (the badge write flow)
  /// replaced it.
  Future<void> rearm() => start();

  Future<void> _dropSession() async {
    final session = _session;
    _session = null;
    await session?.cancel();
  }

  void _onCollected(BadgePerson badgePerson, String? badgeId) {
    final tapped = toCollectedPerson(badgePerson, badgeId: badgeId);
    if (isOwnBadge(badgePerson, ownInstallId: _ownInstallId?.call())) {
      emit(
        state.copyWith(
          lastCollected: BadgeCollected(
            person: tapped,
            isNew: false,
            isOwn: true,
            sequence: ++_sequence,
          ),
        ),
      );
      return;
    }
    final before = _people.state.people.length;
    final person = _people.collect(tapped);
    emit(
      state.copyWith(
        lastCollected: BadgeCollected(
          person: person,
          isNew: _people.state.people.length > before,
          isOwn: false,
          sequence: ++_sequence,
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(start());
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(stop());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Future<void> close() async {
    if (enabled) WidgetsBinding.instance.removeObserver(this);
    await _dropSession();
    await super.close();
  }
}

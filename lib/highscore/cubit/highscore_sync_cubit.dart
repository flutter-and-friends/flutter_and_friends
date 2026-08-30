import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/highscore/models/models.dart';
import 'package:flutter_and_friends/highscore/repository/highscore_repository.dart';

part 'highscore_sync_state.dart';

/// Keeps this device's highscore entry up to date for the whole life of the
/// app: whenever the number of collected people or the name on the badge
/// changes, the new submission is published a moment later.
///
/// Publishing needs a name, since that is what the highscore shows, so a
/// device whose badge has no name stays off the board (and is taken off it
/// again if the name is cleared). Failures are kept in the state rather
/// than surfaced; the highscore page retries with [sync] when opened.
class HighscoreSyncCubit extends Cubit<HighscoreSyncState> {
  HighscoreSyncCubit({
    required this._people,
    required this._identity,
    required this._repository,
    this._debounce = const Duration(seconds: 1),
  }) : super(const HighscoreSyncState());

  final CollectedPeopleCubit _people;
  final BadgeIdentityCubit _identity;
  final HighscoreRepository _repository;
  final Duration _debounce;

  StreamSubscription<CollectedPeopleState>? _peopleSubscription;
  StreamSubscription<BadgeIdentityState>? _identitySubscription;
  Timer? _timer;
  bool _syncing = false;
  bool _dirty = false;

  /// The submission the app would publish right now.
  HighscoreSubmission get current => HighscoreSubmission.from(
    badgeName: _identity.state.name,
    count: _people.state.people.length,
  );

  /// Publishes the current submission and starts following changes.
  Future<void> start() async {
    _peopleSubscription ??= _people.stream.listen((_) => _schedule());
    _identitySubscription ??= _identity.stream.listen((_) => _schedule());
    await sync();
  }

  /// Publishes the current submission now, unless it is already what the
  /// highscore holds. Safe to call at any time; a call during an ongoing
  /// publish runs again once it completes.
  Future<void> sync() async {
    _timer?.cancel();
    if (_syncing) {
      _dirty = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _dirty = false;
        await _publish(current);
      } while (_dirty && !isClosed);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _publish(HighscoreSubmission submission) async {
    final published = state.published;
    final removed = !submission.hasName && published == null;
    if (submission == published || removed) {
      if (state.status != HighscoreSyncStatus.synced) {
        emit(state.copyWith(status: HighscoreSyncStatus.synced));
      }
      return;
    }
    emit(state.copyWith(status: HighscoreSyncStatus.syncing));
    try {
      await _repository.signIn();
      if (submission.hasName) {
        await _repository.submit(submission);
      } else {
        await _repository.remove();
      }
      if (isClosed) return;
      emit(
        HighscoreSyncState(
          status: HighscoreSyncStatus.synced,
          published: submission.hasName ? submission : null,
        ),
      );
    } on Exception {
      if (isClosed) return;
      emit(state.copyWith(status: HighscoreSyncStatus.failure));
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(_debounce, sync);
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _peopleSubscription?.cancel();
    await _identitySubscription?.cancel();
    return super.close();
  }
}

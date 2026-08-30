import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/highscore/models/models.dart';
import 'package:flutter_and_friends/highscore/repository/highscore_repository.dart';

part 'highscore_state.dart';

/// Mirrors the highscore while its page is open. Not hydrated: Firestore
/// already caches the board and it is only ever shown live.
class HighscoreCubit extends Cubit<HighscoreState> {
  HighscoreCubit({required this._repository}) : super(const HighscoreState());

  final HighscoreRepository _repository;

  StreamSubscription<List<HighscoreEntry>>? _entries;

  /// Signs in and starts listening. Safe to call again to retry after a
  /// failure.
  Future<void> init() async {
    await _entries?.cancel();
    emit(state.copyWith(status: HighscoreStatus.loading));
    try {
      await _repository.signIn();
    } on Exception catch (error) {
      _fail(error);
      return;
    }
    _entries = _repository.watchHighscores().listen(
      (entries) => emit(
        state.copyWith(status: HighscoreStatus.loaded, entries: entries),
      ),
      onError: _fail,
    );
  }

  void _fail(Object error) {
    emit(
      state.copyWith(
        status: HighscoreStatus.error,
        errorMessage: error.toString(),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _entries?.cancel();
    return super.close();
  }
}

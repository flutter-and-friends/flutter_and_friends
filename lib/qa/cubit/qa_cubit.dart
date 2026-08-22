import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/qa/qa.dart';

part 'qa_state.dart';

/// Owns the questions for one [QaSession]: keeps them in sync with Firestore
/// through the repository's live stream and applies the user's own actions
/// (asking, voting, deleting). Firestore reflects this device's own writes
/// in the stream before the server confirms them, so the screen responds
/// instantly even on conference venue wifi.
///
/// Not hydrated: questions and votes are shared, live data that Firestore
/// already caches on disk for offline use; persisting them again here would
/// only add a second, staler copy.
class QaCubit extends Cubit<QaState> {
  QaCubit({required this._repository, required this.session})
    : super(const QaState());

  final QaRepository _repository;
  final QaSession session;

  StreamSubscription<List<Question>>? _questions;

  /// Signs in and starts listening to the questions. Safe to call again to
  /// retry after a failure.
  Future<void> init() async {
    await _questions?.cancel();
    emit(state.copyWith(status: QaStatus.loading));
    try {
      await _repository.signIn();
    } on Exception catch (error) {
      _fail(error);
      return;
    }
    _questions = _repository
        .watchQuestions(session.id)
        .listen(_onQuestions, onError: _fail);
  }

  Future<void> ask({required String body, String? authorName}) async {
    emit(state.copyWith(submissionStatus: QaSubmissionStatus.submitting));
    try {
      final trimmedName = authorName?.trim();
      await _repository.askQuestion(
        sessionId: session.id,
        body: body.trim(),
        authorName: (trimmedName == null || trimmedName.isEmpty)
            ? null
            : trimmedName,
      );
      emit(state.copyWith(submissionStatus: QaSubmissionStatus.success));
    } on Exception catch (error) {
      emit(
        state.copyWith(
          submissionStatus: QaSubmissionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> toggleVote(Question question) async {
    try {
      if (question.hasVoted) {
        await _repository.removeUpvote(
          sessionId: session.id,
          questionId: question.id,
        );
      } else {
        await _repository.upvote(
          sessionId: session.id,
          questionId: question.id,
        );
      }
    } on Exception catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> deleteQuestion(Question question) async {
    try {
      await _repository.deleteQuestion(
        sessionId: session.id,
        questionId: question.id,
      );
    } on Exception catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  void _onQuestions(List<Question> questions) {
    emit(
      state.copyWith(status: QaStatus.loaded, questions: _sorted(questions)),
    );
  }

  void _fail(Object error) {
    emit(
      state.copyWith(status: QaStatus.error, errorMessage: error.toString()),
    );
  }

  /// Most upvoted first; ties keep the order they were asked in.
  static List<Question> _sorted(List<Question> questions) {
    return [...questions]..sort((a, b) {
      final byVotes = b.voteCount.compareTo(a.voteCount);
      if (byVotes != 0) return byVotes;
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  @override
  Future<void> close() async {
    await _questions?.cancel();
    return super.close();
  }
}

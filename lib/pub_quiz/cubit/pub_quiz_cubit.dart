import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';
import 'package:flutter_and_friends/pub_quiz/repository/pub_quiz_repository.dart';

part 'pub_quiz_state.dart';

/// Keeps this device in sync with the live quiz: the quiz document (phase
/// and current question), the teams (names and scores) and this device's
/// own answer to the current question, plus the actions a player can take
/// (join, rename, answer).
///
/// Everything that needs a decision, from closing a question to handing out
/// points, happens on the server, so the state here is a plain mirror of
/// Firestore. Not hydrated for the same reason as the Q&A: Firestore already
/// caches it and a stale copy of a live game is worse than none.
class PubQuizCubit extends Cubit<PubQuizState> {
  PubQuizCubit({required this._repository}) : super(const PubQuizState());

  final PubQuizRepository _repository;

  StreamSubscription<PubQuiz?>? _quiz;
  StreamSubscription<bool>? _connection;
  StreamSubscription<List<PubQuizTeam>>? _teams;
  StreamSubscription<PubQuizAnswer?>? _myAnswer;
  String? _answerQuestionId;

  /// Signs in and starts listening. Safe to call again to retry after a
  /// failure.
  Future<void> init() async {
    await _cancelAll();
    emit(state.copyWith(status: PubQuizStatus.loading));
    try {
      await _repository.signIn();
    } on Exception catch (error) {
      _fail(error);
      return;
    }
    _quiz = _repository.watchQuiz().listen(_onQuiz, onError: _fail);
    _connection = _repository.watchConnected().listen(_onConnected);
    _teams = _repository.watchTeams().listen(_onTeams, onError: _fail);
  }

  Future<void> createTeam(String name) async {
    try {
      await _repository.createTeam(name.trim());
    } on Exception catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> renameTeam(String name) async {
    try {
      await _repository.renameTeam(name.trim());
    } on Exception catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> answer(int choice) async {
    final question = state.quiz?.question;
    if (question == null || state.myAnswer != null) return;
    if (state.submission == PubQuizSubmission.submitting) return;
    emit(state.copyWith(submission: PubQuizSubmission.submitting));
    try {
      await _repository.submitAnswer(questionId: question.id, choice: choice);
      emit(state.copyWith(submission: PubQuizSubmission.submitted));
    } on PubQuizAnswerRejected {
      emit(state.copyWith(submission: PubQuizSubmission.tooLate));
    } on Exception catch (error) {
      emit(
        state.copyWith(
          submission: PubQuizSubmission.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onQuiz(PubQuiz? quiz) {
    final questionId = quiz?.question?.id;
    final questionChanged = questionId != _answerQuestionId;
    emit(
      state.copyWith(
        status: PubQuizStatus.loaded,
        quiz: () => quiz,
        myAnswer: questionChanged ? () => null : null,
        submission: questionChanged ? PubQuizSubmission.idle : null,
      ),
    );
    if (questionChanged) _watchAnswer(questionId);
  }

  void _watchAnswer(String? questionId) {
    _answerQuestionId = questionId;
    unawaited(_myAnswer?.cancel());
    _myAnswer = null;
    if (questionId == null) return;
    _myAnswer = _repository
        .watchMyAnswer(questionId)
        .listen(
          (answer) => emit(state.copyWith(myAnswer: () => answer)),
          onError: _fail,
        );
  }

  void _onConnected(bool connected) {
    final connection = connected
        ? PubQuizConnection.connected
        : state.connection == PubQuizConnection.connecting
        ? PubQuizConnection.connecting
        : PubQuizConnection.reconnecting;
    emit(state.copyWith(connection: connection));
  }

  void _onTeams(List<PubQuizTeam> teams) {
    emit(state.copyWith(status: PubQuizStatus.loaded, teams: _sorted(teams)));
  }

  void _fail(Object error) {
    emit(
      state.copyWith(
        status: PubQuizStatus.error,
        errorMessage: error.toString(),
      ),
    );
  }

  static List<PubQuizTeam> _sorted(List<PubQuizTeam> teams) {
    return [...teams]..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  Future<void> _cancelAll() async {
    await _quiz?.cancel();
    await _connection?.cancel();
    await _teams?.cancel();
    await _myAnswer?.cancel();
    _answerQuestionId = null;
  }

  @override
  Future<void> close() async {
    await _cancelAll();
    return super.close();
  }
}

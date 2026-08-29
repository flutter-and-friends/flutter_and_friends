import 'dart:async';

import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for Firestore: the test pushes documents into the streams and
/// records what the cubit writes.
class _FakeRepository implements PubQuizRepository {
  final quiz = StreamController<PubQuiz?>.broadcast();
  final teams = StreamController<List<PubQuizTeam>>.broadcast();
  final answers = <String, StreamController<PubQuizAnswer?>>{};
  final submitted = <(String, int)>[];
  bool rejectAnswers = false;
  String? createdTeam;

  @override
  String get quizId => 'quiz';

  @override
  Future<void> signIn() async {}

  @override
  Stream<PubQuiz?> watchQuiz() => quiz.stream;

  @override
  Stream<List<PubQuizTeam>> watchTeams() => teams.stream;

  @override
  Stream<PubQuizAnswer?> watchMyAnswer(String questionId) {
    return answers
        .putIfAbsent(questionId, StreamController<PubQuizAnswer?>.broadcast)
        .stream;
  }

  @override
  Future<void> createTeam(String name) async => createdTeam = name;

  @override
  Future<void> renameTeam(String name) async => createdTeam = name;

  @override
  Future<void> submitAnswer({
    required String questionId,
    required int choice,
  }) async {
    if (rejectAnswers) throw const PubQuizAnswerRejected();
    submitted.add((questionId, choice));
  }
}

PubQuiz _quiz({
  PubQuizPhase phase = PubQuizPhase.lobby,
  String? questionId,
  int? correctIndex,
}) {
  return PubQuiz(
    id: 'quiz',
    phase: phase,
    questionIndex: questionId == null ? -1 : 0,
    questionCount: 2,
    answeredCount: 0,
    teamCount: 2,
    question: questionId == null
        ? null
        : PubQuizQuestion(
            id: questionId,
            index: 0,
            text: 'Question?',
            options: const ['a', 'b', 'c', 'd'],
            correctIndex: correctIndex,
          ),
  );
}

PubQuizTeam _team(
  String id, {
  int score = 0,
  bool isMine = false,
  PubQuizAward? lastAward,
}) {
  return PubQuizTeam(
    id: id,
    name: id,
    score: score,
    isMine: isMine,
    lastAward: lastAward,
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepository repository;
  late PubQuizCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    cubit = PubQuizCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('is not ready until the quiz document exists', () async {
    await cubit.init();
    repository.quiz.add(null);
    await _flush();

    expect(cubit.state.status, PubQuizStatus.loaded);
    expect(cubit.state.screen, PubQuizScreen.notReady);
  });

  test('asks for a team, then waits in the lobby', () async {
    await cubit.init();
    repository.quiz.add(_quiz());
    repository.teams.add([_team('other')]);
    await _flush();
    expect(cubit.state.screen, PubQuizScreen.setup);

    await cubit.createTeam('  The Dashers ');
    expect(repository.createdTeam, 'The Dashers');

    repository.teams.add([_team('other'), _team('me', isMine: true)]);
    await _flush();
    expect(cubit.state.screen, PubQuizScreen.lobby);
    expect(cubit.state.myTeam?.id, 'me');
  });

  test('follows the phases and resets the answer per question', () async {
    await cubit.init();
    repository.teams.add([_team('me', isMine: true)]);
    repository.quiz.add(
      _quiz(phase: PubQuizPhase.answering, questionId: 'q1'),
    );
    await _flush();
    expect(cubit.state.screen, PubQuizScreen.question);

    await cubit.answer(2);
    expect(repository.submitted, [('q1', 2)]);
    expect(cubit.state.submission, PubQuizSubmission.submitted);
    repository.answers['q1']!.add(
      const PubQuizAnswer(questionId: 'q1', choice: 2),
    );
    await _flush();
    expect(cubit.state.myAnswer?.choice, 2);

    await cubit.answer(3);
    expect(repository.submitted, hasLength(1), reason: 'one answer only');

    repository.quiz.add(
      _quiz(phase: PubQuizPhase.revealed, questionId: 'q1', correctIndex: 2),
    );
    await _flush();
    expect(cubit.state.screen, PubQuizScreen.reveal);
    expect(cubit.state.revealKey, 'q1');

    repository.quiz.add(
      _quiz(phase: PubQuizPhase.scoreboard, questionId: 'q1', correctIndex: 2),
    );
    await _flush();
    expect(cubit.state.screen, PubQuizScreen.scoreboard);

    repository.quiz.add(
      _quiz(phase: PubQuizPhase.answering, questionId: 'q2'),
    );
    await _flush();
    expect(cubit.state.screen, PubQuizScreen.question);
    expect(cubit.state.myAnswer, isNull);
    expect(cubit.state.submission, PubQuizSubmission.idle);
    expect(cubit.state.revealKey, isNull);

    repository.quiz.add(
      _quiz(phase: PubQuizPhase.finished, questionId: 'q2', correctIndex: 0),
    );
    await _flush();
    expect(cubit.state.screen, PubQuizScreen.finished);
  });

  test('reports an answer the server refused as too late', () async {
    await cubit.init();
    repository.teams.add([_team('me', isMine: true)]);
    repository.quiz.add(
      _quiz(phase: PubQuizPhase.answering, questionId: 'q1'),
    );
    await _flush();
    repository.rejectAnswers = true;

    await cubit.answer(1);

    expect(cubit.state.submission, PubQuizSubmission.tooLate);
    expect(cubit.state.errorMessage, isNull);
  });

  test(
    'derives the scoreboard and own award from the team documents',
    () async {
      await cubit.init();
      const awardMe = PubQuizAward(
        questionId: 'q1',
        points: 3,
        correct: true,
        fastRank: 1,
        choice: 1,
      );
      const awardOld = PubQuizAward(questionId: 'q0', points: 2, correct: true);
      repository.teams.add([
        _team('me', score: 5, isMine: true, lastAward: awardMe),
        _team('them', score: 4, lastAward: awardOld),
      ]);
      repository.quiz.add(
        _quiz(
          phase: PubQuizPhase.scoreboard,
          questionId: 'q1',
          correctIndex: 1,
        ),
      );
      await _flush();

      final board = cubit.state.scoreboard;
      expect(board.map((entry) => entry.teamId), ['me', 'them']);
      expect(board.first.from, 2);
      expect(board.first.to, 5);
      expect(board.first.award, awardMe);
      expect(board.last.from, 4);
      expect(board.last.award, isNull);
      expect(cubit.state.myAward, awardMe);
    },
  );

  test('surfaces stream errors and can retry', () async {
    await cubit.init();
    repository.quiz.addError(Exception('offline'));
    await _flush();
    expect(cubit.state.status, PubQuizStatus.error);

    await cubit.init();
    repository.quiz.add(_quiz());
    await _flush();
    expect(cubit.state.status, PubQuizStatus.loaded);
  });
}

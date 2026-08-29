import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Where the quiz is right now. The server moves it forward; the app only
/// ever renders the phase it is told.
///
/// - [lobby]: teams can join and rename themselves, nothing has started.
/// - [answering]: a question is open and every team can answer once.
/// - [closed]: no more answers are accepted, the server is scoring.
/// - [revealed]: the correct answer and the points are out.
/// - [scoreboard]: a few seconds after the reveal, the standings are shown.
/// - [finished]: the last question has been played, final standings.
enum PubQuizPhase {
  lobby,
  answering,
  closed,
  revealed,
  scoreboard,
  finished;

  static PubQuizPhase parse(Object? raw) {
    return PubQuizPhase.values.asNameMap()[raw] ?? PubQuizPhase.lobby;
  }

  /// Whether the answer to the current question is known to everyone.
  bool get isRevealed => this == revealed || this == scoreboard;
}

/// The question the quiz is currently on, embedded in the quiz document so
/// that the question and the phase always arrive in one snapshot. The
/// reveal fields are null until the server reveals the answer.
class PubQuizQuestion extends Equatable {
  const PubQuizQuestion({
    required this.id,
    required this.index,
    required this.text,
    required this.options,
    this.correctIndex,
    this.answerCounts,
  });

  factory PubQuizQuestion.fromMap(Map<String, dynamic> data) {
    return PubQuizQuestion(
      id: data['id'] as String? ?? '',
      index: (data['index'] as num?)?.toInt() ?? 0,
      text: data['text'] as String? ?? '',
      options: [
        for (final option in data['options'] as List? ?? const [])
          option.toString(),
      ],
      correctIndex: (data['correctIndex'] as num?)?.toInt(),
      answerCounts: switch (data['answerCounts']) {
        final List<Object?> counts => [
          for (final count in counts) (count! as num).toInt(),
        ],
        _ => null,
      },
    );
  }

  final String id;

  /// Zero-based position in the quiz.
  final int index;
  final String text;
  final List<String> options;

  /// Index into [options] of the correct answer, once revealed.
  final int? correctIndex;

  /// How many teams picked each option, once revealed.
  final List<int>? answerCounts;

  @override
  List<Object?> get props => [
    id,
    index,
    text,
    options,
    correctIndex,
    answerCounts,
  ];
}

/// The quiz document, as kept up to date by the conference website's server
/// while an organizer runs the quiz.
class PubQuiz extends Equatable {
  const PubQuiz({
    required this.id,
    required this.phase,
    required this.questionIndex,
    required this.questionCount,
    required this.answeredCount,
    required this.teamCount,
    this.question,
    this.revealedAt,
  });

  factory PubQuiz.fromDocument({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return PubQuiz(
      id: id,
      phase: PubQuizPhase.parse(data['phase']),
      questionIndex: (data['questionIndex'] as num?)?.toInt() ?? -1,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      answeredCount: (data['answeredCount'] as num?)?.toInt() ?? 0,
      teamCount: (data['teamCount'] as num?)?.toInt() ?? 0,
      question: switch (data['currentQuestion']) {
        final Map<String, dynamic> question => PubQuizQuestion.fromMap(
          question,
        ),
        _ => null,
      },
      revealedAt: (data['revealedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final PubQuizPhase phase;

  /// Zero-based index of the current question, -1 before the first one.
  final int questionIndex;
  final int questionCount;

  /// How many of the teams that were in when the question opened have
  /// answered it, refreshed by the server while the question is open.
  final int answeredCount;
  final int teamCount;
  final PubQuizQuestion? question;
  final DateTime? revealedAt;

  @override
  List<Object?> get props => [
    id,
    phase,
    questionIndex,
    questionCount,
    answeredCount,
    teamCount,
    question,
    revealedAt,
  ];
}

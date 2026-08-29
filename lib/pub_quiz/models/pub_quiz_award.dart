import 'package:equatable/equatable.dart';

/// What one team earned on one question, as written by the server when the
/// answer was revealed: two points for a correct answer plus one bonus point
/// for the three fastest correct teams. Teams that answered wrong or not at
/// all get an award of zero points, so every team has one per question.
class PubQuizAward extends Equatable {
  const PubQuizAward({
    required this.questionId,
    required this.points,
    required this.correct,
    this.fastRank,
    this.choice,
  });

  factory PubQuizAward.fromMap(Map<String, dynamic> data) {
    return PubQuizAward(
      questionId: data['questionId'] as String? ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      correct: data['correct'] as bool? ?? false,
      fastRank: (data['fastRank'] as num?)?.toInt(),
      choice: (data['choice'] as num?)?.toInt(),
    );
  }

  final String questionId;
  final int points;
  final bool correct;

  /// 1, 2 or 3 when the team was among the fastest correct answers, which
  /// is what the bonus point is for; null otherwise.
  final int? fastRank;

  /// The option the team picked, or null when it did not answer.
  final int? choice;

  bool get answered => choice != null;

  @override
  List<Object?> get props => [questionId, points, correct, fastRank, choice];
}

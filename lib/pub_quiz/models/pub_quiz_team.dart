import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/pub_quiz/models/pub_quiz_award.dart';

/// A team in the quiz: one per device, named by the players, scored by the
/// server.
class PubQuizTeam extends Equatable {
  const PubQuizTeam({
    required this.id,
    required this.name,
    required this.score,
    required this.isMine,
    this.lastAward,
  });

  factory PubQuizTeam.fromDocument({
    required String id,
    required Map<String, dynamic> data,
    required String currentUserId,
  }) {
    return PubQuizTeam(
      id: id,
      name: data['name'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      isMine: id == currentUserId,
      lastAward: switch (data['lastAward']) {
        final Map<String, dynamic> award => PubQuizAward.fromMap(award),
        _ => null,
      },
    );
  }

  final String id;
  final String name;
  final int score;

  /// Whether this is the team playing on this device.
  final bool isMine;

  /// The points from the most recently revealed question, written together
  /// with [score] so the difference between the two is always what the
  /// team just earned.
  final PubQuizAward? lastAward;

  @override
  List<Object?> get props => [id, name, score, isMine, lastAward];
}

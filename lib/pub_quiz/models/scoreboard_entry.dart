import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/pub_quiz/models/pub_quiz_award.dart';
import 'package:flutter_and_friends/pub_quiz/models/pub_quiz_team.dart';

/// One row of the scoreboard, with the score to animate from and to. Both
/// come straight from the team document: the server writes the new score
/// and the points it just added in the same batch, so the previous score is
/// simply the difference. That makes the animation replayable from any
/// snapshot, whether the phone watched the reveal or wakes up after it.
class ScoreboardEntry extends Equatable {
  const ScoreboardEntry({
    required this.teamId,
    required this.name,
    required this.from,
    required this.to,
    required this.isMine,
    this.award,
  });

  factory ScoreboardEntry.fromTeam(
    PubQuizTeam team, {
    required String? currentQuestionId,
  }) {
    final award = team.lastAward;
    final isCurrent =
        award != null &&
        currentQuestionId != null &&
        award.questionId == currentQuestionId;
    return ScoreboardEntry(
      teamId: team.id,
      name: team.name,
      from: isCurrent ? team.score - award.points : team.score,
      to: team.score,
      isMine: team.isMine,
      award: isCurrent ? award : null,
    );
  }

  final String teamId;
  final String name;
  final int from;
  final int to;
  final bool isMine;

  /// The points earned on the question that was just revealed, or null when
  /// nothing changed for this team in the current reveal.
  final PubQuizAward? award;

  bool get gainedPoints => (award?.points ?? 0) > 0;

  @override
  List<Object?> get props => [teamId, name, from, to, isMine, award];
}

/// Sorts [entries] by [score] descending, then by name, then by id, so two
/// teams on equal points always keep the same relative order.
List<ScoreboardEntry> rankScoreboard(
  List<ScoreboardEntry> entries,
  int Function(ScoreboardEntry entry) score,
) {
  return [...entries]..sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    if (byScore != 0) return byScore;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.teamId.compareTo(b.teamId);
  });
}

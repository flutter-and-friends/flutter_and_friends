import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

PubQuizTeam _team(
  String id, {
  int score = 0,
  PubQuizAward? lastAward,
  bool isMine = false,
}) {
  return PubQuizTeam(
    id: id,
    name: id,
    score: score,
    isMine: isMine,
    lastAward: lastAward,
  );
}

void main() {
  group('ScoreboardEntry.fromTeam', () {
    test('animates from the score before the current award', () {
      final entry = ScoreboardEntry.fromTeam(
        _team(
          'a',
          score: 5,
          lastAward: const PubQuizAward(
            questionId: 'q3',
            points: 3,
            correct: true,
            fastRank: 1,
            choice: 2,
          ),
        ),
        currentQuestionId: 'q3',
      );

      expect(entry.from, 2);
      expect(entry.to, 5);
      expect(entry.award?.points, 3);
      expect(entry.gainedPoints, isTrue);
    });

    test('shows a stable score when the award is from an older question', () {
      final entry = ScoreboardEntry.fromTeam(
        _team(
          'a',
          score: 5,
          lastAward: const PubQuizAward(
            questionId: 'q2',
            points: 2,
            correct: true,
          ),
        ),
        currentQuestionId: 'q3',
      );

      expect(entry.from, 5);
      expect(entry.to, 5);
      expect(entry.award, isNull);
      expect(entry.gainedPoints, isFalse);
    });

    test('shows a stable score when nothing is revealed', () {
      final entry = ScoreboardEntry.fromTeam(
        _team(
          'a',
          score: 5,
          lastAward: const PubQuizAward(
            questionId: 'q3',
            points: 2,
            correct: true,
          ),
        ),
        currentQuestionId: null,
      );

      expect(entry.from, 5);
      expect(entry.to, 5);
      expect(entry.award, isNull);
    });
  });

  group('rankScoreboard', () {
    test('orders by the given score, then name, then id', () {
      const entries = [
        ScoreboardEntry(
          teamId: '2',
          name: 'bob',
          from: 1,
          to: 4,
          isMine: false,
        ),
        ScoreboardEntry(
          teamId: '1',
          name: 'Amy',
          from: 3,
          to: 4,
          isMine: false,
        ),
        ScoreboardEntry(teamId: '3', name: 'Cat', from: 6, to: 6, isMine: true),
        ScoreboardEntry(
          teamId: '4',
          name: 'Amy',
          from: 0,
          to: 4,
          isMine: false,
        ),
      ];

      final byNew = rankScoreboard(entries, (entry) => entry.to);
      expect(byNew.map((entry) => entry.teamId), ['3', '1', '4', '2']);

      final byOld = rankScoreboard(entries, (entry) => entry.from);
      expect(byOld.map((entry) => entry.teamId), ['3', '1', '2', '4']);
    });
  });
}

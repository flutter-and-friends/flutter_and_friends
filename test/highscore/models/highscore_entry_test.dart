import 'package:flutter_and_friends/highscore/highscore.dart';
import 'package:flutter_test/flutter_test.dart';

HighscoreEntry _entry(String id, {String? name, int count = 0}) {
  return HighscoreEntry(
    id: id,
    name: name ?? id,
    count: count,
    isMine: false,
  );
}

void main() {
  group('HighscoreEntry.fromDocument', () {
    test('reads the fields and marks the current user', () {
      final entry = HighscoreEntry.fromDocument(
        id: 'me',
        data: const {'name': 'Lukas', 'count': 7},
        currentUserId: 'me',
      );
      expect(entry.name, 'Lukas');
      expect(entry.count, 7);
      expect(entry.isMine, isTrue);
    });

    test('tolerates missing fields', () {
      final entry = HighscoreEntry.fromDocument(
        id: 'other',
        data: const {},
        currentUserId: 'me',
      );
      expect(entry.name, isEmpty);
      expect(entry.count, 0);
      expect(entry.isMine, isFalse);
    });
  });

  group('rankHighscores', () {
    test('orders by count, then name, then id', () {
      final ranked = rankHighscores([
        _entry('c', name: 'Zed', count: 2),
        _entry('b', name: 'amy', count: 2),
        _entry('a', name: 'Amy', count: 2),
        _entry('d', name: 'Top', count: 5),
      ]);
      expect(ranked.map((entry) => entry.id), ['d', 'a', 'b', 'c']);
    });

    test('leaves the input untouched', () {
      final entries = [_entry('a', count: 1), _entry('b', count: 2)];
      rankHighscores(entries);
      expect(entries.first.id, 'a');
    });
  });

  group('HighscoreSubmission.from', () {
    test('trims the badge name', () {
      final submission = HighscoreSubmission.from(
        badgeName: '  Lukas  ',
        count: 3,
      );
      expect(submission.name, 'Lukas');
      expect(submission.hasName, isTrue);
    });

    test('has no name when the badge has none', () {
      final submission = HighscoreSubmission.from(badgeName: '   ', count: 3);
      expect(submission.hasName, isFalse);
    });

    test('cuts the name to what the rules accept', () {
      final submission = HighscoreSubmission.from(
        badgeName: 'x' * (maxHighscoreNameLength + 5),
        count: 0,
      );
      expect(submission.name.length, maxHighscoreNameLength);
    });
  });
}

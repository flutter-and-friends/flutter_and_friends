import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBadgeRoster', () {
    test('reads name, role and email by header', () {
      final entries = parseBadgeRoster(
        'Email,Name,Role\n'
        'ada@example.com,Ada Lovelace,Speaker\n'
        ',Charles Babbage,Attendee\n',
      );

      expect(entries, [
        const BadgeRosterEntry(
          name: 'Ada Lovelace',
          role: 'Speaker',
          email: 'ada@example.com',
        ),
        const BadgeRosterEntry(name: 'Charles Babbage', role: 'Attendee'),
      ]);
    });

    test('takes the columns in order when there is no header', () {
      final entries = parseBadgeRoster(
        'Ada Lovelace,Speaker,ada@example.com\nCharles Babbage,Attendee',
      );

      expect(entries, hasLength(2));
      expect(entries.first.email, 'ada@example.com');
      expect(entries.last.role, 'Attendee');
      expect(entries.last.email, isEmpty);
    });

    test('accepts semicolons and tabs as delimiters', () {
      expect(
        parseBadgeRoster('name;role;e-mail\nAda;Speaker;ada@example.com'),
        [
          const BadgeRosterEntry(
            name: 'Ada',
            role: 'Speaker',
            email: 'ada@example.com',
          ),
        ],
      );
      expect(parseBadgeRoster('Ada\tSpeaker'), [
        const BadgeRosterEntry(name: 'Ada', role: 'Speaker'),
      ]);
    });

    test('handles quoted fields, doubled quotes and CRLF line endings', () {
      final entries = parseBadgeRoster(
        'name,role\r\n"Lovelace, Ada","Speaker ""AI"""\r\n',
      );

      expect(entries, [
        const BadgeRosterEntry(name: 'Lovelace, Ada', role: 'Speaker "AI"'),
      ]);
    });

    test('skips blank lines, rows without a name and a byte order mark', () {
      final entries = parseBadgeRoster(
        '\u{FEFF}name,role\n\n,Attendee\n   ,Attendee\nAda,Speaker\n\n',
      );

      expect(entries, [const BadgeRosterEntry(name: 'Ada', role: 'Speaker')]);
    });

    test('trims cells', () {
      expect(parseBadgeRoster(' Ada , Speaker , ada@example.com '), [
        const BadgeRosterEntry(
          name: 'Ada',
          role: 'Speaker',
          email: 'ada@example.com',
        ),
      ]);
    });

    test('throws when the file has no people', () {
      expect(() => parseBadgeRoster(''), throwsFormatException);
      expect(() => parseBadgeRoster('name,role\n'), throwsFormatException);
      expect(
        () => parseBadgeRoster('name,role\n,Speaker'),
        throwsFormatException,
      );
    });
  });
}

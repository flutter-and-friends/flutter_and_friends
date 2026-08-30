import 'dart:typed_data';

import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_badge/friends_badge.dart';

void main() {
  group('toCollectedPerson', () {
    final at = DateTime(2026, 8, 24, 12);

    test('maps a full badge: name, role, and all URLs', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([
          NdefRecord.uri(Uri.parse('https://johannes.dev')),
          NdefRecord.text(
            'Johannes Pietilä Löhnn · Organizer · '
            'x.com/johannes · linkedin.com/in/johannes',
          ),
        ]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.name, 'Johannes Pietilä Löhnn');
      expect(collected.role, 'Organizer');
      expect(
        collected.urls,
        [
          'https://johannes.dev',
          'https://x.com/johannes',
          'https://linkedin.com/in/johannes',
        ],
      );
      expect(collected.collectedAt, at);
    });

    test('prefixes bare URLs with https:// so url_launcher can open them', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([
          NdefRecord.text('A · B · x.com/johannes'),
        ]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.urls, ['https://x.com/johannes']);
    });

    test('leaves URLs that already carry a scheme unchanged', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([
          NdefRecord.text('A · B · http://example.com/in/johannes'),
        ]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.urls, ['http://example.com/in/johannes']);
    });

    test('name-only Text record collects with empty role and no URLs', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([NdefRecord.text('Johannes')]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.name, 'Johannes');
      expect(collected.role, isEmpty);
      expect(collected.urls, isEmpty);
    });

    test('empty role stays empty, URLs still collect', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([
          NdefRecord.text('Johannes ·  · x.com/johannes'),
        ]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.name, 'Johannes');
      expect(collected.role, isEmpty);
      expect(collected.urls, ['https://x.com/johannes']);
    });

    test('no-URL badge (name and role only) collects with empty urls', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([NdefRecord.text('Johannes · Organizer')]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.name, 'Johannes');
      expect(collected.role, 'Organizer');
      expect(collected.urls, isEmpty);
    });

    test('dedupes the primary URI when it also appears in the Text record', () {
      // The app's own writer puts the same link in both the U record and
      // the T record — the common case should yield a single URL.
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([
          NdefRecord.uri(Uri.parse('https://x.com/johannes')),
          NdefRecord.text('Johannes · Organizer · x.com/johannes'),
        ]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.urls, ['https://x.com/johannes']);
    });

    test(
      'malformed-degraded input (garbage Text record) collects an empty '
      'person',
      () {
        // A Text record whose declared language length exceeds its payload
        // fails to decode; BadgePerson degrades every field to empty.
        final person = BadgePerson.fromNdefMessage(
          NdefMessage([
            NdefRecord(
              tnf: 0x01, // well-known
              type: Uint8List.fromList(const [0x54]), // "T"
              payload: Uint8List.fromList(const [10, 0x65, 0x6E]),
            ),
          ]),
        );

        final collected = toCollectedPerson(person, collectedAt: at);

        expect(collected.name, isEmpty);
        expect(collected.role, isEmpty);
        expect(collected.urls, isEmpty);
        expect(collected.collectedAt, at);
      },
    );

    test('defaults collectedAt to now when not provided', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([NdefRecord.text('Johannes')]),
      );

      final before = DateTime.now();
      final collected = toCollectedPerson(person);
      final after = DateTime.now();

      expect(
        collected.collectedAt.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        collected.collectedAt.isBefore(
          after.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });

  group('toCollectedPerson badgeId', () {
    const person = BadgePerson(
      name: 'Lukas',
      role: 'Test',
      urls: [],
      primaryUri: null,
      installId: null,
      capybaraId: null,
    );

    test('stores the badge ID handed in by the collector', () {
      final collected = toCollectedPerson(person, badgeId: '1dd4ad1958');

      expect(collected.badgeId, '1dd4ad1958');
    });

    test('has no badge ID when the collector reported none', () {
      expect(toCollectedPerson(person).badgeId, isNull);
    });
  });

  group('CollectedPerson JSON', () {
    test('round-trips through toJson/fromJson', () {
      final person = CollectedPerson(
        name: 'Johannes Pietilä Löhnn',
        role: 'Organizer',
        urls: const ['https://x.com/johannes'],
        collectedAt: DateTime(2026, 8, 24, 12, 30),
        installId: 'id-1',
        capybaraId: 'coffee_mode',
        badgeId: '1dd4ad1958',
      );

      final restored = CollectedPerson.fromJson(person.toJson());

      expect(restored, person);
      expect(restored.badgeId, '1dd4ad1958');
    });

    test('fromJson tolerates missing fields', () {
      final restored = CollectedPerson.fromJson(const {});

      expect(restored.name, isEmpty);
      expect(restored.role, isEmpty);
      expect(restored.urls, isEmpty);
      expect(restored.installId, isNull);
      expect(restored.capybaraId, isNull);
      expect(restored.badgeId, isNull);
    });

    test('omits badgeId from JSON when it is null', () {
      final person = CollectedPerson(
        name: 'Johannes',
        role: 'Organizer',
        urls: const [],
        collectedAt: DateTime(2026, 8, 24, 12),
      );

      expect(person.toJson().containsKey('badgeId'), isFalse);
    });

    test(
      'decodes a pre-v2 entry (no installId/capybaraId keys) with nulls',
      () {
        // Shape written by the pre-v2 build of the app.
        final restored = CollectedPerson.fromJson(const {
          'name': 'Johannes',
          'role': 'Organizer',
          'urls': ['https://x.com/johannes'],
          'collectedAt': '2026-08-24T12:00:00.000',
        });

        expect(restored.name, 'Johannes');
        expect(restored.installId, isNull);
        expect(restored.capybaraId, isNull);
      },
    );
  });

  group('toCollectedPerson v2 fields', () {
    final at = DateTime(2026, 8, 24, 12);

    test('passes installId and capybaraId through from the badge', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([
          NdefRecord.text(
            'Johannes · Organizer · x.com/johannes · id:abc-123 · '
            'capy:coffee_mode',
          ),
        ]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.installId, 'abc-123');
      expect(collected.capybaraId, 'coffee_mode');
      // Tagged segments are not URLs.
      expect(collected.urls, ['https://x.com/johannes']);
    });

    test('pre-v2 badge (no tagged segments) maps both fields to null', () {
      final person = BadgePerson.fromNdefMessage(
        NdefMessage([NdefRecord.text('Johannes · Organizer')]),
      );

      final collected = toCollectedPerson(person, collectedAt: at);

      expect(collected.installId, isNull);
      expect(collected.capybaraId, isNull);
    });
  });
}

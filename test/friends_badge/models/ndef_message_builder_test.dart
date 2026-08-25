import 'dart:convert';

import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_badge/friends_badge.dart';

/// Decodes an NFC Forum Text record payload into its text content.
String _decodeTextRecord(NdefRecord record) {
  final langLength = record.payload[0];
  return utf8.decode(record.payload.sublist(1 + langLength));
}

void main() {
  group('buildBadgeNdefMessage', () {
    group('when the URL is empty', () {
      test('returns null (no NDEF write)', () {
        expect(
          buildBadgeNdefMessage(name: 'Johannes', role: 'Organizer', url: ''),
          isNull,
        );
      });

      test('returns null when the URL is only whitespace', () {
        expect(
          buildBadgeNdefMessage(name: 'Johannes', role: 'Organizer', url: '  '),
          isNull,
        );
      });
    });

    group('when the URL is provided', () {
      test('produces a URI record first and a Text record second', () {
        final message = buildBadgeNdefMessage(
          name: 'Johannes Pietilä Löhnn',
          role: 'Organizer',
          url: 'x.com/johannes',
        )!;

        expect(message.records, hasLength(2));
        // NFC Forum well-known types: 'U' (0x55) then 'T' (0x54).
        expect(message.records[0].type.single, 0x55);
        expect(message.records[1].type.single, 0x54);
      });

      test('T record segments in canonical v2 order without tagged segments',
          () {
        final message = buildBadgeNdefMessage(
          name: 'Johannes Pietilä Löhnn',
          role: 'Organizer',
          url: 'x.com/johannes',
        )!;

        expect(
          _decodeTextRecord(message.records[1]),
          'Johannes Pietilä Löhnn · Organizer · x.com/johannes',
        );
      });

      test('appends id: segment when installId is given', () {
        final message = buildBadgeNdefMessage(
          name: 'A',
          role: 'B',
          url: 'x.com/a',
          installId: 'uuid-1234',
        )!;

        expect(
          _decodeTextRecord(message.records[1]),
          'A · B · x.com/a · id:uuid-1234',
        );
      });

      test('appends capy: segment when capybaraId is given', () {
        final message = buildBadgeNdefMessage(
          name: 'A',
          role: 'B',
          url: 'x.com/a',
          capybaraId: 'coffee_mode',
        )!;

        expect(
          _decodeTextRecord(message.records[1]),
          'A · B · x.com/a · capy:coffee_mode',
        );
      });

      test('appends id: then capy: when both are given (canonical order)',
          () {
        final message = buildBadgeNdefMessage(
          name: 'A',
          role: 'B',
          url: 'x.com/a',
          installId: 'uuid-1234',
          capybaraId: 'coffee_mode',
        )!;

        expect(
          _decodeTextRecord(message.records[1]),
          'A · B · x.com/a · id:uuid-1234 · capy:coffee_mode',
        );
      });

      test('passes the URL through bare — no scheme added', () {
        final message = buildBadgeNdefMessage(
          name: 'A',
          role: 'B',
          url: 'linkedin.com/in/johannes',
        )!;

        final uriPayload = utf8.decode(message.records[0].payload);
        expect(uriPayload, isNot(contains('http')));
        expect(
          _decodeTextRecord(message.records[1]),
          'A · B · linkedin.com/in/johannes',
        );
      });

      test('trims surrounding whitespace on the URL', () {
        final message = buildBadgeNdefMessage(
          name: 'A',
          role: 'B',
          url: '  x.com/johannes  ',
        )!;

        expect(
          _decodeTextRecord(message.records[1]),
          'A · B · x.com/johannes',
        );
      });

      test('empty role round-trips through the BadgePerson decoder', () {
        final message = buildBadgeNdefMessage(
          name: 'Johannes',
          role: '',
          url: 'x.com/johannes',
          installId: 'uuid-1',
          capybaraId: 'coder',
        )!;

        final person = BadgePerson.fromNdefMessage(message);
        expect(person.name, 'Johannes');
        expect(person.role, '');
        expect(person.urls, ['x.com/johannes']);
        expect(person.installId, 'uuid-1');
        expect(person.capybaraId, 'coder');
        expect(person.primaryUri, Uri.parse('x.com/johannes'));
      });
    });
  });
}

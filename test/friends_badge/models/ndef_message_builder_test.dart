import 'dart:convert';

import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildBadgeNdefMessage', () {
    group('when the URL is empty', () {
      test('returns null (no NDEF write)', () {
        expect(
          buildBadgeNdefMessage(
            name: 'Johannes',
            role: 'Organizer',
            url: '',
          ),
          isNull,
        );
      });

      test('returns null when the URL is only whitespace', () {
        expect(
          buildBadgeNdefMessage(
            name: 'Johannes',
            role: 'Organizer',
            url: '   ',
          ),
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

      test(
        'Text record carries "Name · Role · url" with middle-dot separators',
        () {
          final message = buildBadgeNdefMessage(
            name: 'Johannes Pietilä Löhnn',
            role: 'Organizer',
            url: 'x.com/johannes',
          )!;

          // Text RTD payload: status byte (lang length), lang bytes, then
          // UTF-8 text.
          final payload = message.records[1].payload;
          final langLength = payload[0];
          final text = utf8.decode(payload.sublist(1 + langLength));
          expect(
            text,
            'Johannes Pietilä Löhnn · Organizer · x.com/johannes',
          );
        },
      );

      test('passes the URL through bare — no scheme added', () {
        final message = buildBadgeNdefMessage(
          name: 'A',
          role: 'B',
          url: 'linkedin.com/in/johannes',
        )!;

        // The URI record payload must not contain "http" anywhere; the
        // friends-badge-ndef contract says URLs are stored bare as typed.
        final uriPayload = utf8.decode(message.records[0].payload);
        expect(uriPayload, isNot(contains('http')));
      });

      test('trims surrounding whitespace on the URL', () {
        final message = buildBadgeNdefMessage(
          name: 'A',
          role: 'B',
          url: '  x.com/johannes  ',
        )!;

        final payload = message.records[1].payload;
        final langLength = payload[0];
        final text = utf8.decode(payload.sublist(1 + langLength));
        expect(text, 'A · B · x.com/johannes');
      });
    });
  });
}

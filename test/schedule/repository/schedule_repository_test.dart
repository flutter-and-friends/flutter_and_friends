import 'dart:convert';

import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

String _feed({required String trackLabel}) => jsonEncode({
  'generated_at': '2026-08-26T12:27:48+00:00',
  'version': 1,
  'days': [
    {
      'date': '2026-09-04',
      'label': 'Conference Day',
      'tracks': [
        {'id': 'main', 'label': trackLabel},
      ],
    },
  ],
  'sessions': [
    {
      'id': 'talk',
      'type': 'talk',
      'category': 'talk',
      'title': 'A talk',
      'description': '',
      'speaker_slugs': <String>[],
      'day': '2026-09-04',
      'start': '2026-09-04T09:30:00+02:00',
      'end': '2026-09-04T10:15:00+02:00',
      'duration_minutes': 45,
      'track': 'main',
      'location': null,
      'published': true,
    },
  ],
  'speakers': <Object>[],
});

void main() {
  group('ScheduleRepository', () {
    for (final (feedLabel, displayed) in [
      ('THEATRE STAGE', 'Theatre stage'),
      ('Kägelbanan STAGE', 'Kägelbanan'),
      ('AI Track', 'AI Track'),
      ('MAIN HALL', 'Main hall'),
    ]) {
      test('shows the track label "$feedLabel" as "$displayed"', () {
        final result = ScheduleRepository(
          feedUrl: 'http://localhost',
        ).parseSnapshot(_feed(trackLabel: feedLabel));

        expect(result.schedule.events.single.location?.name, displayed);
      });
    }
  });
}

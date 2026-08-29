import 'package:flutter/material.dart';
import 'package:flutter_and_friends/favorites/favorites.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class _MemoryStorage implements Storage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Future<void> close() async {}
}

const _location = Location(
  name: 'Skandia Bank, Lindhagensgatan 86',
  coordinates: (59.33, 18.02),
);

const _speaker = Speaker(
  slug: 'emma',
  name: 'Emma Twersky',
  title: 'Staff Developer Relations Engineer / Lead @ Google',
  bio: '',
);

final _startTime = DateTime(2026, 9, 4, 9, 30);

Talk _talk() => Talk(
  id: 'talk',
  name: 'Flutter is Everywhere',
  speakers: const [_speaker],
  duration: const Duration(minutes: 45),
  startTime: _startTime,
  location: _location,
  description: '',
);

Workshop _workshop() => Workshop(
  id: 'workshop',
  name: 'Hybrid AI in Flutter with Genkit Dart',
  speakers: const [_speaker],
  duration: const Duration(minutes: 90),
  startTime: _startTime,
  location: _location,
  description: '',
);

Activity _activity() => Activity(
  id: 'activity',
  name: 'Free hackathon (all day)',
  duration: const Duration(hours: 6, minutes: 30),
  startTime: _startTime,
  location: _location,
  description: 'A free hackathon runs all day at Skandia Bank.',
);

Widget _subject(Event event, {bool showDate = true}) {
  return MaterialApp(
    home: BlocProvider(
      create: (_) => FavoritesCubit(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [EventCard(event: event, showDate: showDate)],
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
  });

  group('EventCard', () {
    for (final (label, event) in <(String, Event)>[
      ('TalkCard', _talk()),
      ('WorkshopCard', _workshop()),
      ('ActivityCard', _activity()),
    ]) {
      testWidgets('$label fits a 320 pixel wide screen', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_subject(event));

        expect(tester.takeException(), isNull);
        expect(find.text(_location.name), findsOneWidget);
      });
    }

    testWidgets('shows the date by default', (tester) async {
      await tester.pumpWidget(_subject(_talk()));

      expect(find.text('September 4, 9:30 AM - 10:15 AM'), findsOneWidget);
    });

    testWidgets('shows only the time when the date is hidden', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(_talk(), showDate: false));

      expect(find.text('9:30 AM - 10:15 AM'), findsOneWidget);
      expect(find.textContaining('September'), findsNothing);
    });
  });
}

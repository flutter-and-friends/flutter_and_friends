import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/highscore/highscore.dart';
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

class _FakeRepository implements HighscoreRepository {
  final entries = StreamController<List<HighscoreEntry>>.broadcast();

  @override
  Future<void> signIn() async {}

  @override
  Stream<List<HighscoreEntry>> watchHighscores({int limit = 100}) {
    return entries.stream;
  }

  @override
  Future<void> submit(HighscoreSubmission submission) async {}

  @override
  Future<void> remove() async {}
}

HighscoreEntry _entry(String name, {int count = 0, bool isMine = false}) {
  return HighscoreEntry(id: name, name: name, count: count, isMine: isMine);
}

CollectedPerson _person(String name) {
  return CollectedPerson(
    name: name,
    role: 'Speaker',
    urls: const [],
    collectedAt: DateTime(2026, 9, 3),
    badgeId: name,
  );
}

void main() {
  late _FakeRepository repository;
  late HighscoreCubit cubit;
  late CollectedPeopleCubit people;
  late BadgeIdentityCubit identity;

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
    repository = _FakeRepository();
    cubit = HighscoreCubit(repository: repository);
    people = CollectedPeopleCubit();
    identity = BadgeIdentityCubit();
  });

  tearDown(() async {
    await cubit.close();
    await people.close();
    await identity.close();
  });

  Widget subject() {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: people),
        BlocProvider.value(value: identity),
      ],
      child: const MaterialApp(home: HighscoreView()),
    );
  }

  Future<void> load(WidgetTester tester, List<HighscoreEntry> entries) async {
    await cubit.init();
    await tester.pumpWidget(subject());
    repository.entries.add(entries);
    await tester.pump();
  }

  testWidgets('lists the board with ranks and highlights this device', (
    tester,
  ) async {
    identity.updateName('Lukas');
    people
      ..collect(_person('Johannes'))
      ..collect(_person('Felix'));
    await load(tester, [
      _entry('Johannes', count: 9),
      _entry('Lukas', count: 2, isMine: true),
    ]);

    expect(find.byType(HighscoreRow), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('You have collected 2 people'), findsOneWidget);
    expect(find.text('#2 on the highscore'), findsOneWidget);
    expect(find.byType(HighscoreNameField), findsNothing);
  });

  testWidgets('asks for a name while the badge has none', (tester) async {
    people.collect(_person('Johannes'));
    await load(tester, [_entry('Johannes', count: 9)]);

    expect(find.text('You have collected 1 person'), findsOneWidget);
    expect(find.byType(HighscoreNameField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Lukas ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(identity.state.name, 'Lukas');
    expect(find.byType(HighscoreNameField), findsNothing);
  });

  testWidgets('explains an empty board', (tester) async {
    identity.updateName('Lukas');
    await load(tester, const []);

    expect(find.byType(HighscoreRow), findsNothing);
    expect(find.textContaining('Nobody has collected anyone yet'), findsOne);
    expect(find.text('Tap a badge to get on the board'), findsOneWidget);
  });

  testWidgets('offers a retry when the board fails to load', (tester) async {
    await cubit.init();
    await tester.pumpWidget(subject());
    repository.entries.addError(Exception('offline'));
    await tester.pump();

    expect(find.text('Could not load the highscore'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

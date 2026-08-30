import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/highscore/highscore.dart';
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

/// Stands in for Firestore: records what the cubit publishes and can be
/// told to fail.
class _FakeRepository implements HighscoreRepository {
  final submitted = <HighscoreSubmission>[];
  int removed = 0;
  int signIns = 0;
  bool failSignIn = false;

  @override
  Future<void> signIn() async {
    signIns += 1;
    if (failSignIn) throw Exception('offline');
  }

  @override
  Stream<List<HighscoreEntry>> watchHighscores({int limit = 100}) {
    return const Stream.empty();
  }

  @override
  Future<void> submit(HighscoreSubmission submission) async {
    submitted.add(submission);
  }

  @override
  Future<void> remove() async => removed += 1;
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

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepository repository;
  late CollectedPeopleCubit people;
  late BadgeIdentityCubit identity;
  late HighscoreSyncCubit sync;

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
    repository = _FakeRepository();
    people = CollectedPeopleCubit();
    identity = BadgeIdentityCubit();
    sync = HighscoreSyncCubit(
      people: people,
      identity: identity,
      repository: repository,
      debounce: Duration.zero,
    );
  });

  tearDown(() async {
    await sync.close();
    await people.close();
    await identity.close();
  });

  test('publishes the badge name and collected count on start', () async {
    identity.updateName('Lukas');
    people.collect(_person('Johannes'));

    await sync.start();

    expect(repository.submitted, [
      const HighscoreSubmission(name: 'Lukas', count: 1),
    ]);
    expect(sync.state.status, HighscoreSyncStatus.synced);
    expect(
      sync.state.published,
      const HighscoreSubmission(name: 'Lukas', count: 1),
    );
  });

  test('stays off the board without a name', () async {
    people.collect(_person('Johannes'));

    await sync.start();

    expect(repository.submitted, isEmpty);
    expect(repository.removed, 0);
    expect(sync.state.status, HighscoreSyncStatus.synced);
    expect(sync.state.published, isNull);
  });

  test('republishes when a person is collected', () async {
    identity.updateName('Lukas');
    await sync.start();

    people.collect(_person('Johannes'));
    await _flush();
    await _flush();

    expect(repository.submitted.last.count, 1);
  });

  test('republishes when the badge name changes', () async {
    identity.updateName('Lukas');
    await sync.start();

    identity.updateName('Lukas K');
    await _flush();
    await _flush();

    expect(repository.submitted.last.name, 'Lukas K');
  });

  test('does not publish again when nothing changed', () async {
    identity.updateName('Lukas');
    await sync.start();

    await sync.sync();
    identity.updateRole('Organizer');
    await _flush();
    await _flush();

    expect(repository.submitted, hasLength(1));
  });

  test('removes the entry when the name is cleared', () async {
    identity.updateName('Lukas');
    await sync.start();

    identity.updateName('');
    await _flush();
    await _flush();

    expect(repository.removed, 1);
    expect(sync.state.published, isNull);
  });

  test('keeps the failure and publishes on the next sync', () async {
    identity.updateName('Lukas');
    repository.failSignIn = true;

    await sync.start();
    expect(sync.state.status, HighscoreSyncStatus.failure);
    expect(repository.submitted, isEmpty);

    repository.failSignIn = false;
    await sync.sync();

    expect(sync.state.status, HighscoreSyncStatus.synced);
    expect(repository.submitted, hasLength(1));
  });

  test('publishes the latest submission after an overlapping sync', () async {
    identity.updateName('Lukas');
    final first = sync.start();
    people.collect(_person('Johannes'));
    await sync.sync();
    await first;
    await _flush();
    await _flush();

    expect(repository.submitted.last.count, 1);
    expect(sync.state.published?.count, 1);
  });
}

import 'dart:async';

import 'package:flutter_and_friends/highscore/highscore.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements HighscoreRepository {
  final entries = StreamController<List<HighscoreEntry>>.broadcast();
  bool failSignIn = false;

  @override
  Future<void> signIn() async {
    if (failSignIn) throw Exception('offline');
  }

  @override
  Stream<List<HighscoreEntry>> watchHighscores({int limit = 100}) {
    return entries.stream;
  }

  @override
  Future<void> submit(HighscoreSubmission submission) async {}

  @override
  Future<void> remove() async {}
}

HighscoreEntry _entry(String id, {int count = 0, bool isMine = false}) {
  return HighscoreEntry(id: id, name: id, count: count, isMine: isMine);
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepository repository;
  late HighscoreCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    cubit = HighscoreCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('loads the board and finds this device on it', () async {
    await cubit.init();
    expect(cubit.state.status, HighscoreStatus.loading);

    repository.entries.add([
      _entry('a', count: 5),
      _entry('me', count: 3, isMine: true),
    ]);
    await _flush();

    expect(cubit.state.status, HighscoreStatus.loaded);
    expect(cubit.state.entries, hasLength(2));
    expect(cubit.state.myRank, 2);
  });

  test('has no rank while this device is not on the board', () async {
    await cubit.init();
    repository.entries.add([_entry('a', count: 5)]);
    await _flush();

    expect(cubit.state.myRank, isNull);
  });

  test('fails when signing in fails and recovers on retry', () async {
    repository.failSignIn = true;
    await cubit.init();
    expect(cubit.state.status, HighscoreStatus.error);

    repository.failSignIn = false;
    await cubit.init();
    repository.entries.add(const []);
    await _flush();

    expect(cubit.state.status, HighscoreStatus.loaded);
  });

  test('fails when the board stream fails', () async {
    await cubit.init();
    repository.entries.addError(Exception('permission-denied'));
    await _flush();

    expect(cubit.state.status, HighscoreStatus.error);
    expect(cubit.state.errorMessage, contains('permission-denied'));
  });
}

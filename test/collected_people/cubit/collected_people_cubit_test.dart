import 'package:flutter_and_friends/collected_people/collected_people.dart';
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

CollectedPerson _person({
  String name = 'Johannes Pietilä Löhnn',
  String role = 'Organizer',
  List<String>? urls,
}) {
  return CollectedPerson(
    name: name,
    role: role,
    urls: urls ?? const ['https://x.com/johannes'],
    collectedAt: DateTime(2026, 8, 24, 12),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Storage storage;

  setUp(() {
    storage = _MemoryStorage();
    HydratedBloc.storage = storage;
  });

  group('CollectedPeopleCubit', () {
    test('starts empty', () {
      expect(CollectedPeopleCubit().state.people, isEmpty);
    });

    test('collect appends a new person in collection order', () {
      final cubit = CollectedPeopleCubit()
        ..collect(_person(name: 'Alice'))
        ..collect(_person(name: 'Bob'));

      expect(cubit.state.people.map((p) => p.name), ['Alice', 'Bob']);
    });

    test(
      'collect dedupes on (name, role): returns the existing entry, keeps '
      'original collectedAt, and does not emit',
      () {
        final cubit = CollectedPeopleCubit();
        final first = cubit.collect(_person());
        final stateAfterFirst = cubit.state;
        final again = cubit.collect(_person());

        expect(identical(again, first), isTrue);
        expect(cubit.state.people, hasLength(1));
        expect(identical(cubit.state, stateAfterFirst), isTrue);
      },
    );

    test('same name with a different role is a different person', () {
      final cubit = CollectedPeopleCubit()
        ..collect(_person())
        ..collect(_person(role: 'Speaker'));

      expect(cubit.state.people, hasLength(2));
    });

    test('two nameless badges (empty name and role) dedupe to one entry', () {
      final cubit = CollectedPeopleCubit()
        ..collect(_person(name: '', role: ''))
        ..collect(_person(name: '', role: ''));

      expect(cubit.state.people, hasLength(1));
    });

    test('remove deletes the person from the dex', () {
      final cubit = CollectedPeopleCubit();
      final alice = cubit.collect(_person(name: 'Alice'));
      cubit
        ..collect(_person(name: 'Bob'))
        ..remove(alice);

      expect(cubit.state.people.map((p) => p.name), ['Bob']);
    });

    group('hydration', () {
      test('state round-trips through storage', () async {
        final cubit = CollectedPeopleCubit()
          ..collect(_person(name: 'Alice', role: 'Speaker'))
          ..collect(_person(name: 'Bob'));
        await cubit.close();

        final restored = CollectedPeopleCubit();

        expect(restored.state.people, hasLength(2));
        expect(restored.state.people[0].name, 'Alice');
        expect(restored.state.people[0].role, 'Speaker');
        expect(restored.state.people[0].urls, ['https://x.com/johannes']);
        expect(restored.state.people[0].collectedAt, DateTime(2026, 8, 24, 12));
        expect(restored.state.people[1].name, 'Bob');
      });

      test('empty state restores as empty', () async {
        final cubit = CollectedPeopleCubit();
        await cubit.close();

        expect(CollectedPeopleCubit().state.people, isEmpty);
      });
    });
  });
}

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
  String? installId,
  String? capybaraId,
  String? badgeId,
}) {
  return CollectedPerson(
    name: name,
    role: role,
    urls: urls ?? const ['https://x.com/johannes'],
    collectedAt: DateTime(2026, 8, 24, 12),
    installId: installId,
    capybaraId: capybaraId,
    badgeId: badgeId,
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

    group('dedupe v2 (install ID first)', () {
      test(
        'same installId with a new name updates the entry in place, '
        'keeping original collectedAt and position',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person(name: 'Bob'))
            ..collect(
              _person(name: 'Johannes', installId: 'id-1', capybaraId: 'dj'),
            );

          final updated = cubit.collect(
            _person(
              name: 'Johannes P. Löhnn',
              role: 'Lead Organizer',
              urls: const ['https://johannes.dev'],
              installId: 'id-1',
              capybaraId: 'coder',
            ),
          );

          expect(cubit.state.people, hasLength(2));
          // Position kept: still the second entry.
          final entry = cubit.state.people[1];
          expect(identical(entry, updated), isTrue);
          expect(entry.name, 'Johannes P. Löhnn');
          expect(entry.role, 'Lead Organizer');
          expect(entry.urls, ['https://johannes.dev']);
          expect(entry.capybaraId, 'coder');
          expect(entry.installId, 'id-1');
          // Original collectedAt survives the refresh.
          expect(entry.collectedAt, DateTime(2026, 8, 24, 12));
        },
      );

      test('id-less badges still dedupe on (name, role)', () {
        final cubit = CollectedPeopleCubit();
        final first = cubit.collect(_person());

        final again = cubit.collect(_person());

        expect(identical(again, first), isTrue);
        expect(cubit.state.people, hasLength(1));
      });

      test(
        'same (name, role) but DIFFERENT installIds are two entries',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person(installId: 'id-1'))
            ..collect(_person(installId: 'id-2'));

          expect(cubit.state.people, hasLength(2));
        },
      );

      test(
        'an ID-carrying person does NOT match an ID-less entry with the '
        'same (name, role)',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person())
            ..collect(_person(installId: 'id-1'));

          expect(cubit.state.people, hasLength(2));
        },
      );

      test(
        'an ID-less re-tap matches an ID-carrying entry via the (name, '
        'role) fallback and keeps its installId',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person(installId: 'id-1'));

          final existing = cubit.collect(_person());

          expect(cubit.state.people, hasLength(1));
          expect(existing.installId, 'id-1');
        },
      );
    });

    group('dedupe v3 (badge ID first)', () {
      test(
        'same badgeId updates the entry in place, keeping original '
        'collectedAt and position, even when rewritten by another install',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person(name: 'Bob'))
            ..collect(
              _person(
                name: 'Lukas Klingsbo',
                role: 'SDK Engineer',
                installId: 'install-store',
                capybaraId: 'zen',
                badgeId: 'badge-1',
              ),
            );

          final updated = cubit.collect(
            _person(
              name: 'Lukas',
              role: 'Test',
              urls: const ['https://x.com/spydon'],
              installId: 'install-debug',
              capybaraId: 'coder_face',
              badgeId: 'badge-1',
            ),
          );

          expect(cubit.state.people, hasLength(2));
          final entry = cubit.state.people[1];
          expect(identical(entry, updated), isTrue);
          expect(entry.name, 'Lukas');
          expect(entry.role, 'Test');
          expect(entry.urls, ['https://x.com/spydon']);
          expect(entry.installId, 'install-debug');
          expect(entry.capybaraId, 'coder_face');
          expect(entry.badgeId, 'badge-1');
          expect(entry.collectedAt, DateTime(2026, 8, 24, 12));
        },
      );

      test('same (name, role) on two different badges are two entries', () {
        final cubit = CollectedPeopleCubit()
          ..collect(_person(badgeId: 'badge-1'))
          ..collect(_person(badgeId: 'badge-2'));

        expect(cubit.state.people, hasLength(2));
      });

      test(
        'a badge-carrying person does NOT match an ID-less entry with the '
        'same (name, role)',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person())
            ..collect(_person(badgeId: 'badge-1'));

          expect(cubit.state.people, hasLength(2));
        },
      );

      test(
        'an entry collected before badge IDs matches by installId and '
        'picks up the badgeId',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person(installId: 'id-1'));

          final updated = cubit.collect(
            _person(installId: 'id-1', badgeId: 'badge-1'),
          );

          expect(cubit.state.people, hasLength(1));
          expect(updated.badgeId, 'badge-1');
          expect(cubit.state.people.single.badgeId, 'badge-1');
        },
      );

      test(
        'a replacement badge with the same installId updates the badgeId',
        () {
          final cubit = CollectedPeopleCubit()
            ..collect(_person(installId: 'id-1', badgeId: 'badge-1'))
            ..collect(_person(installId: 'id-1', badgeId: 'badge-2'));

          expect(cubit.state.people, hasLength(1));
          expect(cubit.state.people.single.badgeId, 'badge-2');
        },
      );

      test('badgeId survives hydration', () async {
        final cubit = CollectedPeopleCubit()
          ..collect(_person(badgeId: 'badge-1'));
        await cubit.close();

        expect(CollectedPeopleCubit().state.people.single.badgeId, 'badge-1');
      });
    });

    group('hydration', () {
      test('state round-trips through storage', () async {
        final cubit = CollectedPeopleCubit()
          ..collect(_person(name: 'Alice', role: 'Speaker'))
          ..collect(
            _person(name: 'Bob', installId: 'id-b', capybaraId: 'dj'),
          );
        await cubit.close();

        final restored = CollectedPeopleCubit();

        expect(restored.state.people, hasLength(2));
        expect(restored.state.people[0].name, 'Alice');
        expect(restored.state.people[0].role, 'Speaker');
        expect(restored.state.people[0].urls, ['https://x.com/johannes']);
        expect(
          restored.state.people[0].collectedAt,
          DateTime(2026, 8, 24, 12),
        );
        expect(restored.state.people[0].installId, isNull);
        expect(restored.state.people[1].name, 'Bob');
        expect(restored.state.people[1].installId, 'id-b');
        expect(restored.state.people[1].capybaraId, 'dj');
      });

      test('empty state restores as empty', () async {
        final cubit = CollectedPeopleCubit();
        await cubit.close();

        expect(CollectedPeopleCubit().state.people, isEmpty);
      });
    });
  });
}

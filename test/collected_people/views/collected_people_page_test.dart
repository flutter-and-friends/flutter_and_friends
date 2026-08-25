import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
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

CollectedPerson _person({
  String name = 'Johannes Pietilä Löhnn',
  String role = 'Organizer',
  List<String> urls = const ['https://x.com/johannes'],
  String? installId,
  String? capybaraId,
}) {
  return CollectedPerson(
    name: name,
    role: role,
    urls: urls,
    collectedAt: DateTime(2026, 8, 24, 12),
    installId: installId,
    capybaraId: capybaraId,
  );
}

Widget _subject(CollectedPeopleCubit cubit) {
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: const CollectedPeopleView(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
  });

  group('CollectedPeopleView', () {
    testWidgets('shows the empty state when no one is collected', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(CollectedPeopleCubit()));

      expect(find.text('No one collected yet'), findsOneWidget);
      expect(find.byIcon(Icons.contact_page), findsOneWidget);
      expect(find.byIcon(Icons.nfc), findsOneWidget);
    });

    testWidgets('lists collected people with name and role', (tester) async {
      final cubit = CollectedPeopleCubit()
        ..collect(_person())
        ..collect(_person(name: 'Ada Lovelace', role: 'Speaker', urls: []));
      await tester.pumpWidget(_subject(cubit));

      expect(find.text('Johannes Pietilä Löhnn'), findsOneWidget);
      expect(find.text('Organizer'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Speaker'), findsOneWidget);
    });

    testWidgets('nameless entry falls back to "Unknown"', (tester) async {
      final cubit = CollectedPeopleCubit()
        ..collect(_person(name: '', role: '', urls: []));
      await tester.pumpWidget(_subject(cubit));

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('tapping an entry opens its links sheet', (tester) async {
      final cubit = CollectedPeopleCubit()..collect(_person());
      await tester.pumpWidget(_subject(cubit));

      await tester.tap(find.text('Johannes Pietilä Löhnn'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('https://x.com/johannes'), findsOneWidget);
    });

    testWidgets('long-press offers removal, removing on confirm', (
      tester,
    ) async {
      final cubit = CollectedPeopleCubit()..collect(_person());
      await tester.pumpWidget(_subject(cubit));

      await tester.longPress(find.text('Johannes Pietilä Löhnn'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Johannes Pietilä Löhnn?'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(cubit.state.people, isEmpty);
      expect(find.text('No one collected yet'), findsOneWidget);
    });

    group('capybara avatar', () {
      testWidgets(
        'shows the bundled capybara image when capybaraId is set',
        (tester) async {
          final cubit = CollectedPeopleCubit()
            ..collect(_person(capybaraId: 'coffee_mode'));
          await tester.pumpWidget(_subject(cubit));

          final avatar = tester.widget<CircleAvatar>(
            find.byType(CircleAvatar),
          );
          final image = avatar.backgroundImage! as AssetImage;
          expect(
            image.assetName,
            'assets/badge_templates/capybaras/coffee_mode.jpeg',
          );
          // Image replaces the initial-letter child.
          expect(avatar.child, isNull);
        },
      );

      testWidgets('falls back to the initial letter without a capybaraId',
          (tester) async {
        final cubit = CollectedPeopleCubit()..collect(_person());
        await tester.pumpWidget(_subject(cubit));

        final avatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(avatar.backgroundImage, isNull);
        expect(find.text('J'), findsOneWidget);
      });

      testWidgets('falls back for an unknown capybaraId', (tester) async {
        final cubit = CollectedPeopleCubit()
          ..collect(_person(capybaraId: 'not_a_real_capybara'));
        await tester.pumpWidget(_subject(cubit));

        final avatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(avatar.backgroundImage, isNull);
        expect(find.text('J'), findsOneWidget);
      });
    });
  });

  group('capybaraAssetFor', () {
    test('resolves a known capybara name to its asset path', () {
      expect(
        capybaraAssetFor('coffee_mode'),
        'assets/badge_templates/capybaras/coffee_mode.jpeg',
      );
    });

    test('returns null for null, empty, and unknown ids', () {
      expect(capybaraAssetFor(null), isNull);
      expect(capybaraAssetFor(''), isNull);
      expect(capybaraAssetFor('missing'), isNull);
      // Path traversal never escapes the lookup: the candidate must exist
      // in kCapybaraAssets.
      expect(capybaraAssetFor('../logo'), isNull);
    });
  });
}

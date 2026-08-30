import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/collected_people/collected_people.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_badge/friends_badge.dart' show BadgePerson;
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
  String? badgeId,
}) {
  return CollectedPerson(
    name: name,
    role: role,
    urls: urls,
    collectedAt: DateTime(2026, 8, 24, 12),
    installId: installId,
    capybaraId: capybaraId,
    badgeId: badgeId,
  );
}

/// A collector whose session is driven by the test through its
/// [_FakeSessionController]: the collected callback is captured so a tap can
/// be simulated, and the controller ends the session.
class _FakeBadgeCollector extends BadgeCollector {
  const _FakeBadgeCollector(this.controller);

  final _FakeSessionController controller;

  @override
  Future<BadgeCollectSession> start({
    required void Function(BadgePerson person, String? badgeId) onCollected,
    String alertMessageIos = '',
    bool continuous = false,
  }) async {
    controller
      ..onCollected = onCollected
      ..continuous = continuous
      ..startCalls += 1;
    return BadgeCollectSession(
      result: controller.completer.future,
      onCancel: () async {
        controller.cancelCalls += 1;
        if (!controller.completer.isCompleted) {
          controller.completer.complete(BadgeCollectResult.cancelled);
        }
      },
    );
  }
}

class _FakeSessionController {
  final completer = Completer<BadgeCollectResult>();
  void Function(BadgePerson person, String? badgeId)? onCollected;
  bool? continuous;
  int startCalls = 0;
  int cancelCalls = 0;

  void tap(BadgePerson person, {String? badgeId = '1dd4ad1958'}) {
    onCollected!(person, badgeId);
    if (continuous != true) completer.complete(BadgeCollectResult.collected);
  }

  void finish(BadgeCollectResult result) => completer.complete(result);
}

const _badgePerson = BadgePerson(
  name: 'Ada Lovelace',
  role: 'Speaker',
  urls: ['https://x.com/ada'],
  primaryUri: null,
  installId: 'install-1',
  capybaraId: null,
);

Widget _subject(
  CollectedPeopleCubit cubit, {
  BadgeCollector collector = const BadgeCollector(),
  BadgeListenerCubit? listener,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        if (listener != null) BlocProvider.value(value: listener),
      ],
      child: CollectedPeopleView(collector: collector),
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

    group('collecting a badge', () {
      testWidgets('keeps listening until a badge is tapped', (tester) async {
        final controller = _FakeSessionController();
        final cubit = CollectedPeopleCubit();
        await tester.pumpWidget(
          _subject(cubit, collector: _FakeBadgeCollector(controller)),
        );

        await tester.tap(find.byIcon(Icons.nfc));
        await tester.pumpAndSettle();

        expect(controller.startCalls, 1);
        expect(find.byType(CollectBadgeDialog), findsOneWidget);
        expect(find.text('No badge tapped'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);

        controller.tap(_badgePerson);
        await tester.pumpAndSettle();

        expect(find.byType(CollectBadgeDialog), findsNothing);
        expect(find.text('Collected Ada Lovelace ✓'), findsOneWidget);
        expect(cubit.state.people.single.name, 'Ada Lovelace');
        expect(cubit.state.people.single.badgeId, '1dd4ad1958');
        expect(find.text('Ada Lovelace'), findsOneWidget);
      });

      testWidgets('tapping the same badge again updates the entry', (
        tester,
      ) async {
        final cubit = CollectedPeopleCubit()
          ..collect(
            _person(name: 'Ada', role: 'Dev', badgeId: '1dd4ad1958'),
          );
        final controller = _FakeSessionController();
        await tester.pumpWidget(
          _subject(cubit, collector: _FakeBadgeCollector(controller)),
        );

        await tester.tap(find.byIcon(Icons.nfc));
        await tester.pumpAndSettle();
        controller.tap(_badgePerson);
        await tester.pumpAndSettle();

        expect(find.text('Updated Ada Lovelace ✓'), findsOneWidget);
        expect(cubit.state.people.single.name, 'Ada Lovelace');
        expect(cubit.state.people.single.role, 'Speaker');
        expect(find.text('Ada'), findsNothing);
      });

      testWidgets('cancel ends the session without a message', (
        tester,
      ) async {
        final controller = _FakeSessionController();
        await tester.pumpWidget(
          _subject(
            CollectedPeopleCubit(),
            collector: _FakeBadgeCollector(controller),
          ),
        );

        await tester.tap(find.byIcon(Icons.nfc));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(controller.cancelCalls, greaterThanOrEqualTo(1));
        expect(await controller.completer.future, BadgeCollectResult.cancelled);
        expect(find.byType(CollectBadgeDialog), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('a foreign tag closes the dialog and explains', (
        tester,
      ) async {
        final controller = _FakeSessionController();
        await tester.pumpWidget(
          _subject(
            CollectedPeopleCubit(),
            collector: _FakeBadgeCollector(controller),
          ),
        );

        await tester.tap(find.byIcon(Icons.nfc));
        await tester.pumpAndSettle();
        controller.finish(BadgeCollectResult.notABadge);
        await tester.pumpAndSettle();

        expect(find.byType(CollectBadgeDialog), findsNothing);
        expect(
          find.text('That was not a Friends badge, try again'),
          findsOneWidget,
        );
      });
    });

    group('with the app-wide listener active', () {
      testWidgets('hides the collect button and shows the hint', (
        tester,
      ) async {
        final controller = _FakeSessionController();
        final cubit = CollectedPeopleCubit();
        final listener = BadgeListenerCubit(
          people: cubit,
          collector: _FakeBadgeCollector(controller),
          enabled: true,
        );
        addTearDown(listener.close);
        await listener.start();
        await tester.pumpWidget(_subject(cubit, listener: listener));

        expect(controller.continuous, isTrue);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.byType(ListeningBanner), findsOneWidget);
        expect(
          find.text("Hold your phone near someone's badge to collect them"),
          findsOneWidget,
        );

        controller.tap(_badgePerson);
        await tester.pumpAndSettle();

        expect(find.text('Ada Lovelace'), findsOneWidget);
        expect(find.byType(ListeningBanner), findsOneWidget);
      });

      testWidgets('keeps the collect button while not listening', (
        tester,
      ) async {
        final cubit = CollectedPeopleCubit();
        final listener = BadgeListenerCubit(
          people: cubit,
          collector: _FakeBadgeCollector(_FakeSessionController()),
          enabled: false,
        );
        addTearDown(listener.close);
        await tester.pumpWidget(_subject(cubit, listener: listener));

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(ListeningBanner), findsNothing);
      });
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

      testWidgets('falls back to the initial letter without a capybaraId', (
        tester,
      ) async {
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

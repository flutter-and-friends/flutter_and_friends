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

class _FakeBadgeCollector extends BadgeCollector {
  const _FakeBadgeCollector(this.controller);

  final _FakeSessionController controller;

  @override
  Future<BadgeCollectSession> start({
    required void Function(BadgePerson person, String? badgeId) onCollected,
    String alertMessageIos = '',
    bool continuous = false,
  }) async {
    controller.onCollected = onCollected;
    return BadgeCollectSession(
      result: Completer<BadgeCollectResult>().future,
      onCancel: () async {},
    );
  }
}

class _FakeSessionController {
  void Function(BadgePerson person, String? badgeId)? onCollected;

  void tap(BadgePerson person) => onCollected!(person, 'badge-1');
}

const _ada = BadgePerson(
  name: 'Ada Lovelace',
  role: 'Speaker',
  urls: [],
  primaryUri: null,
  installId: 'install-ada',
  capybaraId: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSessionController controller;
  late CollectedPeopleCubit people;
  late BadgeListenerCubit listener;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() async {
    HydratedBloc.storage = _MemoryStorage();
    controller = _FakeSessionController();
    people = CollectedPeopleCubit();
    listener = BadgeListenerCubit(
      people: people,
      collector: _FakeBadgeCollector(controller),
      ownInstallId: () => 'install-me',
      enabled: true,
    );
    addTearDown(listener.close);
    await listener.start();
    navigatorKey = GlobalKey<NavigatorState>();
  });

  Widget app({Widget home = const Scaffold(body: Text('Home'))}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: people),
        BlocProvider.value(value: listener),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: home,
        builder: (context, child) => BadgeCollectedListener(
          navigatorKey: navigatorKey,
          child: child!,
        ),
      ),
    );
  }

  group('BadgeCollectedListener', () {
    testWidgets('a tap anywhere announces and opens Collected People', (
      tester,
    ) async {
      await tester.pumpWidget(app());

      controller.tap(_ada);
      await tester.pumpAndSettle();

      expect(find.text('Collected Ada Lovelace ✓'), findsOneWidget);
      expect(find.byType(CollectedPeopleView), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('does not stack a second Collected People page', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      navigatorKey.currentState!.push(CollectedPeoplePage.route());
      await tester.pumpAndSettle();

      controller.tap(_ada);
      await tester.pumpAndSettle();
      controller.tap(_ada);
      await tester.pumpAndSettle();

      expect(find.byType(CollectedPeopleView), findsOneWidget);
      expect(find.text('Updated Ada Lovelace ✓'), findsOneWidget);
    });

    testWidgets("one's own badge only shows a message", (tester) async {
      await tester.pumpWidget(app());

      controller.tap(
        const BadgePerson(
          name: 'Me',
          role: 'Organizer',
          urls: [],
          primaryUri: null,
          installId: 'install-me',
          capybaraId: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("That's your own badge"), findsOneWidget);
      expect(find.byType(CollectedPeopleView), findsNothing);
      expect(people.state.people, isEmpty);
    });
  });
}

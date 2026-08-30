import 'dart:async';

import 'package:flutter_and_friends/collected_people/collected_people.dart';
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
    if (controller.failWith != null) throw controller.failWith!;
    final completer = Completer<BadgeCollectResult>();
    controller
      ..onCollected = onCollected
      ..continuous = continuous
      ..startCalls += 1
      ..completer = completer;
    return BadgeCollectSession(
      result: completer.future,
      onCancel: () async {
        controller.cancelCalls += 1;
        if (!completer.isCompleted) {
          completer.complete(BadgeCollectResult.cancelled);
        }
      },
    );
  }
}

class _FakeSessionController {
  Completer<BadgeCollectResult>? completer;
  void Function(BadgePerson person, String? badgeId)? onCollected;
  bool? continuous;
  int startCalls = 0;
  int cancelCalls = 0;
  Error? failWith;

  void tap(BadgePerson person, {String badgeId = 'badge-1'}) {
    onCollected!(person, badgeId);
  }
}

const _ada = BadgePerson(
  name: 'Ada Lovelace',
  role: 'Speaker',
  urls: ['https://x.com/ada'],
  primaryUri: null,
  installId: 'install-1',
  capybaraId: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSessionController controller;
  late CollectedPeopleCubit people;

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
    controller = _FakeSessionController();
    people = CollectedPeopleCubit();
  });

  BadgeListenerCubit listener({bool enabled = true, String? ownInstallId}) {
    final cubit = BadgeListenerCubit(
      people: people,
      collector: _FakeBadgeCollector(controller),
      ownInstallId: () => ownInstallId,
      enabled: enabled,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('BadgeListenerCubit', () {
    test('start holds a continuous session', () async {
      final cubit = listener();

      await cubit.start();

      expect(cubit.state.listening, isTrue);
      expect(controller.continuous, isTrue);
      expect(controller.startCalls, 1);
    });

    test('does nothing when disabled', () async {
      final cubit = listener(enabled: false);

      await cubit.start();

      expect(cubit.state.listening, isFalse);
      expect(controller.startCalls, 0);
    });

    test('a tap collects into the dex and announces it', () async {
      final cubit = listener();
      await cubit.start();

      controller.tap(_ada);

      expect(people.state.people.single.name, 'Ada Lovelace');
      expect(people.state.people.single.badgeId, 'badge-1');
      final first = cubit.state.lastCollected!;
      expect(first.isNew, isTrue);
      expect(first.sequence, 1);
      expect(cubit.state.listening, isTrue);

      controller.tap(_ada);

      expect(people.state.people, hasLength(1));
      final second = cubit.state.lastCollected!;
      expect(second.isNew, isFalse);
      expect(second.sequence, 2);
    });

    test("one's own badge is announced but not collected", () async {
      final cubit = listener(ownInstallId: 'install-1');
      await cubit.start();

      controller.tap(_ada);

      expect(people.state.people, isEmpty);
      final own = cubit.state.lastCollected!;
      expect(own.isOwn, isTrue);
      expect(own.person.name, 'Ada Lovelace');
    });

    test('stop cancels the session', () async {
      final cubit = listener();
      await cubit.start();

      await cubit.stop();

      expect(controller.cancelCalls, 1);
      expect(cubit.state.listening, isFalse);
    });

    test('rearm replaces the session', () async {
      final cubit = listener();
      await cubit.start();

      await cubit.rearm();

      expect(controller.cancelCalls, 1);
      expect(controller.startCalls, 2);
      expect(cubit.state.listening, isTrue);
    });

    test('reports not listening when NFC is unavailable', () async {
      controller.failWith = StateError('NFC is not available');
      final cubit = listener();

      await cubit.start();

      expect(cubit.state.listening, isFalse);
    });

    test('goes idle when the session ends on its own', () async {
      final cubit = listener();
      await cubit.start();

      controller.completer!.complete(BadgeCollectResult.cancelled);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.listening, isFalse);
    });
  });
}

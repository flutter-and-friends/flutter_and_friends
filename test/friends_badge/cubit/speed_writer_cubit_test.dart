import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A small solid-color JPEG standing in for every capybara asset.
Future<Uint8List> _fakeAsset(String assetPath) async {
  final source = img.Image(width: 64, height: 64)
    ..clear(img.ColorRgb8(200, 30, 30));
  return Uint8List.fromList(img.encodeJpg(source));
}

const _roster =
    'name,role,email\n'
    'Ada Lovelace,Speaker,ada@example.com\n'
    'Charles Babbage,Attendee,\n'
    'Grace Hopper,Speaker,grace@example.com\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SpeedWriterCubit subject({Random? random}) {
    var badgeCount = 0;
    final cubit = SpeedWriterCubit(
      random: random ?? Random(1),
      loadAsset: _fakeAsset,
      generateBadgeId: () => 'badge-${++badgeCount}',
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('SpeedWriterCubit', () {
    test('starts empty', () {
      final cubit = subject();
      expect(cubit.state.status, SpeedWriterStatus.empty);
      expect(cubit.state.current, isNull);
    });

    test('loading a roster composes the first person', () async {
      final cubit = subject();

      await cubit.loadRoster(_roster);

      final state = cubit.state;
      expect(state.status, SpeedWriterStatus.ready);
      expect(state.entries, hasLength(3));
      expect(state.index, 0);
      expect(state.current?.name, 'Ada Lovelace');
      expect(state.badge, isNotNull);
      expect(state.badge!.previewPng, isNotEmpty);
      expect(state.badge!.peekPngs, isEmpty);
      expect(state.badgeId, 'badge-1');
      expect(kCapybaraAssets, contains(state.asset));
      expect(state.capybaraId, isNotNull);
    });

    test(
      'a roster without people reports an error and keeps the state',
      () async {
        final cubit = subject();

        await cubit.loadRoster('name,role\n');

        expect(cubit.state.status, SpeedWriterStatus.empty);
        expect(cubit.state.errorCount, 1);
        expect(cubit.state.error, contains('No people found'));
      },
    );

    test('marking a badge written advances to the next person', () async {
      final cubit = subject();
      await cubit.loadRoster(_roster);

      await cubit.markWritten();

      final state = cubit.state;
      expect(state.status, SpeedWriterStatus.ready);
      expect(state.index, 1);
      expect(state.current?.name, 'Charles Babbage');
      expect(state.writtenIndices, {0});
      expect(state.badgeId, 'badge-2');
      expect(state.badge, isNotNull);
    });

    test('marking the last badge written finishes the roster', () async {
      final cubit = subject();
      await cubit.loadRoster(_roster);

      await cubit.markWritten();
      await cubit.markWritten();
      await cubit.markWritten();

      expect(cubit.state.status, SpeedWriterStatus.done);
      expect(cubit.state.writtenIndices, {0, 1, 2});
      expect(cubit.state.hasNext, isFalse);
    });

    test('skipping and going back do not count as written', () async {
      final cubit = subject();
      await cubit.loadRoster(_roster);

      await cubit.next();
      expect(cubit.state.current?.name, 'Charles Babbage');
      await cubit.previous();
      expect(cubit.state.current?.name, 'Ada Lovelace');

      expect(cubit.state.writtenIndices, isEmpty);
      expect(cubit.state.status, SpeedWriterStatus.ready);
    });

    test('rerolling draws a new badge ID and recomposes', () async {
      final cubit = subject();
      await cubit.loadRoster(_roster);
      final before = cubit.state;

      await cubit.reroll();

      expect(cubit.state.index, before.index);
      expect(cubit.state.badgeId, isNot(before.badgeId));
      expect(cubit.state.badge, isNotNull);
      expect(cubit.state.status, SpeedWriterStatus.ready);
    });

    test('the look is drawn from the injected random source', () async {
      final a = subject(random: Random(7));
      final b = subject(random: Random(7));

      await a.loadRoster(_roster);
      await b.loadRoster(_roster);

      expect(a.state.font, b.state.font);
      expect(a.state.asset, b.state.asset);
    });
  });
}

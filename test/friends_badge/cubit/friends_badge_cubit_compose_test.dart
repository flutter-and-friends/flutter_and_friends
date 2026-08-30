import 'dart:io';

import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:image/image.dart' as img;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
  });

  group('FriendsBadgeCubit isolate compose (end-to-end)', () {
    test(
      'picking an image composes a badge through the background isolate',
      () async {
        final identity = BadgeIdentityCubit();
        addTearDown(identity.close);
        final cubit = FriendsBadgeCubit(identity: identity);
        addTearDown(cubit.close);

        // Build a small solid-color JPEG on the fly.
        final source = img.Image(width: 64, height: 64)
          ..clear(img.ColorRgb8(200, 30, 30));
        final file = File(
          '${Directory.systemTemp.path}/badge_cubit_test.jpg',
        )..writeAsBytesSync(img.encodeJpg(source));
        addTearDown(file.deleteSync);

        await cubit.updateImage(file);

        expect(cubit.state.status, FriendsBadgeStatus.loaded);
        expect(cubit.state.badge, isNotNull);
        // The previews are encoded by the isolate, not by the widgets.
        final badge = cubit.state.badge!;
        expect(badge.previewPng, isNotEmpty);
        expect(
          badge.peekPngs.keys,
          unorderedEquals(BadgeImage.allSupportedKernels),
        );

        final previous = badge.previewPng;
        await cubit.updateDitherKernel(img.DitherKernel.floydSteinberg);

        expect(
          cubit.state.badge!.ditherKernel,
          img.DitherKernel.floydSteinberg,
        );
        expect(identical(cubit.state.badge!.previewPng, previous), isFalse);
      },
      // TextPainter layout inside renderPng needs the test binding's font
      // pipeline; google_fonts styles fall back to default fonts offline.
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'back-to-back recomposes settle on the latest state',
      () async {
        final identity = BadgeIdentityCubit();
        addTearDown(identity.close);
        final cubit = FriendsBadgeCubit(identity: identity);
        addTearDown(cubit.close);

        final source = img.Image(width: 64, height: 64)
          ..clear(img.ColorRgb8(30, 30, 200));
        final file = File(
          '${Directory.systemTemp.path}/badge_cubit_test2.jpg',
        )..writeAsBytesSync(img.encodeJpg(source));
        addTearDown(file.deleteSync);

        await cubit.updateImage(file);
        await cubit.updateTemplate(BadgeTemplate.classic);

        // Subscribe before firing so a fast emit can't race past us.
        final settled = cubit.stream.firstWhere(
          (s) => s.badge != null && s.name == 'ABC',
        );

        // Fire several recomposes without awaiting between them — the
        // ReplaceBackpressureStrategy drops the stale ones.
        final pending = <Future<void>>[
          cubit.updateName('A'),
          cubit.updateName('AB'),
          cubit.updateName('ABC'),
        ];
        await Future.wait(pending);
        // Let any in-flight isolate job land.
        await settled;

        expect(cubit.state.name, 'ABC');
        expect(cubit.state.badge, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}

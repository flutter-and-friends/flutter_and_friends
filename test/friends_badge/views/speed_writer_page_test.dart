import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Future<Uint8List> _fakeAsset(String assetPath) async {
  final source = img.Image(width: 64, height: 64)
    ..clear(img.ColorRgb8(30, 30, 200));
  return Uint8List.fromList(img.encodeJpg(source));
}

Widget _subject(SpeedWriterCubit cubit) {
  return MaterialApp(
    home: BlocProvider.value(value: cubit, child: const SpeedWriterView()),
  );
}

void main() {
  SpeedWriterCubit subject() {
    final cubit = SpeedWriterCubit(random: Random(1), loadAsset: _fakeAsset);
    addTearDown(cubit.close);
    return cubit;
  }

  group('SpeedWriterView', () {
    testWidgets('asks for a CSV when no roster is loaded', (tester) async {
      await tester.pumpWidget(_subject(subject()));

      expect(find.text('Write badges from a CSV'), findsOneWidget);
      expect(find.byType(PickRosterButton), findsOneWidget);
      expect(find.byType(WriteToBadgeButton), findsNothing);
      expect(find.text('Previous'), findsNothing);
    });

    testWidgets('shows the current person, progress and write button', (
      tester,
    ) async {
      final cubit = subject();
      await tester.runAsync(
        () => cubit.loadRoster(
          'name,role,email\nAda Lovelace,Speaker,ada@example.com\nBob,Attendee',
        ),
      );
      await tester.pumpWidget(_subject(cubit));

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Speaker'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('1 of 2 · 0 written'), findsOneWidget);
      expect(find.text(cubit.state.font.label), findsOneWidget);
      expect(find.text(cubit.state.capybaraId!), findsOneWidget);
      expect(find.byType(WriteToBadgeButton), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      final previous = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Previous'),
      );
      expect(previous.onPressed, isNull);
      final skip = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Skip'),
      );
      expect(skip.onPressed, isNotNull);
    });

    testWidgets('shows the summary once every badge is written', (
      tester,
    ) async {
      final cubit = subject();
      await tester.runAsync(() async {
        await cubit.loadRoster('Ada,Speaker');
        await cubit.markWritten();
      });
      await tester.pumpWidget(_subject(cubit));

      expect(find.text('1 of 1 badges written'), findsOneWidget);
      expect(find.byType(WriteToBadgeButton), findsNothing);
      expect(find.byType(PickRosterButton), findsNWidgets(2));
    });
  });
}

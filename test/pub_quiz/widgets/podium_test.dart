import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

const _entries = [
  ScoreboardEntry(
    teamId: 'a',
    name: 'A rather long team name',
    from: 50,
    to: 54,
    isMine: true,
  ),
  ScoreboardEntry(teamId: 'b', name: 'Beta', from: 30, to: 31, isMine: false),
  ScoreboardEntry(teamId: 'c', name: 'Gamma', from: 20, to: 20, isMine: false),
];

Widget _subject() {
  return const MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Podium(entries: _entries),
          ),
          Expanded(
            child: AnimatedScoreboard(entries: _entries, animate: false),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('fits the labels above the steps on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('54 pts'), findsOneWidget);
    expect(find.text('31 pts'), findsOneWidget);
    expect(find.text('20 pts'), findsOneWidget);

    final podium = tester.getRect(find.byType(Podium));
    final winner = tester.getRect(find.text('54 pts'));
    expect(winner.top, greaterThanOrEqualTo(podium.top));
  });
}

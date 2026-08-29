import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

const _awardA = PubQuizAward(
  questionId: 'q1',
  points: 2,
  correct: true,
  choice: 0,
);

const _entries = [
  ScoreboardEntry(
    teamId: 'a',
    name: 'Alpha',
    from: 5,
    to: 9,
    isMine: true,
    award: _awardA,
  ),
  ScoreboardEntry(teamId: 'b', name: 'Beta', from: 7, to: 7, isMine: false),
];

Widget _subject({bool animate = true}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimatedScoreboard(entries: _entries, animate: animate),
    ),
  );
}

double _top(WidgetTester tester, String name) {
  return tester.getTopLeft(find.text(name)).dy;
}

void main() {
  testWidgets('starts in the old order and settles in the new one', (
    tester,
  ) async {
    await tester.pumpWidget(_subject());

    expect(_top(tester, 'Beta'), lessThan(_top(tester, 'Alpha')));
    expect(find.text('5'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(_top(tester, 'Alpha'), lessThan(_top(tester, 'Beta')));
    expect(find.text('9'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('draws the final state at once when not animating', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(animate: false));

    expect(_top(tester, 'Alpha'), lessThan(_top(tester, 'Beta')));
    expect(find.text('9'), findsOneWidget);
  });
}

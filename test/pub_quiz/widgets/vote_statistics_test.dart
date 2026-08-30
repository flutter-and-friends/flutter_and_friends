import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

const _question = PubQuizQuestion(
  id: 'q1',
  index: 0,
  text: 'Which one?',
  options: ['Alpha', 'Beta', 'Gamma', 'Delta'],
  correctIndex: 1,
  answerCounts: [1, 3, 0, 2],
);

Widget _subject({bool animate = true}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: VoteStatistics(
              question: _question,
              myChoice: 0,
              result: const Text('Result'),
              animate: animate,
            ),
          ),
        ],
      ),
    ),
  );
}

double _resultOpacity(WidgetTester tester) {
  return tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Result'),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;
}

void main() {
  testWidgets('grows the bars in one by one before showing the answer', (
    tester,
  ) async {
    await tester.pumpWidget(_subject());

    expect(find.text('0'), findsNWidgets(4));
    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(_resultOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('3'), findsNothing);
    expect(find.byIcon(Icons.cancel), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(_resultOpacity(tester), 1);
  });

  testWidgets('draws the final state at once when not animating', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(animate: false));

    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(_resultOpacity(tester), 1);
  });
}

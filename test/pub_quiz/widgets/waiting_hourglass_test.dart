import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get _rotation => find
    .descendant(
      of: find.byType(WaitingHourglass),
      matching: find.byType(Transform),
    )
    .first;

void main() {
  testWidgets('runs the sand through and flips the glass', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WaitingHourglass())),
    );

    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    var rotate = tester.widget<Transform>(_rotation);
    expect(rotate.transform, Matrix4.identity());

    await tester.pump(const Duration(milliseconds: 700));
    rotate = tester.widget<Transform>(_rotation);
    expect(rotate.transform, isNot(Matrix4.identity()));

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get _rotation => find
    .descendant(
      of: find.byType(WaitingHourglass),
      matching: find.byType(Transform),
    )
    .first;

HourglassPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(WaitingHourglass),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as HourglassPainter;
}

void main() {
  testWidgets('runs the sand through, then flips back to the start', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WaitingHourglass())),
    );

    expect(_painter(tester).sand, 0);
    expect(tester.widget<Transform>(_rotation).transform, Matrix4.identity());

    await tester.pump(const Duration(milliseconds: 1080));
    expect(_painter(tester).sand, closeTo(0.5, 0.01));
    expect(tester.widget<Transform>(_rotation).transform, Matrix4.identity());

    await tester.pump(const Duration(milliseconds: 1500));
    expect(_painter(tester).sand, 1);
    expect(
      tester.widget<Transform>(_rotation).transform,
      isNot(Matrix4.identity()),
    );

    await tester.pump(const Duration(milliseconds: 420));
    expect(_painter(tester).sand, 0);
    expect(tester.widget<Transform>(_rotation).transform, Matrix4.identity());
  });
}

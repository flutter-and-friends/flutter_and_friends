import 'package:flutter/material.dart';
import 'package:flutter_and_friends/pub_quiz/pub_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _subject(PubQuizConnection connection) {
  return MaterialApp(
    home: Scaffold(body: ConnectionBanner(connection: connection)),
  );
}

void main() {
  testWidgets('shows nothing while connected', (tester) async {
    await tester.pumpWidget(_subject(PubQuizConnection.connected));

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('says it is connecting before the first server round trip', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(PubQuizConnection.connecting));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Connecting to the quiz…'), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);
  });

  testWidgets('says the connection was lost once it drops', (tester) async {
    await tester.pumpWidget(_subject(PubQuizConnection.reconnecting));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Connection lost. Reconnecting…'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });
}

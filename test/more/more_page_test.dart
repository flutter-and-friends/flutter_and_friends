import 'package:flutter/material.dart';
import 'package:flutter_and_friends/more/view/more_page.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _subject() {
  return MaterialApp(
    theme: lightTheme,
    home: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        MoreItem(
          icon: Icons.question_answer,
          title: 'Q&A',
          subtitle: 'Ask the panel a question',
          onTap: () {},
        ),
        MoreItem(
          icon: Icons.contact_page,
          title: 'Collected People',
          subtitle: 'People you met, tap a badge to collect',
          onTap: () {},
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('keeps the chevron and icon on the same inset on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MoreItem), findsNWidgets(2));

    final chevron = tester.getRect(find.byIcon(Icons.chevron_right).first);
    final icon = tester.getRect(find.byIcon(Icons.question_answer));
    expect(320 - chevron.right, icon.left);
    expect(icon.left, 28);

    final subtitle = tester.getRect(find.text('Ask the panel a question'));
    expect(subtitle.right, lessThan(chevron.left));
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoreItem(
            icon: Icons.badge_outlined,
            title: 'Friends Badge',
            subtitle: 'Customize your badge',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Friends Badge'));

    expect(tapped, isTrue);
  });

  group('onHold', () {
    Widget subject({
      required VoidCallback onTap,
      required VoidCallback onHold,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MoreItem(
            icon: Icons.badge_outlined,
            title: 'Friends Badge',
            subtitle: 'Customize your badge',
            onTap: onTap,
            onHold: onHold,
          ),
        ),
      );
    }

    testWidgets('fires after holding for five seconds and swallows the tap', (
      tester,
    ) async {
      var tapped = false;
      var held = false;
      await tester.pumpWidget(
        subject(onTap: () => tapped = true, onHold: () => held = true),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Friends Badge')),
      );
      await tester.pump(MoreItem.holdDuration - const Duration(seconds: 1));
      expect(held, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(held, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });

    testWidgets('a short press still taps', (tester) async {
      var tapped = false;
      var held = false;
      await tester.pumpWidget(
        subject(onTap: () => tapped = true, onHold: () => held = true),
      );

      await tester.tap(find.text('Friends Badge'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(held, isFalse);
    });
  });
}

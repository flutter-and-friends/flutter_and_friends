import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BadgeTemplate', () {
    test('imageOnly is the only template without text fields', () {
      expect(BadgeTemplate.imageOnly.usesText, isFalse);
      for (final t in BadgeTemplate.values.where(
        (t) => t != BadgeTemplate.imageOnly,
      )) {
        expect(t.usesText, isTrue, reason: '${t.name} should render text');
      }
    });

    test('every template has a non-empty label', () {
      for (final t in BadgeTemplate.values) {
        expect(t.label, isNotEmpty);
      }
    });
  });

  group('BadgeFont', () {
    test('every font has a non-empty label', () {
      for (final f in BadgeFont.values) {
        expect(f.label, isNotEmpty);
      }
    });
  });

  group('kCapybaraAssets', () {
    test('bundles the 32 documented capybaras', () {
      expect(kCapybaraAssets, hasLength(32));
    });

    test('every path lives under the capybaras asset folder', () {
      for (final path in kCapybaraAssets) {
        expect(
          path,
          startsWith('assets/badge_templates/capybaras/'),
          reason: path,
        );
        expect(path, endsWith('.jpeg'), reason: path);
      }
    });

    test('contains no duplicates', () {
      expect(kCapybaraAssets.toSet(), hasLength(kCapybaraAssets.length));
    });
  });

  group('FriendsBadgeState', () {
    test('starts on imageOnly with empty text and a default font', () {
      const state = FriendsBadgeState();
      expect(state.template, BadgeTemplate.imageOnly);
      expect(state.name, isEmpty);
      expect(state.role, isEmpty);
      expect(state.url, isEmpty);
      expect(state.font, BadgeFont.display);
      expect(state.status, FriendsBadgeStatus.idle);
      expect(state.badge, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const original = FriendsBadgeState(
        template: BadgeTemplate.classic,
        name: 'Johannes',
        role: 'Organizer',
        font: BadgeFont.sans,
        url: 'x.com/johannes',
      );
      final updated = original.copyWith(name: 'Johan');
      expect(updated.template, BadgeTemplate.classic);
      expect(updated.name, 'Johan');
      expect(updated.role, 'Organizer');
      expect(updated.font, BadgeFont.sans);
      expect(updated.url, 'x.com/johannes');
    });
  });

  group('FriendsBadgeView', () {
    testWidgets('shows the capybara grid when no image is picked', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: FriendsBadgePage()),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(
        find.text('Pick a capybara, or use the gallery button below'),
        findsOneWidget,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// In-memory HydratedBloc storage for tests (mirrors
/// test/collected_people's pattern).
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
  setUpAll(() {
    HydratedBloc.storage = _MemoryStorage();
  });

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

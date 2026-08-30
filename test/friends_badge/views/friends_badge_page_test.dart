import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    test('classic is the first template and the default', () {
      expect(BadgeTemplate.values.first, BadgeTemplate.classic);
      expect(const FriendsBadgeState().template, BadgeTemplate.classic);
      expect(const BadgeIdentityState().template, BadgeTemplate.classic);
    });

    test('every template has a non-empty label', () {
      for (final t in BadgeTemplate.values) {
        expect(t.label, isNotEmpty);
      }
    });
  });

  group('BadgeFont', () {
    test('offers seven fonts with unique labels', () {
      expect(BadgeFont.values, hasLength(7));
      expect(
        BadgeFont.values.map((f) => f.label).toSet(),
        hasLength(BadgeFont.values.length),
      );
    });

    test('every font has a name and role style', () {
      for (final font in BadgeFont.values) {
        expect(font.nameStyle.fontFamily, isNotNull, reason: '$font');
        expect(font.roleStyle.fontFamily, isNotNull, reason: '$font');
      }
    });

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
    test('starts on classic with empty text and a default font', () {
      const state = FriendsBadgeState();
      expect(state.template, BadgeTemplate.classic);
      expect(state.name, isEmpty);
      expect(state.role, isEmpty);
      expect(state.url, isEmpty);
      expect(state.font, BadgeFont.display);
      expect(state.status, FriendsBadgeStatus.idle);
      expect(state.badge, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const original = FriendsBadgeState(
        template: BadgeTemplate.overlay,
        name: 'Johannes',
        role: 'Organizer',
        font: BadgeFont.sans,
        url: 'x.com/johannes',
      );
      final updated = original.copyWith(name: 'Johan');
      expect(updated.template, BadgeTemplate.overlay);
      expect(updated.name, 'Johan');
      expect(updated.role, 'Organizer');
      expect(updated.font, BadgeFont.sans);
      expect(updated.url, 'x.com/johannes');
    });
  });

  group('TemplateTabBar', () {
    Widget subject(FriendsBadgeCubit cubit) {
      return MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            appBar: AppBar(bottom: const TemplateTabBar()),
          ),
        ),
      );
    }

    testWidgets('shows one tab per template with Classic selected', (
      tester,
    ) async {
      final cubit = FriendsBadgeCubit(identity: BadgeIdentityCubit());
      addTearDown(cubit.close);
      await tester.pumpWidget(subject(cubit));

      for (final template in BadgeTemplate.values) {
        expect(find.text(template.label), findsOneWidget);
      }
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller!.index, BadgeTemplate.classic.index);
    });

    testWidgets('tapping a tab selects that template', (tester) async {
      final cubit = FriendsBadgeCubit(identity: BadgeIdentityCubit());
      addTearDown(cubit.close);
      await tester.pumpWidget(subject(cubit));

      await tester.tap(find.text('Overlay'));
      await tester.pumpAndSettle();

      expect(cubit.state.template, BadgeTemplate.overlay);
    });

    testWidgets('opens on the persisted template', (tester) async {
      final identity = BadgeIdentityCubit()
        ..updateTemplate(BadgeTemplate.framed);
      final cubit = FriendsBadgeCubit(identity: identity);
      addTearDown(cubit.close);
      await tester.pumpWidget(subject(cubit));

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller!.index, BadgeTemplate.framed.index);
    });
  });

  group('FramePicker', () {
    Widget subject(FriendsBadgeCubit cubit) {
      return MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: Center(child: FramePicker())),
        ),
      );
    }

    testWidgets('shows a swatch per frame with stripe selected', (
      tester,
    ) async {
      final cubit = FriendsBadgeCubit(identity: BadgeIdentityCubit());
      addTearDown(cubit.close);
      await tester.pumpWidget(subject(cubit));

      expect(find.byType(FrameSwatch), findsNWidgets(BadgeFrame.values.length));
      for (final frame in BadgeFrame.values) {
        expect(find.text(frame.label), findsOneWidget);
      }
      final selected = tester
          .widgetList<FrameSwatch>(find.byType(FrameSwatch))
          .where((swatch) => swatch.selected)
          .map((swatch) => swatch.frame);
      expect(selected, [BadgeFrame.stripe]);
    });

    testWidgets('tapping a swatch selects that frame', (tester) async {
      final identity = BadgeIdentityCubit();
      final cubit = FriendsBadgeCubit(identity: identity);
      addTearDown(cubit.close);
      await tester.pumpWidget(subject(cubit));

      await tester.tap(find.text('Rounded'));
      await tester.pumpAndSettle();

      expect(cubit.state.frame, BadgeFrame.rounded);
      expect(identity.state.frame, BadgeFrame.rounded);
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

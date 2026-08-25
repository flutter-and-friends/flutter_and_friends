import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// In-memory HydratedBloc storage, keyed like the real one, so hydration
/// round-trips can be exercised in tests.
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
  late _MemoryStorage storage;

  setUp(() {
    storage = _MemoryStorage();
    HydratedBloc.storage = storage;
  });

  group('BadgeIdentityCubit', () {
    test('starts empty when nothing is persisted', () {
      final cubit = BadgeIdentityCubit();
      addTearDown(cubit.close);
      expect(cubit.state.name, isEmpty);
      expect(cubit.state.role, isEmpty);
      expect(cubit.state.url, isEmpty);
      expect(cubit.state.template, BadgeTemplate.imageOnly);
      expect(cubit.state.font, BadgeFont.display);
    });

    test('persists every field on change', () async {
      final cubit = BadgeIdentityCubit()
        ..updateName('Johannes')
        ..updateRole('Organizer')
        ..updateUrl('x.com/johannes')
        ..updateTemplate(BadgeTemplate.framed)
        ..updateFont(BadgeFont.sans);
      addTearDown(cubit.close);

      // HydratedCubit writes synchronously through Storage.write; give the
      // microtask queue a turn before reading storage.
      await Future<void>.delayed(Duration.zero);

      final stored = storage.read('BadgeIdentityCubit') as Map;
      expect(stored['name'], 'Johannes');
      expect(stored['role'], 'Organizer');
      expect(stored['url'], 'x.com/johannes');
      expect(stored['template'], 'framed');
      expect(stored['font'], 'sans');
    });

    test('rehydrates a previously saved identity on construction', () async {
      storage._data['BadgeIdentityCubit'] = {
        'name': 'Johannes Pietilä Löhnn',
        'role': 'Organizer',
        'url': 'linkedin.com/in/johannes',
        'template': 'overlay',
        'font': 'sans',
      };

      final cubit = BadgeIdentityCubit();
      addTearDown(cubit.close);

      expect(cubit.state.name, 'Johannes Pietilä Löhnn');
      expect(cubit.state.role, 'Organizer');
      expect(cubit.state.url, 'linkedin.com/in/johannes');
      expect(cubit.state.template, BadgeTemplate.overlay);
      expect(cubit.state.font, BadgeFont.sans);
    });

    test('tolerates missing fields in stored json (forward-compat)', () {
      storage._data['BadgeIdentityCubit'] = {'name': 'A'};

      final cubit = BadgeIdentityCubit();
      addTearDown(cubit.close);

      expect(cubit.state.name, 'A');
      expect(cubit.state.role, isEmpty);
      expect(cubit.state.template, BadgeTemplate.imageOnly);
    });

    test('falls back to defaults for unknown enum names', () {
      storage._data['BadgeIdentityCubit'] = {
        'template': 'holographic', // a template from the future
        'font': 'comic_sans',
      };

      final cubit = BadgeIdentityCubit();
      addTearDown(cubit.close);

      expect(cubit.state.template, BadgeTemplate.imageOnly);
      expect(cubit.state.font, BadgeFont.display);
    });
  });

  group('capybaraIdForAsset', () {
    test('maps a bundled capybara path to its asset name', () {
      expect(
        capybaraIdForAsset('assets/badge_templates/capybaras/coffee_mode.jpeg'),
        'coffee_mode',
      );
      expect(
        capybaraIdForAsset('assets/badge_templates/capybaras/yoga.jpeg'),
        'yoga',
      );
    });

    test('returns null for gallery picks (null path)', () {
      expect(capybaraIdForAsset(null), isNull);
    });

    test('returns null for paths not in the bundled list', () {
      expect(
        capybaraIdForAsset('assets/badge_templates/capybaras/not_real.jpeg'),
        isNull,
      );
      expect(capybaraIdForAsset('/data/user/photo.jpg'), isNull);
    });
  });

  group('FriendsBadgeCubit + BadgeIdentityCubit integration', () {
    test('cubit seeds its state from the identity cubit', () {
      final identity = BadgeIdentityCubit()
        ..updateName('Prefilled')
        ..updateRole('Friend')
        ..updateUrl('x.com/prefilled')
        ..updateTemplate(BadgeTemplate.classic);
      addTearDown(identity.close);

      final cubit = FriendsBadgeCubit(identity: identity);
      addTearDown(cubit.close);

      expect(cubit.state.name, 'Prefilled');
      expect(cubit.state.role, 'Friend');
      expect(cubit.state.url, 'x.com/prefilled');
      expect(cubit.state.template, BadgeTemplate.classic);
    });

    test('identity mutators forward to the identity cubit (persist on change)',
        () async {
      final identity = BadgeIdentityCubit();
      addTearDown(identity.close);
      final cubit = FriendsBadgeCubit(identity: identity);
      addTearDown(cubit.close);

      await cubit.updateName('Typed Name');
      cubit.updateUrl('typed.example');

      expect(identity.state.name, 'Typed Name');
      expect(identity.state.url, 'typed.example');
    });
  });
}

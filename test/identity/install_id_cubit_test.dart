import 'package:flutter_and_friends/identity/identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

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

final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Storage storage;

  setUp(() {
    storage = _MemoryStorage();
    HydratedBloc.storage = storage;
  });

  group('generateInstallId', () {
    test('produces a well-formed UUID v4', () {
      expect(generateInstallId(), matches(_uuidV4Pattern));
    });

    test('generates unique IDs', () {
      final ids = {for (var i = 0; i < 100; i++) generateInstallId()};
      expect(ids, hasLength(100));
    });
  });

  group('InstallIdCubit', () {
    test('generates a UUID v4 on first run', () {
      expect(InstallIdCubit().state.id, matches(_uuidV4Pattern));
    });

    test('persists the same ID across instances (app restart)', () async {
      final first = InstallIdCubit();
      final id = first.state.id;
      await first.close();

      expect(InstallIdCubit().state.id, id);
    });

    test(
      'a wiped storage regenerates a NEW id (reinstall semantics)',
      () async {
        final first = InstallIdCubit();
        final id = first.state.id;
        await first.close();
        await storage.clear();

        final regenerated = InstallIdCubit().state.id;
        expect(regenerated, matches(_uuidV4Pattern));
        expect(regenerated, isNot(id));
      },
    );

    test('a malformed stored id regenerates instead of crashing', () async {
      await storage.write('InstallIdCubit', {'id': ''});

      expect(InstallIdCubit().state.id, matches(_uuidV4Pattern));
    });
  });
}

import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/config/config.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

part 'settings_state.dart';

class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit({ShorebirdUpdater? updater})
    : _updater = updater ?? ShorebirdUpdater(),
      super(SettingsState(version: version));

  final ShorebirdUpdater _updater;

  void init() => _loadCurrentPatch();

  Future<void> _loadCurrentPatch() async {
    final patch = await _updater.readCurrentPatch();
    emit(state.copyWith(patchNumber: patch?.number));
  }

  /// Debug-only: toggles fetching the schedule feed from a local host
  /// instead of the production URL. Gated behind `kDebugMode` at the UI
  /// layer (see `SettingsView`) so it's completely absent from release
  /// builds, not merely hidden - but the persisted value itself is harmless
  /// either way since it's only ever consulted when `kDebugMode` is also
  /// true.
  void setDebugUseLocalFeed({required bool value}) =>
      emit(state.copyWith(debugUseLocalFeed: value));

  /// Debug-only: sets the base host (e.g. `http://localhost:4500`) used
  /// when [SettingsState.debugUseLocalFeed] is on.
  void setDebugFeedHost(String host) =>
      emit(state.copyWith(debugFeedHost: host));

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    return SettingsState(
      version: version,
      debugUseLocalFeed: json['debugUseLocalFeed'] as bool? ?? false,
      debugFeedHost: json['debugFeedHost'] as String?,
    );
  }

  @override
  Map<String, dynamic>? toJson(SettingsState state) {
    return {
      'debugUseLocalFeed': state.debugUseLocalFeed,
      'debugFeedHost': state.debugFeedHost,
    };
  }
}

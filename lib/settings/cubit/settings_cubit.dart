import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/config/config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({ShorebirdUpdater? updater})
    : _updater = updater ?? ShorebirdUpdater(),
      super(SettingsState(version: version));

  final ShorebirdUpdater _updater;

  void init() => _loadCurrentPatch();

  Future<void> _loadCurrentPatch() async {
    final patch = await _updater.readCurrentPatch();
    emit(state.copyWith(patchNumber: patch?.number));
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/identity/services/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'install_id_state.dart';

/// Provides this installation's random ID.
///
/// A UUID v4 is generated once at first run and then persisted via
/// HydratedBloc storage, so the ID survives app restarts but NOT a
/// reinstall (app-data wipe regenerates it). Nothing ties the ID back to
/// anything except a specific installation at a specific point in time.
///
/// The ID is written onto this user's own badge (by the badge-write flow)
/// and read back off other people's badges, where it serves as the dex
/// dedupe identity (see CollectedPeopleCubit).
///
/// The ID is read-only to the rest of the app: [InstallIdCubit] exposes no
/// mutators, only `state.id`.
class InstallIdCubit extends HydratedCubit<InstallIdState> {
  InstallIdCubit() : super(InstallIdState(id: generateInstallId()));

  @override
  InstallIdState? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    // A missing or malformed stored ID regenerates rather than crashing —
    // worst case the dex falls back to (name, role) dedupe once.
    if (id == null || id.isEmpty) {
      return InstallIdState(id: generateInstallId());
    }
    return InstallIdState(id: id);
  }

  @override
  Map<String, dynamic>? toJson(InstallIdState state) => {'id': state.id};
}

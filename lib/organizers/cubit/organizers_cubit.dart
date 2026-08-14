import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_and_friends/organizers/organizers.dart';

part 'organizers_state.dart';

/// Owns the organizers list, loaded once from the bundled build-time asset
/// (see [OrganizersRepository]). Not hydrated - nothing to persist, the
/// source is already on disk as a bundled asset.
class OrganizersCubit extends Cubit<OrganizersState> {
  OrganizersCubit({OrganizersRepository? repository})
    : _repository = repository ?? const OrganizersRepository(),
      super(const OrganizersState());

  final OrganizersRepository _repository;

  Future<void> init() async {
    emit(state.copyWith(status: OrganizersStatus.loading));
    try {
      final organizers = await _repository.loadOrganizers();
      emit(
        OrganizersState(
          status: OrganizersStatus.loaded,
          organizers: organizers,
        ),
      );
    } on Exception catch (error) {
      debugPrint('Could not load bundled organizers asset: $error');
      emit(
        state.copyWith(
          status: OrganizersStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

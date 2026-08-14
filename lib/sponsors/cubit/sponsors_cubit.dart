import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_and_friends/sponsors/sponsors.dart';

part 'sponsors_state.dart';

/// Owns sponsor tier data, loaded once from the bundled build-time asset
/// (see [SponsorsRepository]). Not hydrated - there is nothing to persist
/// across launches since the source is already on disk as a bundled asset,
/// not a network fetch.
class SponsorsCubit extends Cubit<SponsorsState> {
  SponsorsCubit({SponsorsRepository? repository})
    : _repository = repository ?? const SponsorsRepository(),
      super(const SponsorsState());

  final SponsorsRepository _repository;

  Future<void> init() async {
    emit(state.copyWith(status: SponsorsStatus.loading));
    try {
      final data = await _repository.loadSponsors();
      emit(
        SponsorsState(
          status: SponsorsStatus.loaded,
          tiers: data.tiers,
          version: data.version,
        ),
      );
    } on Exception catch (error) {
      // Bundled asset missing or malformed - this should only happen if
      // tool/sync_sponsors.dart was never run or the asset was hand-edited.
      // Not recoverable at runtime; surface an error state rather than
      // pretending there are no sponsors.
      debugPrint('Could not load bundled sponsors asset: $error');
      emit(
        state.copyWith(
          status: SponsorsStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

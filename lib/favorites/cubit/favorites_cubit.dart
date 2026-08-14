import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'favorites_state.dart';

class FavoritesCubit extends HydratedCubit<FavoritesState> {
  FavoritesCubit() : super(const FavoritesState());

  void toggleFavorite(Event event) {
    final events = [...state.events];
    final isFavorite = events.any((e) => e.id == event.id);
    isFavorite
        ? events.removeWhere((e) => e.id == event.id)
        : events.add(event);
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    emit(state.copyWith(events: events));
  }

  bool isFavorite(Event event) => state.events.any((e) => e.id == event.id);

  @override
  FavoritesState? fromJson(Map<String, dynamic> json) {
    // Favourites are matched by `Event.id` only - a stable id authored by
    // the remote schedule feed. There is no migration path from the old
    // structural-equality / derived-hash identity schemes: `HydratedBloc`
    // storage moved from the OS temp directory to the application support
    // directory in this same change, so any favourite persisted under the
    // old scheme lives at a path this build never reads. Preferences
    // clearing once on upgrade is expected and accepted.
    final events = [
      ...(json['events'] as List).map(
        (e) => Event.fromJson(e as Map<String, dynamic>),
      ),
    ];
    return FavoritesState(events: events);
  }

  @override
  Map<String, dynamic>? toJson(FavoritesState state) {
    return {'events': state.events.map(Event.toJson).toList()};
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/collected_people/models/models.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'collected_people_state.dart';

/// Stores the people collected by tapping their badges, Capydex-style.
///
/// Mirrors the FavoritesCubit hydration pattern: the whole state
/// serializes to JSON via HydratedBloc storage.
class CollectedPeopleCubit extends HydratedCubit<CollectedPeopleState> {
  CollectedPeopleCubit() : super(const CollectedPeopleState());

  /// Adds [person] to the dex, or returns the existing entry when this
  /// person was already collected.
  ///
  /// Dedupe policy: identity is the `(name, role)` pair (case-sensitive).
  /// Re-tapping the same person's badge does not create a duplicate; the
  /// existing entry (and its original `collectedAt`) is kept, so the dex
  /// stays in first-collected order. Badge data carries no stable id, and
  /// `name + role` is the most specific identity the wire format offers.
  CollectedPerson collect(CollectedPerson person) {
    for (final existing in state.people) {
      if (existing.name == person.name && existing.role == person.role) {
        return existing;
      }
    }
    emit(state.copyWith(people: [...state.people, person]));
    return person;
  }

  /// Removes [person] from the dex.
  void remove(CollectedPerson person) {
    emit(
      state.copyWith(
        people: state.people.where((p) => p != person).toList(),
      ),
    );
  }

  @override
  CollectedPeopleState? fromJson(Map<String, dynamic> json) {
    final people = [
      ...(json['people'] as List).map(
        (p) => CollectedPerson.fromJson(p as Map<String, dynamic>),
      ),
    ];
    return CollectedPeopleState(people: people);
  }

  @override
  Map<String, dynamic>? toJson(CollectedPeopleState state) {
    return {'people': state.people.map((p) => p.toJson()).toList()};
  }
}

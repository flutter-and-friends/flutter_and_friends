import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/collected_people/models/models.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'collected_people_state.dart';

/// Stores the people collected by tapping their badges, Pokédex-style.
///
/// Mirrors the FavoritesCubit hydration pattern: the whole state
/// serializes to JSON via HydratedBloc storage.
///
/// ## Dedupe identity (v2)
///
/// Precedence when [collect]ing a person:
///
/// 1. **Install ID first.** If the incoming person carries an
///    [CollectedPerson.installId] (v2 wire format) and an existing entry
///    has the SAME installId, that entry is *updated in place*: name, role,
///    urls and capybaraId refresh from the new badge, but the original
///    `collectedAt` is kept (and the entry keeps its position in the dex).
///    Rationale: an install ID identifies a specific app installation, so
///    it survives that person rewriting their badge with a new name, role,
///    or links — re-tapping must not create a duplicate.
/// 2. **(name, role) fallback.** For ID-less badges (written pre-v2, or
///    with no `id:` segment) identity is the `(name, role)` pair
///    (case-sensitive): re-tapping returns the existing entry unchanged.
///
/// Two entries with the same `(name, role)` but DIFFERENT installIds are
/// two different installations — both stay in the dex.
class CollectedPeopleCubit extends HydratedCubit<CollectedPeopleState> {
  CollectedPeopleCubit() : super(const CollectedPeopleState());

  /// Adds [person] to the dex, updating or returning the existing entry
  /// when this person was already collected (see the class doc for the
  /// identity precedence).
  ///
  /// Returns the entry as it now stands in the dex.
  CollectedPerson collect(CollectedPerson person) {
    final people = [...state.people];

    // 1. Install-ID identity (v2). A person carrying an installId only
    //    ever matches an existing entry by that id — never by
    //    (name, role): two installations of the app are two dex entries
    //    even when their badges carry identical name and role.
    final installId = person.installId;
    if (installId != null) {
      final index = people.indexWhere((p) => p.installId == installId);
      if (index != -1) {
        final updated = people[index].copyWith(
          name: person.name,
          role: person.role,
          urls: person.urls,
          capybaraId: person.capybaraId,
        );
        people[index] = updated;
        emit(state.copyWith(people: people));
        return updated;
      }
      emit(state.copyWith(people: [...people, person]));
      return person;
    }

    // 2. (name, role) fallback for ID-less badges.
    for (final existing in people) {
      if (existing.name == person.name && existing.role == person.role) {
        return existing;
      }
    }

    emit(state.copyWith(people: [...people, person]));
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

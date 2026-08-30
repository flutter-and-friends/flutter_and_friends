import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/collected_people/models/models.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'collected_people_state.dart';

/// Stores the people collected by tapping their badges, Pokédex-style.
///
/// Mirrors the FavoritesCubit hydration pattern: the whole state
/// serializes to JSON via HydratedBloc storage.
///
/// ## Dedupe identity
///
/// Precedence when [collect]ing a person:
///
/// 1. **Badge ID first.** If the incoming person carries a
///    [CollectedPerson.badgeId] (the physical badge's NFC tag UID) and an
///    existing entry has the SAME badgeId, that entry is *updated in
///    place*: name, role, urls, capybaraId and installId refresh from the
///    new tap, but the original `collectedAt` is kept (and the entry keeps
///    its position in the dex). Tapping the same badge twice never creates
///    a duplicate, even if it was rewritten with new details or by a
///    different app installation in between.
/// 2. **Install ID.** If the incoming person carries a
///    [CollectedPerson.installId] (v2 wire format) and an existing entry
///    has the SAME installId, that entry is updated in place the same way,
///    picking up the badgeId when the entry had none. An install ID
///    identifies a specific app installation, so it survives that person
///    moving their details to a replacement badge.
/// 3. **(name, role) fallback.** For badges carrying neither ID identity is
///    the `(name, role)` pair (case-sensitive): re-tapping returns the
///    existing entry unchanged.
///
/// A person carrying a badgeId or installId only ever matches by those IDs,
/// never by (name, role): two badges or two installations with identical
/// name and role are two dex entries.
class CollectedPeopleCubit extends HydratedCubit<CollectedPeopleState> {
  CollectedPeopleCubit() : super(const CollectedPeopleState());

  /// Adds [person] to the dex, updating or returning the existing entry
  /// when this person was already collected (see the class doc for the
  /// identity precedence).
  ///
  /// Returns the entry as it now stands in the dex.
  CollectedPerson collect(CollectedPerson person) {
    final people = [...state.people];

    CollectedPerson updateAt(int index) {
      final updated = people[index].copyWith(
        name: person.name,
        role: person.role,
        urls: person.urls,
        capybaraId: person.capybaraId,
        installId: person.installId,
        badgeId: person.badgeId,
      );
      people[index] = updated;
      emit(state.copyWith(people: people));
      return updated;
    }

    // 1. Badge identity: the physical badge's tag UID.
    final badgeId = person.badgeId;
    if (badgeId != null) {
      final index = people.indexWhere((p) => p.badgeId == badgeId);
      if (index != -1) return updateAt(index);
    }

    // 2. Install-ID identity (v2 wire format).
    final installId = person.installId;
    if (installId != null) {
      final index = people.indexWhere((p) => p.installId == installId);
      if (index != -1) return updateAt(index);
    }

    if (badgeId != null || installId != null) {
      emit(state.copyWith(people: [...people, person]));
      return person;
    }

    // 3. (name, role) fallback for ID-less badges.
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

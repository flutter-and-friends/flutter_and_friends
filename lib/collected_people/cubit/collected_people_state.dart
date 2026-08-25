part of 'collected_people_cubit.dart';

class CollectedPeopleState extends Equatable {
  const CollectedPeopleState({this.people = const []});

  /// Collected people, in the order they were first collected.
  final List<CollectedPerson> people;

  CollectedPeopleState copyWith({List<CollectedPerson>? people}) {
    return CollectedPeopleState(people: people ?? this.people);
  }

  @override
  List<Object> get props => [people];
}

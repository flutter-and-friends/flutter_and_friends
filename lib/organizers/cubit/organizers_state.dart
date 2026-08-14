part of 'organizers_cubit.dart';

enum OrganizersStatus { initial, loading, loaded, error }

class OrganizersState extends Equatable {
  const OrganizersState({
    this.status = OrganizersStatus.initial,
    this.organizers = const [],
    this.errorMessage,
  });

  final OrganizersStatus status;
  final List<Organizer> organizers;
  final String? errorMessage;

  OrganizersState copyWith({
    OrganizersStatus? status,
    List<Organizer>? organizers,
    String? errorMessage,
  }) {
    return OrganizersState(
      status: status ?? this.status,
      organizers: organizers ?? this.organizers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, organizers, errorMessage];
}

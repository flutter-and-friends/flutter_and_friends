part of 'install_id_cubit.dart';

class InstallIdState extends Equatable {
  const InstallIdState({required this.id});

  /// This installation's random UUID v4.
  final String id;

  @override
  List<Object> get props => [id];
}

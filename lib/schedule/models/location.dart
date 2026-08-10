import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location extends Equatable {
  const Location({required this.name, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);

  final String name;

  /// May be null when the remote feed doesn't supply venue coordinates for
  /// this event (e.g. talks/workshops identified only by stage name).
  final (double latitude, double longitude)? coordinates;

  @override
  List<Object?> get props => [name, coordinates];
}

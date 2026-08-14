// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: strict_raw_type, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  name: json['name'] as String,
  coordinates: _$recordConvertNullable(
    json['coordinates'],
    ($jsonValue) => (
      ($jsonValue[r'$1'] as num).toDouble(),
      ($jsonValue[r'$2'] as num).toDouble(),
    ),
  ),
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'name': instance.name,
  'coordinates': instance.coordinates == null
      ? null
      : <String, dynamic>{
          r'$1': instance.coordinates!.$1,
          r'$2': instance.coordinates!.$2,
        },
};

$Rec? _$recordConvertNullable<$Rec>(
  Object? value,
  $Rec Function(Map) convert,
) => value == null ? null : convert(value as Map<String, dynamic>);

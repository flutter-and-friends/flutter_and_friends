// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: strict_raw_type, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
  id: json['id'] as String,
  name: json['name'] as String,
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  startTime: DateTime.parse(json['startTime'] as String),
  location: json['location'] == null
      ? null
      : Location.fromJson(json['location'] as Map<String, dynamic>),
  image: json['image'] as String?,
  link: json['link'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'duration': instance.duration.inMicroseconds,
  'startTime': instance.startTime.toIso8601String(),
  'location': instance.location,
  'image': instance.image,
  'link': instance.link,
  'description': instance.description,
};

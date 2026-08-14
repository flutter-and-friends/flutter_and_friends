// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: strict_raw_type, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'organizer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organizer _$OrganizerFromJson(Map<String, dynamic> json) => Organizer(
  id: json['id'] as String,
  name: json['name'] as String,
  avatar: json['avatar'] as String?,
  handle: json['handle'] as String?,
);

Map<String, dynamic> _$OrganizerToJson(Organizer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar': instance.avatar,
  'handle': instance.handle,
};

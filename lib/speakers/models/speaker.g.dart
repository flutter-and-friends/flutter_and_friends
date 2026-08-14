// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: strict_raw_type, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'speaker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Speaker _$SpeakerFromJson(Map<String, dynamic> json) => Speaker(
  slug: json['slug'] as String,
  name: json['name'] as String,
  title: json['title'] as String,
  bio: json['bio'] as String,
  photoUrl: json['photoUrl'] as String?,
  github: json['github'] as String?,
  bluesky: json['bluesky'] as String?,
  linkedin: json['linkedin'] as String?,
  website: json['website'] as String?,
);

Map<String, dynamic> _$SpeakerToJson(Speaker instance) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'title': instance.title,
  'bio': instance.bio,
  'photoUrl': instance.photoUrl,
  'github': instance.github,
  'bluesky': instance.bluesky,
  'linkedin': instance.linkedin,
  'website': instance.website,
};

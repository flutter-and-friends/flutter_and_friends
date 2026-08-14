// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: strict_raw_type, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'sponsors.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sponsor _$SponsorFromJson(Map<String, dynamic> json) => Sponsor(
  id: json['id'] as String,
  name: json['name'] as String,
  url: json['url'] as String,
  logo: json['logo'] as String,
);

Map<String, dynamic> _$SponsorToJson(Sponsor instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'url': instance.url,
  'logo': instance.logo,
};

SponsorTier _$SponsorTierFromJson(Map<String, dynamic> json) => SponsorTier(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  sponsors: (json['sponsors'] as List<dynamic>)
      .map((e) => Sponsor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SponsorTierToJson(SponsorTier instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'sponsors': instance.sponsors.map((e) => e.toJson()).toList(),
    };

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'speaker.g.dart';

@JsonSerializable()
class Speaker extends Equatable {
  const Speaker({
    required this.slug,
    required this.name,
    required this.title,
    required this.bio,
    this.photoUrl,
    this.github,
    this.bluesky,
    this.linkedin,
    this.website,
  });

  factory Speaker.fromJson(Map<String, dynamic> json) =>
      _$SpeakerFromJson(json);

  Map<String, dynamic> toJson() => _$SpeakerToJson(this);

  /// Stable, author-assigned key from the remote feed (`speakers[].slug`).
  /// Used to match a speaker to `sessions[].speaker_slugs` - the documented
  /// join key, distinct from (and more stable than) [name].
  final String slug;

  final String name;
  final String title;
  final String bio;

  /// Absolute URL to the speaker's photo, fetched over the network and
  /// cached locally. Explicitly nullable - the feed sends `null` for a
  /// speaker with no photo rather than omitting the field or pointing at a
  /// placeholder, so callers must render an initials fallback rather than
  /// assume a URL is always present.
  final String? photoUrl;

  final String? github;
  final String? bluesky;
  final String? linkedin;
  final String? website;

  @override
  List<Object?> get props => [
    slug,
    name,
    title,
    bio,
    photoUrl,
    github,
    bluesky,
    linkedin,
    website,
  ];
}

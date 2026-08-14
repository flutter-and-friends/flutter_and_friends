import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'organizer.g.dart';

@JsonSerializable()
class Organizer extends Equatable {
  const Organizer({
    required this.id,
    required this.name,
    this.avatar,
    this.handle,
  });

  factory Organizer.fromJson(Map<String, dynamic> json) =>
      _$OrganizerFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizerToJson(this);

  /// Stable authored slug from the website's `sponsors.json` `organizers[]`
  /// (e.g. `"lukas"`) - also the local avatar's filename stem, since
  /// `tool/sync_sponsors.dart` vendors each organizer's remote `avatar_url`
  /// into a bundled asset at sync time, the same way it does sponsor logos.
  /// Never fetched at app runtime.
  final String id;
  final String name;

  /// Bundled asset path, e.g. `assets/organizers/lukas.jpg`. Sourced from
  /// the feed's (nullable) `avatar_url` at sync time, not read from the
  /// network directly. Null when the feed had no `avatar_url` for this
  /// organizer - display code must handle that gracefully.
  final String? avatar;

  /// Renamed from the former `twitter` field to match the feed's
  /// platform-neutral `handle`. Stored without the leading `@` (the sync
  /// script strips it from the feed's `"@spydon"`) so display code adds it
  /// back in exactly one place.
  final String? handle;

  @override
  List<Object?> get props => [id, name, avatar, handle];
}

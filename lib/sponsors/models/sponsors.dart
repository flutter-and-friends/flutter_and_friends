import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sponsors.g.dart';

/// A single sponsor, sourced from the website's `sponsors.json` feed (vendored
/// at release-prep time, never fetched at app runtime - see
/// `tool/sync_sponsors.dart`).
///
/// [logo] is a bundled asset path (`assets/sponsors/<id>.<ext>`), not the
/// feed's remote `logo_url` - the sync script downloads the image once and
/// this app only ever reads the local copy.
@JsonSerializable()
class Sponsor extends Equatable {
  const Sponsor({
    required this.id,
    required this.name,
    required this.url,
    required this.logo,
  });

  factory Sponsor.fromJson(Map<String, dynamic> json) =>
      _$SponsorFromJson(json);

  Map<String, dynamic> toJson() => _$SponsorToJson(this);

  /// Stable authored slug from the feed (e.g. `"flutter"`) - also the
  /// bundled logo's filename stem.
  final String id;
  final String name;
  final String url;

  /// Bundled asset path, e.g. `assets/sponsors/flutter.png` or
  /// `.../revenuecat.svg`. Use [isSvg] to pick the right image widget.
  final String logo;

  bool get isSvg => logo.toLowerCase().endsWith('.svg');

  @override
  List<Object?> get props => [id, name, url, logo];
}

/// One tier of sponsors (`platinum` / `gold` / `silver` / `event_sponsor`),
/// carrying the feed's own display name so the app never hardcodes tier
/// copy that could drift from the website's.
@JsonSerializable(explicitToJson: true)
class SponsorTier extends Equatable {
  const SponsorTier({
    required this.id,
    required this.displayName,
    required this.sponsors,
  });

  factory SponsorTier.fromJson(Map<String, dynamic> json) =>
      _$SponsorTierFromJson(json);

  Map<String, dynamic> toJson() => _$SponsorTierToJson(this);

  final String id;
  final String displayName;
  final List<Sponsor> sponsors;

  @override
  List<Object?> get props => [id, displayName, sponsors];
}

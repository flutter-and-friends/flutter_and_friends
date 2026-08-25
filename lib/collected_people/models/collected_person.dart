import 'package:equatable/equatable.dart';
import 'package:friends_badge/friends_badge.dart';

/// A person collected by tapping their conference badge, stored in the
/// Pokédex-style dex.
///
/// Pure data — JSON serialization lives here next to the model (hand-written,
/// mirroring how `FavoritesCubit` keeps its persistence simple), and the
/// [BadgePerson] → [CollectedPerson] mapping lives in `toCollectedPerson`.
class CollectedPerson extends Equatable {
  const CollectedPerson({
    required this.name,
    required this.role,
    required this.urls,
    required this.collectedAt,
    this.installId,
    this.capybaraId,
  });

  factory CollectedPerson.fromJson(Map<String, dynamic> json) {
    return CollectedPerson(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      urls: [
        for (final url in json['urls'] as List? ?? const []) url as String,
      ],
      collectedAt:
          DateTime.tryParse(json['collectedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      // Additive v2 fields: entries hydrated from a pre-v2 build simply
      // have no installId/capybaraId.
      installId: json['installId'] as String?,
      capybaraId: json['capybaraId'] as String?,
    );
  }

  /// The person's display name. May be empty for a nameless badge.
  final String name;

  /// The person's role or title. Empty string when the badge carried none.
  final String role;

  /// All links collected from the badge: the U record URL (if any) followed
  /// by any additional URLs from the Text record. May be empty for a
  /// name-only badge.
  final List<String> urls;

  /// When this person was first collected (local time).
  final DateTime collectedAt;

  /// The badge owner's app install ID (v2 wire format), or `null` for
  /// badges written before v2. When present, this is the dex dedupe
  /// identity (see CollectedPeopleCubit).
  final String? installId;

  /// The bundled capybara asset name (e.g. `"coffee_mode"`) when the
  /// person's badge image is a bundled capybara; `null` for gallery-image
  /// badges and pre-v2 badges.
  final String? capybaraId;

  /// Returns a copy with the given fields replaced.
  ///
  /// Note: nullable fields ([installId], [capybaraId]) cannot be reset to
  /// `null` through this method — the dex never needs to (a re-collected
  /// badge either carries an ID or the entry keeps its existing one).
  CollectedPerson copyWith({
    String? name,
    String? role,
    List<String>? urls,
    DateTime? collectedAt,
    String? installId,
    String? capybaraId,
  }) {
    return CollectedPerson(
      name: name ?? this.name,
      role: role ?? this.role,
      urls: urls ?? this.urls,
      collectedAt: collectedAt ?? this.collectedAt,
      installId: installId ?? this.installId,
      capybaraId: capybaraId ?? this.capybaraId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'urls': urls,
      'collectedAt': collectedAt.toIso8601String(),
      if (installId != null) 'installId': installId,
      if (capybaraId != null) 'capybaraId': capybaraId,
    };
  }

  @override
  List<Object?> get props => [
    name,
    role,
    urls,
    collectedAt,
    installId,
    capybaraId,
  ];
}

/// Maps a decoded [BadgePerson] (the `friends_badge` package's read-side
/// model) into a [CollectedPerson] for the dex. Pure by design so the mapping
/// rules are unit-testable without any NFC hardware.
///
/// Mapping rules:
///
/// - [BadgePerson.primaryUri] (the badge's U record) becomes the first entry
///   of [CollectedPerson.urls], followed by any Text-record URLs that are not
///   already present (the writer currently puts the same link in both
///   records, so this dedupe keeps the common case to a single URL).
/// - A bare URL without a scheme (the writer stores them as typed, e.g.
///   `x.com/johannes`) is prefixed with `https://` so `url_launcher` can open
///   it directly. URLs that already carry a scheme are stored unchanged.
/// - Name and role pass through as-is (both may be empty when the badge's
///   Text record was absent or malformed).
/// - [BadgePerson.installId] and [BadgePerson.capybaraId] (v2 tagged
///   segments) pass through unchanged; both are `null` on pre-v2 badges.
CollectedPerson toCollectedPerson(BadgePerson person, {DateTime? collectedAt}) {
  final urls = <String>[
    if (person.primaryUri != null) _ensureScheme(person.primaryUri.toString()),
    for (final url in person.urls) _ensureScheme(url),
  ];
  return CollectedPerson(
    name: person.name,
    role: person.role,
    urls: urls.toSet().toList(),
    collectedAt: collectedAt ?? DateTime.now(),
    installId: person.installId,
    capybaraId: person.capybaraId,
  );
}

String _ensureScheme(String url) => url.contains('://') ? url : 'https://$url';

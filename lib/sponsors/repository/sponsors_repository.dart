import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_and_friends/sponsors/sponsors.dart';

/// Thrown when the bundled `sponsors.json` asset doesn't match the shape
/// this client understands. Bundled content should never be malformed (it's
/// vendored and committed by `tool/sync_sponsors.dart`, not fetched live),
/// so hitting this is a sync-script or asset-packaging bug, not a runtime
/// condition to recover from gracefully.
class SponsorsFormatException implements Exception {
  SponsorsFormatException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'SponsorsFormatException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Result of parsing the bundled sponsors asset: the tiers plus the feed's
/// own [version], so a later diagnostic can confirm which content-hash
/// generation shipped in this build.
class SponsorsData {
  const SponsorsData({required this.tiers, required this.version});

  final List<SponsorTier> tiers;
  final int version;
}

/// Reads sponsor data from the build-time bundled asset
/// (`assets/sponsors/sponsors.json`) that `tool/sync_sponsors.dart` vendors
/// from the website's published feed. Deliberately **not** a network fetch:
/// sponsors don't change mid-conference, so there is no live/cache/snapshot
/// ladder here the way there is for the schedule - just one bundled
/// snapshot, refreshed deliberately at release-prep time.
class SponsorsRepository {
  const SponsorsRepository({this.assetPath = _defaultAssetPath});

  static const _defaultAssetPath = 'assets/sponsors/sponsors.json';

  final String assetPath;

  Future<SponsorsData> loadSponsors() async {
    final String body;
    try {
      body = await rootBundle.loadString(assetPath);
    } on Exception catch (error) {
      throw SponsorsFormatException(
        'Could not load bundled sponsors asset at $assetPath',
        error,
      );
    }
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tiers = [
        for (final raw in json['tiers'] as List)
          SponsorTier.fromJson(raw as Map<String, dynamic>),
      ];
      return SponsorsData(tiers: tiers, version: json['version'] as int);
    } on SponsorsFormatException {
      rethrow;
    } on Exception catch (error) {
      throw SponsorsFormatException(
        'Could not parse bundled sponsors asset',
        error,
      );
    }
  }
}

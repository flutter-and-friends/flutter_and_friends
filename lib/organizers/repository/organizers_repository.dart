import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_and_friends/organizers/organizers.dart';

/// Thrown when the bundled `organizers.json` asset doesn't match the shape
/// this client understands. Bundled content should never be malformed -
/// it's vendored and committed by `tool/sync_sponsors.dart`, not fetched
/// live - so hitting this is a sync-script or asset-packaging bug.
class OrganizersFormatException implements Exception {
  OrganizersFormatException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'OrganizersFormatException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Reads organizer data from the build-time bundled asset
/// (`assets/organizers/organizers.json`) that `tool/sync_sponsors.dart`
/// vendors from the website's published `sponsors.json` feed (`organizers[]`).
/// Not a network fetch - organizers change as rarely as sponsors and share
/// the same drift problem the sync script exists to solve.
class OrganizersRepository {
  const OrganizersRepository({this.assetPath = _defaultAssetPath});

  static const _defaultAssetPath = 'assets/organizers/organizers.json';

  final String assetPath;

  Future<List<Organizer>> loadOrganizers() async {
    final String body;
    try {
      body = await rootBundle.loadString(assetPath);
    } on Exception catch (error) {
      throw OrganizersFormatException(
        'Could not load bundled organizers asset at $assetPath',
        error,
      );
    }
    try {
      final json = jsonDecode(body) as List;
      return [
        for (final raw in json) Organizer.fromJson(raw as Map<String, dynamic>),
      ];
    } on OrganizersFormatException {
      rethrow;
    } on Exception catch (error) {
      throw OrganizersFormatException(
        'Could not parse bundled organizers asset',
        error,
      );
    }
  }
}

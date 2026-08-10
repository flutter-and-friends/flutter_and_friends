// ignore_for_file: avoid_print
// This is a standalone CLI script (not app code) - print is the intended
// way to report sync progress and failures to the person running it.
//
// Vendors sponsor and organizer content from the website's published feed into
// this app's bundled assets. Run deliberately at release-prep time:
//
//   dart run tool/sync_sponsors.dart
//
// This is NOT part of `flutter build` and must not become one - it hits
// the network, and CI/offline builds must not depend on that. What it
// writes (assets/sponsors/sponsors.json + assets/sponsors/*.{png,svg,webp},
// assets/organizers/organizers.json + assets/organizers/*.{jpg,png,...})
// is committed to source control like any other bundled asset.
//
// Design: sponsors and organizers are build-time content, not runtime-
// fetched - see SponsorsRepository / OrganizersRepository, which only ever
// read these vendored files. The problem this script solves is *drift*
// (this app's sponsor/organizer lists silently diverging from the
// website's), not freshness - there is no live/cache ladder here, just a
// deliberate, auditable refresh.
//
// Failure policy: any missing id, duplicate id, unknown tier, or failed
// image download aborts the whole sync with a non-zero exit and nothing
// written for that half - a partially-synced asset directory that *looks*
// complete is worse than a stale one that obviously needs a re-run.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _defaultFeedUrl = 'https://flutterfriends.dev/sponsors.json';
const _sponsorsAssetDir = 'assets/sponsors';
const _organizersAssetDir = 'assets/organizers';
const _knownTiers = {'platinum', 'gold', 'silver', 'event_sponsor'};

/// Supports `--feed-url=<url>` to point at a staging/local feed instead of
/// production (e.g. while the real feed isn't deployed yet), and
/// `--dry-run` to report what would change without writing or deleting
/// anything - useful before trusting a sync that deletes stale assets.
Future<void> main(List<String> args) async {
  var feedUrl = _defaultFeedUrl;
  var dryRun = false;
  for (final arg in args) {
    if (arg.startsWith('--feed-url=')) {
      feedUrl = arg.substring('--feed-url='.length);
    } else if (arg == '--dry-run') {
      dryRun = true;
    } else {
      stderr.writeln('sync_sponsors: unrecognized argument "$arg"');
      exitCode = 1;
      return;
    }
  }

  final client = http.Client();
  try {
    await _sync(client, feedUrl: feedUrl, dryRun: dryRun);
  } on _SyncFailure catch (error) {
    stderr.writeln('sync_sponsors: FAILED - ${error.message}');
    exitCode = 1;
  } finally {
    client.close();
  }
}

class _SyncFailure implements Exception {
  _SyncFailure(this.message);
  final String message;
}

Future<void> _sync(
  http.Client client, {
  required String feedUrl,
  required bool dryRun,
}) async {
  if (dryRun) {
    print('--dry-run: no files will be written or deleted.');
  }
  print('Fetching $feedUrl ...');
  final response = await client.get(Uri.parse(feedUrl));
  if (response.statusCode != 200) {
    throw _SyncFailure(
      'feed returned HTTP ${response.statusCode} - expected 200',
    );
  }
  final contentType = response.headers['content-type'] ?? '';
  if (!contentType.contains('json')) {
    throw _SyncFailure(
      'feed did not return JSON (content-type: "$contentType"). This '
      "usually means the endpoint is serving the website's SPA fallback "
      'instead of the feed - confirm the website has deployed sponsors.json and it is '
      'actually deployed before re-running.',
    );
  }

  final Map<String, dynamic> feed;
  try {
    feed = jsonDecode(response.body) as Map<String, dynamic>;
  } on FormatException catch (error) {
    throw _SyncFailure('feed body is not valid JSON: $error');
  }

  final rawTiers = feed['tiers'];
  final rawOrganizers = feed['organizers'];
  if (rawTiers is! List) {
    throw _SyncFailure('feed missing "tiers" array');
  }
  if (rawOrganizers is! List) {
    throw _SyncFailure('feed missing "organizers" array');
  }

  final sponsorIds = <String>{};
  final sponsorFilenames = <String>{};
  final vendoredTiers = <Map<String, dynamic>>[];
  for (final rawTier in rawTiers) {
    final tier = rawTier as Map<String, dynamic>;
    final tierId = tier['id'] as String;
    if (!_knownTiers.contains(tierId)) {
      throw _SyncFailure(
        'unknown sponsor tier "$tierId" - expected one of $_knownTiers. '
        'This app does not know how to render it; a new tier needs an app '
        'code change before this sync can proceed.',
      );
    }
    final vendoredSponsors = <Map<String, dynamic>>[];
    for (final rawSponsor in tier['sponsors'] as List) {
      final sponsor = rawSponsor as Map<String, dynamic>;
      final id = sponsor['id'] as String;
      if (!sponsorIds.add(id)) {
        throw _SyncFailure('duplicate sponsor id "$id" across tiers');
      }
      final logoUrl = sponsor['logo_url'] as String?;
      if (logoUrl == null) {
        throw _SyncFailure('sponsor "$id" has no logo_url');
      }
      final logoPath = await _downloadAsset(
        client: client,
        url: logoUrl,
        directory: _sponsorsAssetDir,
        stem: id,
        label: 'sponsor "$id" logo',
        dryRun: dryRun,
      );
      sponsorFilenames.add(logoPath.split('/').last);
      vendoredSponsors.add({
        'id': id,
        'name': sponsor['name'],
        'url': sponsor['url'],
        'logo': logoPath,
      });
    }
    vendoredTiers.add({
      'id': tierId,
      'displayName': tier['display_name'],
      'sponsors': vendoredSponsors,
    });
  }

  final organizerIds = <String>{};
  final organizerFilenames = <String>{};
  final vendoredOrganizers = <Map<String, dynamic>>[];
  for (final rawOrganizer in rawOrganizers) {
    final organizer = rawOrganizer as Map<String, dynamic>;
    final id = organizer['id'] as String;
    if (!organizerIds.add(id)) {
      throw _SyncFailure('duplicate organizer id "$id"');
    }
    final avatarUrl = organizer['avatar_url'] as String?;
    String? avatarPath;
    if (avatarUrl != null) {
      avatarPath = await _downloadAsset(
        client: client,
        url: avatarUrl,
        directory: _organizersAssetDir,
        stem: id,
        label: 'organizer "$id" avatar',
        dryRun: dryRun,
      );
      organizerFilenames.add(avatarPath.split('/').last);
    } else {
      print('  organizer "$id" has no avatar_url - leaving avatar unset');
    }
    final rawHandle = organizer['handle'] as String?;
    vendoredOrganizers.add({
      'id': id,
      'name': organizer['name'],
      'avatar': avatarPath,
      // Stored without the leading "@" - the wire sends "@spydon", the app
      // model adds the "@" back in exactly one place for display.
      'handle': rawHandle?.replaceFirst(RegExp('^@'), ''),
    });
  }

  await _cleanStaleAssets(
    directory: _sponsorsAssetDir,
    keepFilenames: sponsorFilenames,
    keepFiles: {'sponsors.json'},
    dryRun: dryRun,
  );
  await _cleanStaleAssets(
    directory: _organizersAssetDir,
    keepFilenames: organizerFilenames,
    keepFiles: {'organizers.json'},
    dryRun: dryRun,
  );

  final version = feed['version'];
  if (dryRun) {
    print(
      'Would sync ${sponsorIds.length} sponsors across '
      '${vendoredTiers.length} tiers and ${organizerIds.length} '
      'organizers (feed version $version). No files written.',
    );
    return;
  }
  await File(
    '$_sponsorsAssetDir/sponsors.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'version': version,
      'tiers': vendoredTiers,
    }),
  );
  await File(
    '$_organizersAssetDir/organizers.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert(vendoredOrganizers),
  );

  print(
    'Synced ${sponsorIds.length} sponsors across ${vendoredTiers.length} '
    'tiers and ${organizerIds.length} organizers (feed version $version).',
  );
}

/// Downloads [url] into `<directory>/<stem>.<ext>`, inferring the extension
/// from the URL path (falling back to the response content-type). Fails
/// loudly on any non-200 - per the sync contract, a 404 here means content
/// genuinely changed upstream, not a stale reference that slipped through.
Future<String> _downloadAsset({
  required http.Client client,
  required String url,
  required String directory,
  required String stem,
  required String label,
  required bool dryRun,
}) async {
  final response = await client.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw _SyncFailure('$label: HTTP ${response.statusCode} for $url');
  }
  final ext = _extensionFor(url, response.headers['content-type']);
  final path = '$directory/$stem.$ext';
  if (dryRun) {
    print('  would write $path (${response.bodyBytes.length} bytes)');
    return path;
  }
  await Directory(directory).create(recursive: true);
  await File(path).writeAsBytes(response.bodyBytes);
  print('  wrote $path (${response.bodyBytes.length} bytes)');
  return path;
}

String _extensionFor(String url, String? contentType) {
  final uriExt = Uri.parse(url).path.split('.').lastOrNull;
  if (uriExt != null && uriExt.isNotEmpty && uriExt.length <= 5) {
    return uriExt.toLowerCase();
  }
  switch (contentType) {
    case 'image/svg+xml':
      return 'svg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/jpeg':
      return 'jpg';
    default:
      throw _SyncFailure(
        'could not infer file extension for $url (content-type: '
        '$contentType)',
      );
  }
}

/// Deletes any file under [directory] whose filename isn't in
/// [keepFilenames] and isn't one of [keepFiles] - the 2025 -> 2026 sponsor
/// set change (or an organizer stepping down) should not leave orphaned
/// assets inflating the bundle indefinitely. Matching on the full filename
/// (not just the id "stem") matters because a sponsor's asset can change
/// *extension* across syncs (e.g. a rasterised firebase.png replaced by a
/// vendored firebase.svg) - stem-only matching would treat the old
/// extension as still "claimed" by the id and leave it behind forever.
Future<void> _cleanStaleAssets({
  required String directory,
  required Set<String> keepFilenames,
  required Set<String> keepFiles,
  required bool dryRun,
}) async {
  final dir = Directory(directory);
  if (!dir.existsSync()) return;
  await for (final entity in dir.list()) {
    if (entity is! File) continue;
    final filename = entity.uri.pathSegments.last;
    if (keepFiles.contains(filename)) continue;
    if (keepFilenames.contains(filename)) continue;
    if (dryRun) {
      print('  would delete stale asset $filename');
      continue;
    }
    print('  deleting stale asset $filename');
    await entity.delete();
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

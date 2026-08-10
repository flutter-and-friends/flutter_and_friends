// ignore_for_file: avoid_print
// This is a standalone CLI script (not app code) - print is the intended
// way to report sync progress and failures to the person running it.
//
// Vendors the published schedule feed (sessions, speakers, day/track
// structure) from the website into this app's bundled snapshot asset. Run
// deliberately at release-prep time:
//
//   dart run tool/sync_schedule.dart
//
// This is NOT part of `flutter build` and must not become one - it hits
// the network, and CI/offline builds must not depend on that. What it
// writes (assets/schedule/schedule_snapshot.json) is committed to source
// control like any other bundled asset.
//
// Design: the bundled snapshot is a build-time seed for first launch with
// no cache and no network yet (see ScheduleDataCubit.init) - not a runtime
// cache. It is byte-identical in shape to the live feed (same wire format
// ScheduleRepository already parses for both), so this script does no
// parsing or transformation of its own - it fetches, validates the
// response is actually the feed, and writes the body through unchanged.
// The problem this solves is *drift* (the bundled seed silently going
// stale relative to the website's live feed, e.g. a removed session or new
// venue coordinates) - see the sibling tool/sync_sponsors.dart for the
// prior art this follows for sponsors/organizers.
//
// Kept as a separate script from sync_sponsors.dart rather than sharing a
// fetch/validate helper: the two feeds have different shapes to validate
// (sponsors validates+rewrites tier/organizer structure and downloads
// image assets; schedule validates+passes the body through verbatim) and
// different failure semantics (sponsors partially aborts per-half;
// schedule is all-or-nothing). The shared part - fetch, check content-type,
// parse the top-level version - is about a dozen lines; a shared
// abstraction would need to flex for both scripts' divergent write paths
// immediately, which is more machinery than the duplication it would
// remove. Revisit if a third feed sync shows up and the pattern repeats.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _defaultFeedUrl = 'https://flutterfriends.dev/schedule.json';
const _snapshotPath = 'assets/schedule/schedule_snapshot.json';

/// Supports `--feed-url=<url>` to point at a staging/local feed instead of
/// production (e.g. while the real feed isn't deployed yet, or to test
/// against a locally-served copy before deploy), and `--dry-run` to report
/// what would change without writing anything.
Future<void> main(List<String> args) async {
  var feedUrl = _defaultFeedUrl;
  var dryRun = false;
  for (final arg in args) {
    if (arg.startsWith('--feed-url=')) {
      feedUrl = arg.substring('--feed-url='.length);
    } else if (arg == '--dry-run') {
      dryRun = true;
    } else {
      stderr.writeln('sync_schedule: unrecognized argument "$arg"');
      exitCode = 1;
      return;
    }
  }

  final client = http.Client();
  try {
    await _sync(client, feedUrl: feedUrl, dryRun: dryRun);
  } on _SyncFailure catch (error) {
    stderr.writeln('sync_schedule: FAILED - ${error.message}');
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
    print('--dry-run: no files will be written.');
  }
  print('Fetching $feedUrl ...');
  final response = await client.get(Uri.parse(feedUrl));
  if (response.statusCode != 200) {
    throw _SyncFailure(
      'feed returned HTTP ${response.statusCode} - expected 200',
    );
  }

  final contentType = response.headers['content-type'] ?? '';
  final looksLikeJson = contentType.contains('json');
  // Firebase Hosting's SPA catch-all rewrite answers a not-yet-deployed (or
  // mistyped, or moved) feed path with HTTP 200 and the full app shell -
  // not a 404. Guard on content-type first; if that's inconclusive, sniff
  // the body, since a misconfigured host can serve valid JSON as
  // text/plain. Same guard as ScheduleRepository.fetchSchedule - refuse to
  // write anything on a non-JSON response.
  if (!looksLikeJson) {
    final trimmed = response.body.trimLeft();
    final sniffedAsHtml =
        trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<!doctype') ||
        trimmed.startsWith('<html');
    final sniffedAsJson = trimmed.startsWith('{') || trimmed.startsWith('[');
    if (sniffedAsHtml || !sniffedAsJson) {
      throw _SyncFailure(
        'feed did not return JSON (content-type: "$contentType"). This '
        "usually means the endpoint is serving the website's SPA fallback "
        'instead of the feed - confirm the website has deployed schedule.json and it is '
        'actually deployed before re-running.',
      );
    }
  }

  final Map<String, dynamic> feed;
  try {
    feed = jsonDecode(response.body) as Map<String, dynamic>;
  } on FormatException catch (error) {
    throw _SyncFailure('feed body is not valid JSON: $error');
  }

  final sessions = feed['sessions'];
  final speakers = feed['speakers'];
  final days = feed['days'];
  final version = feed['version'];
  if (sessions is! List) throw _SyncFailure('feed missing "sessions" array');
  if (speakers is! List) throw _SyncFailure('feed missing "speakers" array');
  if (days is! List) throw _SyncFailure('feed missing "days" array');
  if (version == null) throw _SyncFailure('feed missing "version"');

  final coordinateCount = sessions.cast<Map<String, dynamic>>().where((s) {
    final location = s['location'] as Map<String, dynamic>?;
    return location?['lat'] != null && location?['lng'] != null;
  }).length;

  if (dryRun) {
    print(
      'Would sync ${sessions.length} sessions, ${speakers.length} '
      'speakers, ${days.length} days, $coordinateCount with coordinates '
      '(feed version $version). No files written.',
    );
    return;
  }

  // Written through verbatim (re-encoded for stable indentation, not
  // reshaped) - the snapshot must parse with the exact same
  // ScheduleRepository code path as the live feed, so it must stay
  // byte-for-byte the same *shape*, not just similar.
  await File(
    _snapshotPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(feed));

  print(
    'Synced ${sessions.length} sessions, ${speakers.length} speakers, '
    '${days.length} days, $coordinateCount with coordinates (feed version '
    '$version) to $_snapshotPath.',
  );
}

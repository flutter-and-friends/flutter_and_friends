import 'dart:convert';

import 'package:flutter_and_friends/config/config.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:http/http.dart' as http;

/// Result of a successful feed fetch: the parsed [Schedule] plus the feed's
/// own staleness markers, so callers can cheaply decide whether a
/// previously-cached copy is out of date without re-parsing it.
class ScheduleFeedResult {
  const ScheduleFeedResult({
    required this.schedule,
    required this.speakers,
    required this.generatedAt,
    required this.version,
  });

  final Schedule schedule;

  /// Every speaker in the feed, not just those referenced by an [Event] -
  /// the speakers directory shows everyone, including speakers whose talk
  /// hasn't been scheduled yet. Sourced from the same fetch as [schedule]
  /// (the feed guarantees no dangling `speaker_slugs` within a single fetch), so
  /// this list and `schedule`'s events are always consistent with each
  /// other - never mix a speaker list from one fetch with events from
  /// another.
  final List<Speaker> speakers;

  final DateTime generatedAt;
  final String version;
}

/// Thrown when the remote schedule feed responds but its payload doesn't
/// match the shape this client understands (missing fields, wrong types,
/// unparseable dates...). Kept distinct from network failures so callers -
/// and error UI - can tell "you're offline" apart from "the app is out of
/// date and needs an update to read the new feed".
class ScheduleFormatException implements Exception {
  ScheduleFormatException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ScheduleFormatException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Thrown when the feed URL responds with HTTP 200 but a body that isn't
/// JSON at all - most commonly Firebase Hosting's SPA catch-all rewrite
/// serving `index.html` for a feed path that hasn't been deployed yet (or
/// was mistyped, or moved). This is deliberately kept out of
/// [ScheduleFormatException]: that type means "the feed is there and it's
/// JSON, but the shape is wrong" (a data/version problem), whereas this
/// means "there is no feed at this URL" (a deployment/routing problem).
/// Callers should treat this the same as a network failure for retry
/// purposes - it's just as likely to resolve itself on the next attempt
/// once the real feed is deployed, and it says nothing about the schedule
/// data itself.
class ScheduleUnavailableException implements Exception {
  ScheduleUnavailableException(this.message, this.url);

  final String message;
  final Uri url;

  @override
  String toString() => 'ScheduleUnavailableException: $message ($url)';
}

/// Fetches the conference schedule from the remote feed published by the conference website
/// and publishes.
///
/// This class only knows about the wire format (session/day/speaker JSON
/// documented on the website) and translates it into this app's own [Event] /
/// [Speaker] models. Nothing else in the app should parse that wire shape
/// directly - if the feed changes shape, this is the only file that should
/// need to change.
class ScheduleRepository {
  ScheduleRepository({
    http.Client? client,
    String? feedUrl,
    this.feedUrlResolver,
  }) : _client = client ?? http.Client(),
       _fixedFeedUrl = feedUrl;

  final http.Client _client;
  final String? _fixedFeedUrl;

  /// Resolves the feed URL fresh on every call rather than fixing it at
  /// construction time - lets a debug-only host override (see
  /// `SettingsCubit.debugUseLocalFeed`) take effect on the very next fetch
  /// instead of requiring the repository (and everything holding a
  /// reference to it) to be rebuilt. Defaults to always returning the fixed
  /// `feedUrl` / [scheduleFeedUrl] when not supplied.
  final String Function()? feedUrlResolver;

  String get _feedUrl =>
      feedUrlResolver?.call() ?? _fixedFeedUrl ?? scheduleFeedUrl;

  /// Fetches and parses the current schedule. Throws [http.ClientException]
  /// / [Exception] on network failure, [ScheduleUnavailableException] if the
  /// response isn't JSON at all (most commonly the feed not being deployed
  /// yet - see its doc comment), and [ScheduleFormatException] if it is
  /// JSON but doesn't match the expected shape. Callers are expected to
  /// fall back to a cached [Schedule] in any of these cases.
  Future<ScheduleFeedResult> fetchSchedule() async {
    final feedUrl = _feedUrl;
    final uri = Uri.parse(feedUrl);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Schedule feed returned HTTP ${response.statusCode}',
        uri,
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    final looksLikeJson = contentType.contains('json');
    // Firebase Hosting's SPA catch-all rewrite answers a not-yet-deployed
    // (or mistyped, or moved) feed path with HTTP 200 and the full app
    // shell - not a 404. That is indistinguishable from a real 200 by
    // status code alone, so a missing feed would otherwise reach `_parse`
    // and get misreported as a malformed payload. Guard on content-type
    // first; if that's inconclusive, sniff the body rather than trusting
    // the header alone, since a misconfigured host can serve valid JSON as
    // `text/plain`. Only reject when both signals point away from JSON -
    // stay permissive rather than brittle, but HTML is unambiguous either
    // way (an SPA shell starts with `<!DOCTYPE` or `<html`).
    if (!looksLikeJson) {
      final trimmed = response.body.trimLeft();
      final sniffedAsHtml =
          trimmed.startsWith('<!DOCTYPE') ||
          trimmed.startsWith('<!doctype') ||
          trimmed.startsWith('<html');
      final sniffedAsJson = trimmed.startsWith('{') || trimmed.startsWith('[');
      if (sniffedAsHtml || !sniffedAsJson) {
        throw ScheduleUnavailableException(
          'Schedule feed did not return JSON (content-type: '
          '"$contentType"). This usually means the endpoint is serving '
          "the website's SPA fallback instead of the feed - the feed is "
          'likely not deployed yet, mistyped, or moved.',
          uri,
        );
      }
    }

    return _parse(response.body);
  }

  /// Parses a schedule document in the same wire format as the live feed,
  /// but sourced from a build-time bundled asset (`assets/schedule/…`)
  /// instead of the network. Used to seed the schedule on first launch with
  /// no cache and no network yet - identical shape and identical ids to the
  /// live feed, so there is no separate id space to reconcile once the real
  /// fetch completes.
  ScheduleFeedResult parseSnapshot(String body) => _parse(body);

  ScheduleFeedResult _parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final speakersBySlug = <String, Speaker>{
        for (final raw in json['speakers'] as List)
          (raw as Map<String, dynamic>)['slug'] as String: _speakerFromWire(
            raw,
          ),
      };
      final trackLabelsByDay = _trackLabelsByDay(json['days'] as List);
      final events = <Event>[
        for (final raw in json['sessions'] as List)
          _eventFromWire(
            raw as Map<String, dynamic>,
            speakersBySlug,
            trackLabelsByDay,
          ),
      ];
      return ScheduleFeedResult(
        schedule: Schedule(events: events),
        speakers: speakersBySlug.values.toList(),
        generatedAt: _parseVenueWallClock(json['generated_at'] as String),
        version: json['version'].toString(),
      );
    } on ScheduleFormatException {
      rethrow;
    } on Exception catch (error) {
      throw ScheduleFormatException(
        'Could not parse schedule feed response',
        error,
      );
    }
  }

  Speaker _speakerFromWire(Map<String, dynamic> json) {
    final social = json['social'] as Map<String, dynamic>?;
    return Speaker(
      slug: json['slug'] as String,
      name: json['name'] as String,
      title: json['role'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      photoUrl: json['photo'] as String?,
      github: social?['github'] as String?,
      bluesky: social?['bluesky'] as String?,
      linkedin: social?['linkedin'] as String?,
      website: social?['website'] as String?,
    );
  }

  /// Builds a day-scoped track id → label lookup from the feed's
  /// `days[].tracks` array (each entry `{"id": ..., "label": ...}`).
  ///
  /// Scoped per day rather than merged into one global map: the wire
  /// contract nests tracks under each day on purpose, and track ids are
  /// only guaranteed unique *within* a day (today's ids happen to be
  /// globally unique too, but nothing in the contract promises that will
  /// stay true - e.g. a future day could reuse `"main"` for a different
  /// room). Scoping per day means such a collision would be handled
  /// correctly for free instead of silently mislabelling one of the two
  /// days.
  Map<String, Map<String, String>> _trackLabelsByDay(List<dynamic> days) {
    return {
      for (final raw in days)
        (raw as Map<String, dynamic>)['date'] as String: {
          for (final rawTrack in raw['tracks'] as List)
            (rawTrack as Map<String, dynamic>)['id'] as String:
                rawTrack['label'] as String,
        },
    };
  }

  Event _eventFromWire(
    Map<String, dynamic> json,
    Map<String, Speaker> speakersBySlug,
    Map<String, Map<String, String>> trackLabelsByDay,
  ) {
    final id = json['id'] as String;
    final name = json['title'] as String;
    final start = _parseVenueWallClock(json['start'] as String);
    final durationMinutes = json['duration_minutes'] as int;
    final duration = Duration(minutes: durationMinutes);
    final location = _locationFromWire(json, trackLabelsByDay);
    final speakerSlugs = (json['speaker_slugs'] as List?) ?? const [];
    final speakers = [
      for (final slug in speakerSlugs)
        if (speakersBySlug[slug as String] case final speaker?) speaker,
    ];
    final description = json['description'] as String? ?? '';

    switch (json['type']) {
      case 'talk':
        return Talk(
          id: id,
          name: name,
          speakers: speakers,
          duration: duration,
          startTime: start,
          location: location,
          description: description,
        );
      case 'workshop':
        return Workshop(
          id: id,
          name: name,
          speakers: speakers,
          duration: duration,
          startTime: start,
          location: location,
          description: description,
        );
      case 'activity':
        return Activity(
          id: id,
          name: name,
          duration: duration,
          startTime: start,
          location: location,
          description: description.isEmpty ? null : description,
        );
      default:
        throw ScheduleFormatException(
          'Unknown session type "${json['type']}" for session "$id"',
        );
    }
  }

  static final _offsetPattern = RegExp(r'([+-])(\d{2}):?(\d{2})$');

  /// Parses an ISO-8601 instant that carries an explicit UTC offset (e.g.
  /// `2026-09-03T13:00:00+02:00`) and returns a [DateTime] whose calendar
  /// fields (`.hour`, `.day`, ...) read as the *venue's* wall-clock time,
  /// rather than the device's local time or raw UTC.
  ///
  /// `DateTime.parse` on an offset-bearing string returns a correct UTC
  /// instant, but every display path in this app (`TimeOfDay.fromDateTime`,
  /// day-grouping in [Schedule.days], ...) reads `.hour`/`.day` directly
  /// without ever calling `.toLocal()`. Left alone that renders the feed's
  /// UTC hour on every device regardless of its timezone or the venue's -
  /// a schedule should read in venue wall-clock time (a conference
  /// attendee checking from home, or a phone that hasn't picked up the
  /// new zone, shouldn't see a shifted schedule). Since the feed always
  /// states its own offset, we can restore the wall-clock fields by adding
  /// that offset back onto the UTC instant, without needing a timezone
  /// database. This is the single point where that happens - callers
  /// throughout the app can keep reading `.hour`/`.day` directly.
  static DateTime _parseVenueWallClock(String iso) {
    final parsed = DateTime.parse(iso);
    if (!parsed.isUtc) return parsed;
    final match = _offsetPattern.firstMatch(iso);
    if (match == null) return parsed;
    final sign = match.group(1) == '-' ? -1 : 1;
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3)!);
    return parsed.add(Duration(hours: hours, minutes: minutes) * sign);
  }

  Location? _locationFromWire(
    Map<String, dynamic> json,
    Map<String, Map<String, String>> trackLabelsByDay,
  ) {
    // Track = the room (within the venue), Location = the building/venue
    // itself. The two are not in conflict - the feed deliberately emits both
    // for some conference-day sessions rather than collapsing them - so
    // both are shown when present, composed as "Room · Venue". A session
    // can carry either alone (workshop day: track only; social day: venue
    // only) or neither (renders no location row at all).
    String? trackLabel;
    final track = json['track'] as String?;
    if (track != null) {
      final day = json['day'] as String?;
      final label = trackLabelsByDay[day]?[track];
      // A session referencing a track not in its day's list is a feed
      // defect (the website's generator hard-errors on this),
      // but if it ever slips through, don't fabricate a label - no
      // location is preferable to a wrong one, consistent with the
      // location fix already shipped.
      if (label != null) trackLabel = label;
    }

    final rawLocation = json['location'] as Map<String, dynamic>?;
    final venueName = rawLocation?['name'] as String?;
    final lat = (rawLocation?['lat'] as num?)?.toDouble();
    final lng = (rawLocation?['lng'] as num?)?.toDouble();
    final coordinates = (lat != null && lng != null) ? (lat, lng) : null;

    final name = switch ((trackLabel, venueName)) {
      (final track?, final venue?) => '$track · $venue',
      (final track?, null) => track,
      (null, final venue?) => venue,
      (null, null) => null,
    };
    if (name == null) return null;
    return Location(name: name, coordinates: coordinates);
  }
}

import 'package:flutter_and_friends/schedule/schedule.dart';

interface class Event {
  const Event({
    required this.id,
    required this.name,
    required this.duration,
    required this.startTime,
    required this.location,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'activity':
        return Activity.fromJson(json);
      case 'talk':
        return Talk.fromJson(json);
      case 'workshop':
        return Workshop.fromJson(json);
      default:
        throw UnsupportedError('Unsupported event type: "$type"');
    }
  }

  static Map<String, dynamic> toJson(Event event) {
    if (event is Activity) {
      return {'type': 'activity', ...event.toJson()};
    }
    if (event is Talk) {
      return {'type': 'talk', ...event.toJson()};
    }
    if (event is Workshop) {
      return {'type': 'workshop', ...event.toJson()};
    }
    throw UnsupportedError('Unsupported event type: "$event"');
  }

  /// Stable, unique identifier for this event.
  ///
  /// This is the identity used for equality-sensitive operations such as
  /// favouriting - it must stay the same even if every other field (title,
  /// description, time...) is edited upstream. Authored and assigned by the
  /// remote schedule feed (the website's authored session id) - never derived from other
  /// fields on this side, and never regenerated. An [Event] with no real id
  /// is a bug at the call site, not something to paper over here.
  final String id;
  final String name;
  final Duration duration;
  final DateTime startTime;
  final Location? location;
}

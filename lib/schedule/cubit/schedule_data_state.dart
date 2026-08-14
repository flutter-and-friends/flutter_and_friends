part of 'schedule_data_cubit.dart';

enum ScheduleDataStatus { initial, loading, loaded, error }

class ScheduleDataState extends Equatable {
  const ScheduleDataState({
    this.status = ScheduleDataStatus.initial,
    this.schedule = Schedule.empty,
    this.speakers = const [],
    this.generatedAt,
    this.version,
    this.errorMessage,
  });

  final ScheduleDataStatus status;
  final Schedule schedule;

  /// Every speaker from the same fetch as [schedule] - see
  /// [ScheduleFeedResult.speakers]. Kept on this same state object (rather
  /// than a separate cubit) deliberately, so the two can never be replaced
  /// independently and end up mismatched across a version boundary.
  final List<Speaker> speakers;

  /// From the feed's `generated_at` - when the website last regenerated it.
  final DateTime? generatedAt;

  /// From the feed's `version` - a content hash over the whole serialized
  /// feed (with `generated_at` excluded), cheap to compare to detect
  /// staleness without re-fetching. It is NOT monotonic and NOT a counter:
  /// it can move in either direction between builds, or even revert to a
  /// value seen before if content reverts. The only valid comparison is
  /// equality (`==`/`!=`); never compare with `<`/`>`, and never assume a
  /// "newer" or "older" ordering from it.
  final String? version;

  final String? errorMessage;

  /// True when the last fetch attempt failed but we still have schedule
  /// data to show (from cache or an earlier successful fetch) - the UI
  /// should show that data plus a non-blocking "couldn't refresh" notice,
  /// rather than a full error screen.
  bool get isStale =>
      status == ScheduleDataStatus.error && schedule.events.isNotEmpty;

  ScheduleDataState copyWith({
    ScheduleDataStatus? status,
    Schedule? schedule,
    List<Speaker>? speakers,
    DateTime? generatedAt,
    String? version,
    String? errorMessage,
  }) {
    return ScheduleDataState(
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
      speakers: speakers ?? this.speakers,
      generatedAt: generatedAt ?? this.generatedAt,
      version: version ?? this.version,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    schedule,
    speakers,
    generatedAt,
    version,
    errorMessage,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/speakers/speakers.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'schedule_data_state.dart';

/// Path of the build-time schedule snapshot bundled as a Flutter asset -
/// same wire format as the live feed (see [ScheduleRepository]), generated
/// alongside it so ids match exactly and there is no separate seed id
/// space. Only ever read on first launch with an empty cache and no
/// network yet.
const _bundledSnapshotAsset = 'assets/schedule/schedule_snapshot.json';

/// Owns the schedule data itself (as opposed to [ScheduleCubit], which only
/// tracks which tab is selected).
///
/// Strategy: cache -> bundled snapshot -> network, always-latest. On
/// construction the cubit starts out from whatever [HydratedCubit] last
/// persisted. If that's empty (fresh install, or storage cleared), [init]
/// falls back to the bundled build-time snapshot asset so the schedule
/// screen is never empty on first launch - even offline, which is common at
/// a conference venue. A network fetch always runs after that and, on
/// success, replaces the state (cache or snapshot) and gets persisted; on
/// failure the previous state is kept and flagged via
/// [ScheduleDataState.isStale].
class ScheduleDataCubit extends HydratedCubit<ScheduleDataState> {
  ScheduleDataCubit({ScheduleRepository? repository})
    : _repository = repository ?? ScheduleRepository(),
      super(const ScheduleDataState());

  final ScheduleRepository _repository;

  /// The bundled snapshot's own `version`, read once regardless of whether
  /// it was actually used to seed [state] (cache may already have won) -
  /// kept purely so [fetchSchedule] can debug-log when the live feed has
  /// moved on from what's baked into this build. See
  /// `tool/sync_schedule.dart`, which is what should be re-run when this
  /// fires.
  String? _bundledSnapshotVersion;

  /// Loads the bundled snapshot if nothing was restored from cache, then
  /// always attempts a network refresh. Call once, right after
  /// construction.
  Future<void> init() async {
    if (state.schedule.events.isEmpty) {
      await _loadBundledSnapshot();
    } else if (kDebugMode) {
      // Cache already won the seed race, but still read the snapshot's
      // version so a later fetch can compare against it - see
      // _bundledSnapshotVersion's doc comment.
      await _readBundledSnapshotVersion();
    }
    await fetchSchedule();
  }

  Future<void> _readBundledSnapshotVersion() async {
    try {
      final body = await rootBundle.loadString(_bundledSnapshotAsset);
      _bundledSnapshotVersion = _repository.parseSnapshot(body).version;
    } on Exception {
      // No usable bundled snapshot - nothing to compare against later,
      // same as the silent-miss handling in _loadBundledSnapshot below.
    }
  }

  Future<void> _loadBundledSnapshot() async {
    try {
      final body = await rootBundle.loadString(_bundledSnapshotAsset);
      final result = _repository.parseSnapshot(body);
      _bundledSnapshotVersion = result.version;
      emit(
        ScheduleDataState(
          status: ScheduleDataStatus.loaded,
          schedule: result.schedule,
          speakers: result.speakers,
          generatedAt: result.generatedAt,
          version: result.version,
        ),
      );
    } on Exception catch (error) {
      // No usable bundled snapshot (missing/malformed asset). Not fatal -
      // the screen shows its loading/error state until the network fetch
      // below resolves, same as it would with no seed at all.
      debugPrint('Could not load bundled schedule snapshot: $error');
    }
  }

  Future<void> fetchSchedule() async {
    emit(state.copyWith(status: ScheduleDataStatus.loading));
    try {
      final result = await _repository.fetchSchedule();
      if (kDebugMode &&
          _bundledSnapshotVersion != null &&
          _bundledSnapshotVersion != result.version) {
        // Developer-facing only, never user-facing: the bundled snapshot
        // lagging the live feed is completely normal (it's a build-time
        // artifact and the live feed is always meant to supersede it) -
        // this exists purely to catch "we forgot to re-sync before cutting
        // a release". Re-run tool/sync_schedule.dart to clear it.
        debugPrint(
          'Schedule snapshot is stale: bundled version '
          '$_bundledSnapshotVersion != live feed version ${result.version}. '
          'Run `dart run tool/sync_schedule.dart` to refresh it.',
        );
      }
      emit(
        ScheduleDataState(
          status: ScheduleDataStatus.loaded,
          schedule: result.schedule,
          speakers: result.speakers,
          generatedAt: result.generatedAt,
          version: result.version,
        ),
      );
    } on Exception catch (error) {
      // Network failure or a malformed payload both land here - either way
      // we keep whatever schedule we already had (cache or seed) and
      // surface the error message for a non-blocking "couldn't refresh"
      // notice rather than blanking the screen.
      emit(
        state.copyWith(
          status: ScheduleDataStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  ScheduleDataState? fromJson(Map<String, dynamic> json) {
    try {
      final events = [
        ...(json['events'] as List).map(
          (e) => Event.fromJson(e as Map<String, dynamic>),
        ),
      ];
      final speakers = [
        ...(json['speakers'] as List? ?? const []).map(
          (s) => Speaker.fromJson(s as Map<String, dynamic>),
        ),
      ];
      return ScheduleDataState(
        status: ScheduleDataStatus.loaded,
        schedule: Schedule(events: events),
        speakers: speakers,
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : null,
        version: json['version'] as String?,
      );
    } on Exception {
      // Malformed/old cache shape - return null so HydratedCubit starts
      // from the initial (empty) state instead, and `init` falls back to
      // the bundled snapshot rather than crashing the app on launch.
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ScheduleDataState state) {
    return {
      'events': state.schedule.events.map(Event.toJson).toList(),
      'speakers': state.speakers.map((s) => s.toJson()).toList(),
      'generatedAt': state.generatedAt?.toIso8601String(),
      'version': state.version,
    };
  }
}

part of 'settings_cubit.dart';

final class SettingsState extends Equatable {
  const SettingsState({
    required this.version,
    this.patchNumber,
    this.debugUseLocalFeed = false,
    this.debugFeedHost,
  });

  final Version version;
  final int? patchNumber;

  /// Debug-only override: when true, the schedule repository fetches from
  /// [effectiveDebugFeedHost] instead of the production `scheduleFeedUrl`.
  /// Only ever honoured when `kDebugMode` is also true (checked at the call
  /// site building the feed URL resolver) so this can't leak into a release
  /// build even if a stale persisted value carries over.
  final bool debugUseLocalFeed;

  /// The user-edited host, or null if never edited (falls back to
  /// [defaultDebugFeedHost] via [effectiveDebugFeedHost]).
  final String? debugFeedHost;

  /// The host actually used when [debugUseLocalFeed] is on - never empty.
  String get effectiveDebugFeedHost =>
      (debugFeedHost != null && debugFeedHost!.trim().isNotEmpty)
      ? debugFeedHost!.trim()
      : defaultDebugFeedHost;

  /// The full feed URL that would be used right now given the current
  /// debug override state - shown in the UI so an active override is never
  /// silently invisible.
  String get effectiveFeedUrl => debugUseLocalFeed
      ? '$effectiveDebugFeedHost/schedule.json'
      : scheduleFeedUrl;

  SettingsState copyWith({
    Version? version,
    int? patchNumber,
    bool? debugUseLocalFeed,
    String? debugFeedHost,
  }) {
    return SettingsState(
      version: version ?? this.version,
      patchNumber: patchNumber ?? this.patchNumber,
      debugUseLocalFeed: debugUseLocalFeed ?? this.debugUseLocalFeed,
      debugFeedHost: debugFeedHost ?? this.debugFeedHost,
    );
  }

  @override
  List<Object?> get props => [
    version,
    patchNumber,
    debugUseLocalFeed,
    debugFeedHost,
  ];
}

part of 'sponsors_cubit.dart';

enum SponsorsStatus { initial, loading, loaded, error }

class SponsorsState extends Equatable {
  const SponsorsState({
    this.status = SponsorsStatus.initial,
    this.tiers = const [],
    this.version,
    this.errorMessage,
  });

  final SponsorsStatus status;
  final List<SponsorTier> tiers;

  /// From the vendored feed's `version` at the time `tool/sync_sponsors.dart`
  /// last ran - a content-hash, not a live staleness signal (there is no
  /// runtime fetch to compare it against).
  final int? version;

  final String? errorMessage;

  SponsorsState copyWith({
    SponsorsStatus? status,
    List<SponsorTier>? tiers,
    int? version,
    String? errorMessage,
  }) {
    return SponsorsState(
      status: status ?? this.status,
      tiers: tiers ?? this.tiers,
      version: version ?? this.version,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tiers, version, errorMessage];
}

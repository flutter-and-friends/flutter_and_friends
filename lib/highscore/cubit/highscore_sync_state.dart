part of 'highscore_sync_cubit.dart';

enum HighscoreSyncStatus {
  /// Nothing has been attempted yet in this session.
  idle,

  /// A submission is on its way to the server.
  syncing,

  /// The highscore holds what this device last wanted to publish.
  synced,

  /// The latest submission could not be published (typically offline
  /// before the device ever signed in).
  failure,
}

class HighscoreSyncState extends Equatable {
  const HighscoreSyncState({
    this.status = HighscoreSyncStatus.idle,
    this.published,
  });

  final HighscoreSyncStatus status;

  /// What the highscore holds for this device as far as this session knows,
  /// or null when the device has not published anything yet.
  final HighscoreSubmission? published;

  HighscoreSyncState copyWith({HighscoreSyncStatus? status}) {
    return HighscoreSyncState(
      status: status ?? this.status,
      published: published,
    );
  }

  @override
  List<Object?> get props => [status, published];
}

part of 'highscore_cubit.dart';

enum HighscoreStatus { initial, loading, loaded, error }

class HighscoreState extends Equatable {
  const HighscoreState({
    this.status = HighscoreStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  final HighscoreStatus status;

  /// The board, best first.
  final List<HighscoreEntry> entries;

  /// The most recent failure, if any.
  final String? errorMessage;

  /// This device's position on the board, starting at 1, or null while it
  /// is not on it.
  int? get myRank {
    final index = entries.indexWhere((entry) => entry.isMine);
    return index == -1 ? null : index + 1;
  }

  HighscoreState copyWith({
    HighscoreStatus? status,
    List<HighscoreEntry>? entries,
    String? errorMessage,
  }) {
    return HighscoreState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, entries, errorMessage];
}

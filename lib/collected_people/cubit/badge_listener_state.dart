part of 'badge_listener_cubit.dart';

/// A badge tap handled by the app-wide listener.
class BadgeCollected extends Equatable {
  const BadgeCollected({
    required this.person,
    required this.isNew,
    required this.isOwn,
    required this.sequence,
  });

  /// The dex entry as it stands after the tap, or the tapped person when
  /// [isOwn].
  final CollectedPerson person;

  /// Whether the tap added a new entry (rather than updating one).
  final bool isNew;

  /// Whether the tapped badge is this installation's own badge, which is
  /// never added to the dex.
  final bool isOwn;

  /// Increments per tap so repeated taps of the same badge are distinct
  /// states.
  final int sequence;

  @override
  List<Object?> get props => [person, isNew, isOwn, sequence];
}

class BadgeListenerState extends Equatable {
  const BadgeListenerState({this.listening = false, this.lastCollected});

  /// Whether a continuous NFC session is currently held.
  final bool listening;

  /// The most recent tap, for the UI to announce.
  final BadgeCollected? lastCollected;

  BadgeListenerState copyWith({
    bool? listening,
    BadgeCollected? lastCollected,
  }) {
    return BadgeListenerState(
      listening: listening ?? this.listening,
      lastCollected: lastCollected ?? this.lastCollected,
    );
  }

  @override
  List<Object?> get props => [listening, lastCollected];
}

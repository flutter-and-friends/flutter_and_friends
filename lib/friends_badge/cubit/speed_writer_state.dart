part of 'speed_writer_cubit.dart';

enum SpeedWriterStatus {
  /// No roster loaded yet.
  empty,

  /// The current person's badge is being composed.
  composing,

  /// The current person's badge is ready to be written.
  ready,

  /// Every person in the roster has been written.
  done,
}

class SpeedWriterState extends Equatable {
  const SpeedWriterState({
    this.status = SpeedWriterStatus.empty,
    this.entries = const [],
    this.index = 0,
    this.font = BadgeFont.display,
    this.asset,
    this.badgeId,
    this.badge,
    this.writtenIndices = const {},
    this.error,
    this.errorCount = 0,
  });

  final SpeedWriterStatus status;
  final List<BadgeRosterEntry> entries;

  /// Position of the current person in [entries].
  final int index;

  /// The font drawn for the current person.
  final BadgeFont font;

  /// The capybara asset drawn for the current person, see [kCapybaraAssets].
  final String? asset;

  /// The fresh UUID written as the current badge's ID.
  final String? badgeId;

  /// The composed badge for the current person, once ready.
  final FriendsBadge? badge;

  /// Indices in [entries] whose badge has been written this session.
  final Set<int> writtenIndices;

  /// The latest error message, shown once per [errorCount] change.
  final String? error;
  final int errorCount;

  BadgeRosterEntry? get current =>
      index < entries.length ? entries[index] : null;

  bool get hasPrevious => index > 0;

  bool get hasNext => index + 1 < entries.length;

  bool get isCurrentWritten => writtenIndices.contains(index);

  /// The capybara ID for the current asset, written to the badge's NDEF
  /// record.
  String? get capybaraId => capybaraIdForAsset(asset);

  SpeedWriterState copyWith({
    SpeedWriterStatus? status,
    List<BadgeRosterEntry>? entries,
    int? index,
    BadgeFont? font,
    String? asset,
    String? badgeId,
    FriendsBadge? badge,
    bool clearBadge = false,
    Set<int>? writtenIndices,
    String? error,
    int? errorCount,
  }) {
    return SpeedWriterState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      index: index ?? this.index,
      font: font ?? this.font,
      asset: asset ?? this.asset,
      badgeId: badgeId ?? this.badgeId,
      badge: clearBadge ? null : badge ?? this.badge,
      writtenIndices: writtenIndices ?? this.writtenIndices,
      error: error ?? this.error,
      errorCount: errorCount ?? this.errorCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    index,
    font,
    asset,
    badgeId,
    badge,
    writtenIndices,
    error,
    errorCount,
  ];
}

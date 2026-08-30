import 'package:equatable/equatable.dart';

/// Must match the limit in `firestore.rules`.
const maxHighscoreNameLength = 60;

/// One row on the highscore: a device, the name on its badge and how many
/// people it has collected.
class HighscoreEntry extends Equatable {
  const HighscoreEntry({
    required this.id,
    required this.name,
    required this.count,
    required this.isMine,
  });

  factory HighscoreEntry.fromDocument({
    required String id,
    required Map<String, dynamic> data,
    required String currentUserId,
  }) {
    return HighscoreEntry(
      id: id,
      name: data['name'] as String? ?? '',
      count: (data['count'] as num?)?.toInt() ?? 0,
      isMine: id == currentUserId,
    );
  }

  /// The anonymous user id of the device that collected the people.
  final String id;
  final String name;

  /// How many people the device has collected.
  final int count;

  /// Whether this is the entry published by this device.
  final bool isMine;

  @override
  List<Object?> get props => [id, name, count, isMine];
}

/// Sorts [entries] by [HighscoreEntry.count] descending, then by name, then
/// by id, so two people on equal counts always keep the same relative order.
List<HighscoreEntry> rankHighscores(List<HighscoreEntry> entries) {
  return [...entries]..sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  });
}

/// What this device publishes to the highscore: the name on its badge and
/// the number of people it has collected.
class HighscoreSubmission extends Equatable {
  const HighscoreSubmission({required this.name, required this.count});

  /// Builds the submission from the raw badge name: trimmed and cut to the
  /// length the rules accept. The name is empty when the badge has none,
  /// in which case there is nothing to publish.
  factory HighscoreSubmission.from({
    required String badgeName,
    required int count,
  }) {
    final trimmed = badgeName.trim();
    return HighscoreSubmission(
      name: trimmed.length > maxHighscoreNameLength
          ? trimmed.substring(0, maxHighscoreNameLength).trim()
          : trimmed,
      count: count,
    );
  }

  final String name;
  final int count;

  bool get hasName => name.isNotEmpty;

  @override
  List<Object?> get props => [name, count];
}

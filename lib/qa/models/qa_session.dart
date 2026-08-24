import 'package:equatable/equatable.dart';

/// A session that collects audience questions ahead of, and during, the
/// session itself.
class QaSession extends Equatable {
  const QaSession({
    required this.id,
    required this.title,
    required this.panelists,
  });

  /// The session id as authored by the schedule feed, so the Q&A can be
  /// linked to its entry in the schedule.
  final String id;
  final String title;
  final List<String> panelists;

  /// The panelists as a sentence fragment, e.g. "Alice and Bob".
  String get panelistsLabel {
    if (panelists.length <= 1) return panelists.join();
    final allButLast = panelists.sublist(0, panelists.length - 1);
    return '${allButLast.join(', ')} and ${panelists.last}';
  }

  @override
  List<Object> get props => [id, title, panelists];
}

/// The session this app currently collects audience questions for.
const flutterCoreTeamQaSession = QaSession(
  id: 'qa-with-the-flutter-core-team',
  title: 'Q&A with the Flutter Core Team',
  panelists: ['Michael Thomsen', 'Emma Twersky'],
);

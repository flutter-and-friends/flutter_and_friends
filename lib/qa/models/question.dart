import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A question asked by an attendee, as read from a Firestore question
/// document: the question itself plus how it relates to the current user
/// ([hasVoted], [isMine]).
class Question extends Equatable {
  const Question({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.voteCount,
    required this.hasVoted,
    required this.isMine,
    this.authorName,
  });

  factory Question.fromDocument({
    required String id,
    required Map<String, dynamic> data,
    required String currentUserId,
  }) {
    final voterIds = [...(data['voterIds'] as List? ?? const [])];
    // A question this device just asked shows up in the local snapshot
    // before the server has stamped its creation time, so it has none yet.
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    return Question(
      id: id,
      body: data['body'] as String,
      authorName: data['authorName'] as String?,
      createdAt: createdAt ?? DateTime.now(),
      voteCount: voterIds.length,
      hasVoted: voterIds.contains(currentUserId),
      isMine: data['authorId'] == currentUserId,
    );
  }

  final String id;
  final String body;

  /// The name the asker chose to attach, or null for an anonymous question.
  final String? authorName;
  final DateTime createdAt;
  final int voteCount;

  /// Whether the current user has upvoted this question.
  final bool hasVoted;

  /// Whether the current user asked this question.
  final bool isMine;

  @override
  List<Object?> get props => [
    id,
    body,
    authorName,
    createdAt,
    voteCount,
    hasVoted,
    isMine,
  ];
}

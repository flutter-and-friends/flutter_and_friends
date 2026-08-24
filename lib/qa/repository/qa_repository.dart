import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_and_friends/qa/qa.dart';

/// Talks to the Firestore collections that store audience questions and
/// votes (security rules in `firestore.rules`). Nothing else in the
/// app should know about collection or field names; if the data model
/// changes, this is the only file that should need to change.
///
/// Users are identified by an anonymous Firebase Auth account created on
/// first use (see [signIn]); the security rules tie every question and vote
/// to that identity, so nobody can vote twice or act on behalf of someone
/// else. Votes are stored as the list of voter ids on the question itself,
/// which keeps a vote a single atomic write, makes the count free, and lets
/// the rules verify that a voter only ever adds or removes themselves.
class QaRepository {
  QaRepository({required this._auth, required this._firestore});

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Makes sure the app has an identity to ask and vote with. Firebase Auth
  /// persists the account, so this only creates a new anonymous user on the
  /// very first call on a given install.
  Future<void> signIn() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  /// Emits the full list of questions for [sessionId] whenever any of them
  /// changes, including this device's own pending writes, so the screen
  /// updates instantly and stays in sync with everyone else.
  Stream<List<Question>> watchQuestions(String sessionId) {
    final userId = _requireUserId();
    return _questions(sessionId).snapshots().map(
      (snapshot) => [
        for (final document in snapshot.docs)
          Question.fromDocument(
            id: document.id,
            data: document.data(),
            currentUserId: userId,
          ),
      ],
    );
  }

  Future<void> askQuestion({
    required String sessionId,
    required String body,
    String? authorName,
  }) {
    return _questions(sessionId).add({
      'body': body,
      'authorId': _requireUserId(),
      'authorName': ?authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'voterIds': <String>[],
    });
  }

  Future<void> deleteQuestion({
    required String sessionId,
    required String questionId,
  }) {
    return _questions(sessionId).doc(questionId).delete();
  }

  Future<void> upvote({required String sessionId, required String questionId}) {
    return _questions(sessionId).doc(questionId).update({
      'voterIds': FieldValue.arrayUnion([_requireUserId()]),
    });
  }

  Future<void> removeUpvote({
    required String sessionId,
    required String questionId,
  }) {
    return _questions(sessionId).doc(questionId).update({
      'voterIds': FieldValue.arrayRemove([_requireUserId()]),
    });
  }

  CollectionReference<Map<String, dynamic>> _questions(String sessionId) {
    return _firestore
        .collection('qa_sessions')
        .doc(sessionId)
        .collection('questions');
  }

  String _requireUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('QaRepository used before signIn() completed');
    }
    return user.uid;
  }
}

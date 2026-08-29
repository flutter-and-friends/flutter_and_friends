import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_and_friends/pub_quiz/models/models.dart';

/// Thrown when an answer is refused, which happens when the question closed
/// before the answer reached the server (or the device was offline and the
/// write only went out later).
class PubQuizAnswerRejected implements Exception {
  const PubQuizAnswerRejected();
}

/// Talks to the Firestore documents behind the pub quiz (security rules in
/// `firestore.rules`). Nothing else in the app should know about collection
/// or field names.
///
/// The conference website's server owns the quiz: it publishes questions,
/// closes them, scores the answers and moves the phase forward. This device
/// only reads that state, creates its own team (keyed by the anonymous user
/// id, see [signIn]) and submits one answer per question. The answer is
/// stamped with the server's clock so the "fastest correct" bonus cannot be
/// gamed by a phone with a wrong time.
class PubQuizRepository {
  PubQuizRepository({
    required this.quizId,
    required this._auth,
    required this._firestore,
  });

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String quizId;

  /// Makes sure the device has an identity to play with. Firebase Auth
  /// persists the account, so this only creates a new anonymous user on
  /// the very first call on a given install.
  Future<void> signIn() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  /// Emits the quiz whenever the server changes it, or null while the
  /// organizers have not set it up yet.
  Stream<PubQuiz?> watchQuiz() {
    return _quiz.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return PubQuiz.fromDocument(id: snapshot.id, data: data);
    });
  }

  Stream<List<PubQuizTeam>> watchTeams() {
    final userId = _requireUserId();
    return _teams.snapshots().map(
      (snapshot) => [
        for (final document in snapshot.docs)
          PubQuizTeam.fromDocument(
            id: document.id,
            data: document.data(),
            currentUserId: userId,
          ),
      ],
    );
  }

  /// Emits this device's answer to [questionId], or null until it has
  /// answered. Includes the device's own pending write, so the choice shows
  /// as locked in immediately.
  Stream<PubQuizAnswer?> watchMyAnswer(String questionId) {
    return _answer(questionId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return PubQuizAnswer(
        questionId: questionId,
        choice: (data['choice'] as num).toInt(),
      );
    });
  }

  Future<void> createTeam(String name) {
    return _teams.doc(_requireUserId()).set({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> renameTeam(String name) {
    return _teams.doc(_requireUserId()).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Submits [choice] for [questionId]. Throws [PubQuizAnswerRejected] when
  /// the server refuses it because the question is no longer open.
  Future<void> submitAnswer({
    required String questionId,
    required int choice,
  }) async {
    try {
      await _answer(questionId).set({
        'choice': choice,
        'answeredAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const PubQuizAnswerRejected();
      }
      rethrow;
    }
  }

  DocumentReference<Map<String, dynamic>> get _quiz =>
      _firestore.collection('pub_quizzes').doc(quizId);

  CollectionReference<Map<String, dynamic>> get _teams =>
      _quiz.collection('teams');

  DocumentReference<Map<String, dynamic>> _answer(String questionId) {
    return _quiz
        .collection('questions')
        .doc(questionId)
        .collection('answers')
        .doc(_requireUserId());
  }

  String _requireUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('PubQuizRepository used before signIn() completed');
    }
    return user.uid;
  }
}

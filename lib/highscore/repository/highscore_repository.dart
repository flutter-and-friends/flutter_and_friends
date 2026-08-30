import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_and_friends/highscore/models/models.dart';

/// Talks to the Firestore collection behind the highscore (security rules
/// in `firestore.rules`). Nothing else in the app should know about
/// collection or field names.
///
/// Every device owns exactly one document, keyed by its anonymous user id
/// (see [signIn]), holding the name on its badge and how many people it has
/// collected. The count is what the device reports; the collected people
/// themselves never leave the phone.
class HighscoreRepository {
  HighscoreRepository({required this._auth, required this._firestore});

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Makes sure the device has an identity to publish with. Firebase Auth
  /// persists the account, so this only creates a new anonymous user on
  /// the very first call on a given install.
  Future<void> signIn() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  /// Emits the top [limit] entries, best first, whenever any of them
  /// changes. Devices that have not collected anyone yet are left out.
  Stream<List<HighscoreEntry>> watchHighscores({int limit = 100}) {
    final userId = _requireUserId();
    return _highscores
        .where('count', isGreaterThan: 0)
        .orderBy('count', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => rankHighscores([
            for (final document in snapshot.docs)
              HighscoreEntry.fromDocument(
                id: document.id,
                data: document.data(),
                currentUserId: userId,
              ),
          ]),
        );
  }

  /// Publishes this device's entry, replacing whatever it published before.
  Future<void> submit(HighscoreSubmission submission) {
    return _highscores.doc(_requireUserId()).set({
      'name': submission.name,
      'count': submission.count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Takes this device off the highscore.
  Future<void> remove() => _highscores.doc(_requireUserId()).delete();

  CollectionReference<Map<String, dynamic>> get _highscores =>
      _firestore.collection('highscores');

  String _requireUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('HighscoreRepository used before signIn() completed');
    }
    return user.uid;
  }
}

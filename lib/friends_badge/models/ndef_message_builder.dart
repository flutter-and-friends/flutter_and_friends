import 'package:friends_badge/friends_badge.dart';

/// Builds the NDEF payload for a badge write, or `null` when the user did
/// not supply a link.
///
/// Wire contract (decided by `friends-badge-ndef`): the message contains a
/// well-known URI record plus a Text record reading
/// `Name · Role · url`, separated by space + U+00B7 MIDDLE DOT + space, with
/// the URL bare as typed (no scheme added). An empty [url] means "no NDEF
/// write" — callers must not write an empty message, so this returns `null`.
NdefMessage? buildBadgeNdefMessage({
  required String name,
  required String role,
  required String url,
}) {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) return null;

  return NdefMessage([
    NdefRecord.uri(Uri.parse(trimmedUrl)),
    NdefRecord.text('$name · $role · $trimmedUrl'),
  ]);
}

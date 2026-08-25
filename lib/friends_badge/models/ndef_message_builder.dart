import 'package:friends_badge/friends_badge.dart';

/// Builds the NDEF payload for a badge write, or `null` when the user did
/// not supply a link.
///
/// Wire contract v2 (FINAL — encoded by `NdefRecord.badgePerson` in the
/// `friends_badge` package; never string-munge the format here):
///
/// ```text
/// [U record]  <the user's personal URL, bare as typed>
/// [T record]  Name · Role · <url> · id:<installId> · capy:<capybaraId>
/// ```
///
/// The creator collects a single URL, which doubles as the U record and the
/// lone URL segment of the T record. [installId] comes from
/// `InstallIdCubit` (first-run UUID); [capybaraId] is the bundled capybara
/// asset name when the badge image is a bundled capybara, `null` for gallery
/// picks. Both tagged segments are appended by the contract writer in
/// canonical order.
///
/// An empty [url] means "no NDEF write" — callers must not write an empty
/// message, so this returns `null`.
NdefMessage? buildBadgeNdefMessage({
  required String name,
  required String role,
  required String url,
  String? installId,
  String? capybaraId,
}) {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) return null;

  return NdefMessage([
    NdefRecord.uri(Uri.parse(trimmedUrl)),
    NdefRecord.badgePerson(
      name: name,
      role: role,
      urls: [trimmedUrl],
      installId: installId,
      capybaraId: capybaraId,
    ),
  ]);
}

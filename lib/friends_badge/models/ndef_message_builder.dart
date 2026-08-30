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
/// An e-mail address typed as the link is written as a `mailto:` URL (see
/// [normalizeBadgeLink]) so the collector can open it.
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
  final link = normalizeBadgeLink(url);
  if (link.isEmpty) return null;

  return NdefMessage([
    NdefRecord.uri(Uri.parse(link)),
    NdefRecord.badgePerson(
      name: name,
      role: role,
      urls: [link],
      installId: installId,
      capybaraId: capybaraId,
    ),
  ]);
}

/// Builds the NDEF payload for a badge prepared on someone's behalf ahead
/// of the conference (see `SpeedWriterCubit`).
///
/// Same wire contract as [buildBadgeNdefMessage], but the person record is
/// always written, with [badgeId] (a fresh UUID per badge, standing in for
/// the install ID the owner's own phone would write) so that collectors
/// dedupe the badge and the owner's app never collects it as a stranger.
/// The U record is only added when [link] is non-empty.
NdefMessage buildPreparedBadgeNdefMessage({
  required String name,
  required String role,
  required String badgeId,
  String link = '',
  String? capybaraId,
}) {
  final normalized = normalizeBadgeLink(link);
  return NdefMessage([
    if (normalized.isNotEmpty) NdefRecord.uri(Uri.parse(normalized)),
    NdefRecord.badgePerson(
      name: name,
      role: role,
      urls: [if (normalized.isNotEmpty) normalized],
      installId: badgeId,
      capybaraId: capybaraId,
    ),
  ]);
}

final _emailPattern = RegExp(r'^[^\s@/:]+@[^\s@/:]+\.[^\s@/:]+$');

/// Trims [link] and turns a bare e-mail address into a `mailto:` URL, so
/// the badge carries something `url_launcher` can open. Anything else
/// (a URL with or without a scheme) is returned trimmed and unchanged.
String normalizeBadgeLink(String link) {
  final trimmed = link.trim();
  if (_emailPattern.hasMatch(trimmed)) return 'mailto:$trimmed';
  return trimmed;
}

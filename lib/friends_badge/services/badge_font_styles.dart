import 'package:flutter/painting.dart';
import 'package:flutter_and_friends/friends_badge/models/models.dart';
import 'package:google_fonts/google_fonts.dart';

/// The `google_fonts` text styles behind each [BadgeFont] pairing.
///
/// Used by the composer to draw the badge and by the font picker to show
/// each chip in its own face. Fonts are fetched by `google_fonts` on first
/// use; the composer awaits `GoogleFonts.pendingFonts` before rasterizing so
/// a freshly picked face never renders with a fallback font.
extension BadgeFontStyles on BadgeFont {
  /// Style for the name line.
  TextStyle get nameStyle => switch (this) {
    BadgeFont.display => GoogleFonts.oswald(fontWeight: FontWeight.w700),
    BadgeFont.sans => GoogleFonts.roboto(fontWeight: FontWeight.w700),
    BadgeFont.comic => GoogleFonts.bangers(),
    BadgeFont.script => GoogleFonts.pacifico(),
    BadgeFont.pixel => GoogleFonts.pressStart2p(),
    BadgeFont.bubbly => GoogleFonts.fredoka(fontWeight: FontWeight.w700),
    BadgeFont.mono => GoogleFonts.spaceMono(fontWeight: FontWeight.w700),
  };

  /// Style for the role line.
  TextStyle get roleStyle => switch (this) {
    BadgeFont.display ||
    BadgeFont.sans ||
    BadgeFont.comic ||
    BadgeFont.script => GoogleFonts.roboto(fontWeight: FontWeight.w400),
    BadgeFont.pixel => GoogleFonts.spaceMono(fontWeight: FontWeight.w700),
    BadgeFont.bubbly => GoogleFonts.fredoka(fontWeight: FontWeight.w500),
    BadgeFont.mono => GoogleFonts.spaceMono(fontWeight: FontWeight.w400),
  };
}

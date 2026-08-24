/// Which of the four badge templates to compose the image and text with.
///
/// Values mirror the spec in `docs/badge-creator.md` §5.
enum BadgeTemplate {
  /// Full-bleed image, no text. Identical to the app's behavior before the
  /// badge creator existed.
  imageOnly,

  /// Image on top (~60% of the panel), horizontal divider, name large and
  /// role smaller below.
  classic,

  /// Full-bleed image with a solid band across the bottom holding the name
  /// and role.
  overlay,

  /// Inset image with a thick border and accent stripe, name/role beneath.
  framed;

  /// Whether this template renders name/role text fields.
  bool get usesText => this != BadgeTemplate.imageOnly;

  /// User-facing label for the template picker.
  String get label => switch (this) {
    BadgeTemplate.imageOnly => 'Image only',
    BadgeTemplate.classic => 'Classic',
    BadgeTemplate.overlay => 'Overlay',
    BadgeTemplate.framed => 'Framed',
  };
}

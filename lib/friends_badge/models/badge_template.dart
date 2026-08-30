/// Which of the four badge templates to compose the image and text with.
///
/// Values mirror the spec in `docs/badge-creator.md` §5. Declaration order
/// is the order of the template tabs in the creator, and [classic] is the
/// default.
enum BadgeTemplate {
  /// Image on top (~60% of the panel), horizontal divider, name large and
  /// role smaller below.
  classic,

  /// Full-bleed image, no text. Identical to the app's behavior before the
  /// badge creator existed.
  imageOnly,

  /// Full-bleed image with a solid band across the bottom holding the name
  /// and role.
  overlay,

  /// Inset image with a frame (see `BadgeFrame`), name/role beneath.
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

/// The two curated font faces used by the badge creator.
///
/// Rendered via `google_fonts`. Per the spec (`docs/badge-creator.md` §6):
/// a heavy display face survives quantization to the badge palette, and a
/// neutral sans keeps the role legible at low resolution.
enum BadgeFont {
  /// Bold display face for the name.
  display,

  /// Clean sans for the role.
  sans;

  /// User-facing label for the font picker.
  String get label => switch (this) {
    BadgeFont.display => 'Display',
    BadgeFont.sans => 'Sans',
  };
}

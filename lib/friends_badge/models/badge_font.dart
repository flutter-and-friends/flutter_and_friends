/// The curated font pairings used by the badge creator.
///
/// Rendered via `google_fonts` (see `BadgeFontStyles`). Per the spec
/// (`docs/badge-creator.md` §6) every name face is heavy enough to survive
/// quantization to the badge palette, and the role face stays legible at low
/// resolution. Declaration order is the order in the font picker.
enum BadgeFont {
  /// Bold condensed display face (Oswald) for the name, Roboto for the role.
  display,

  /// Clean sans (Roboto) for both.
  sans,

  /// Comic-book lettering (Bangers) for the name, Roboto for the role.
  comic,

  /// Brush script (Pacifico) for the name, Roboto for the role.
  script,

  /// 8-bit pixel face (Press Start 2P) for the name, Space Mono for the
  /// role.
  pixel,

  /// Rounded, friendly face (Fredoka) for both.
  bubbly,

  /// Monospace (Space Mono) for both.
  mono;

  /// User-facing label for the font picker.
  String get label => switch (this) {
    BadgeFont.display => 'Display',
    BadgeFont.sans => 'Sans',
    BadgeFont.comic => 'Comic',
    BadgeFont.script => 'Script',
    BadgeFont.pixel => 'Pixel',
    BadgeFont.bubbly => 'Bubbly',
    BadgeFont.mono => 'Mono',
  };
}

/// The frame styles available for the framed badge template.
///
/// Every frame only uses the badge palette (black, white, red, yellow) so it
/// quantizes cleanly. Declaration order is the order in the frame picker,
/// and [stripe] is the default.
enum BadgeFrame {
  /// Thick black border with a red and yellow accent stripe underneath.
  stripe,

  /// A thin outer and inner black line with a white gap between them.
  double,

  /// Rounded corners, a red border with a thin yellow inner line.
  rounded,

  /// Black photo-mount brackets over the image corners and a red and yellow
  /// bar underneath.
  corners;

  /// User-facing label for the frame picker.
  String get label => switch (this) {
    BadgeFrame.stripe => 'Stripe',
    BadgeFrame.double => 'Double',
    BadgeFrame.rounded => 'Rounded',
    BadgeFrame.corners => 'Corners',
  };
}

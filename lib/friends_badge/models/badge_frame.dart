/// The frame styles available for the framed badge template.
///
/// Every frame is plain black so it quantizes cleanly to the badge palette.
/// Declaration order is the order in the frame picker, and [bold] is the
/// default.
enum BadgeFrame {
  /// A thick black border.
  bold,

  /// A thin outer and inner black line with a white gap between them.
  double,

  /// A black border with rounded corners; the image is clipped to match.
  rounded,

  /// Black photo-mount brackets over the image corners.
  corners;

  /// User-facing label for the frame picker.
  String get label => switch (this) {
    BadgeFrame.bold => 'Bold',
    BadgeFrame.double => 'Double',
    BadgeFrame.rounded => 'Rounded',
    BadgeFrame.corners => 'Corners',
  };
}

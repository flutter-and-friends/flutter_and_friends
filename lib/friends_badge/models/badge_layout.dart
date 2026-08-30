import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_and_friends/friends_badge/models/badge_frame.dart';
import 'package:flutter_and_friends/friends_badge/models/badge_template.dart';

/// Dimensions of the badge panel the composer renders to.
///
/// Matches `BadgeSpecification.size3_7inchPassiveBWRY` in the `friends_badge`
/// package (240 x 416 portrait). The package does not export that enum, so the
/// dimensions are duplicated here and kept in sync by tests.
const Size kBadgePanelSize = Size(240, 416);

/// Computed layout for a badge template: where the image goes, where text
/// goes, and how large each text block may be.
///
/// Pure value type — produced by [BadgeLayout.forTemplate] and consumed by
/// the canvas renderer. No Flutter widgets, no `img.Image`; this is the
/// unit-testable seam of the composer.
class BadgeLayout {
  const BadgeLayout._({
    required this.template,
    required this.imageRect,
    required this.nameRect,
    required this.roleRect,
    required this.nameMaxFontSize,
    required this.roleMaxFontSize,
    this.dividerY,
    this.borderWidth = 0,
    this.textOnDark = false,
    this.frame,
    this.imageCornerRadius = 0,
  });

  /// Computes the layout for [template] on a panel of [panelSize]. [frame]
  /// only matters for [BadgeTemplate.framed].
  ///
  /// For templates that do not use text, `nameRect`/`roleRect` are
  /// [Rect.zero] and font sizes are 0.
  factory BadgeLayout.forTemplate(
    BadgeTemplate template, {
    BadgeFrame frame = BadgeFrame.bold,
    Size panelSize = kBadgePanelSize,
  }) {
    switch (template) {
      case BadgeTemplate.imageOnly:
        return BadgeLayout._(
          template: template,
          imageRect: Offset.zero & panelSize,
          nameRect: Rect.zero,
          roleRect: Rect.zero,
          nameMaxFontSize: 0,
          roleMaxFontSize: 0,
        );
      case BadgeTemplate.classic:
        return _classic(panelSize);
      case BadgeTemplate.overlay:
        return _overlay(panelSize);
      case BadgeTemplate.framed:
        return _framed(panelSize, frame);
    }
  }

  final BadgeTemplate template;

  /// Rect the user's image is cover-fitted into.
  final Rect imageRect;

  /// Rect the name text is laid out inside (top-left anchored).
  final Rect nameRect;

  /// Rect the role text is laid out inside (top-left anchored).
  final Rect roleRect;

  /// Largest font size the name may be rendered at before [fitFontSize]
  /// starts shrinking it.
  final double nameMaxFontSize;

  /// Largest font size the role may be rendered at.
  final double roleMaxFontSize;

  /// Y coordinate of the horizontal divider, if the template draws one
  /// (`classic` only).
  final double? dividerY;

  /// Total thickness of the frame drawn around [imageRect], if any
  /// (`framed` only). Zero when the frame is drawn over the image instead.
  final double borderWidth;

  /// True when text sits on a dark band and should render in white
  /// (`overlay`); false for black text on light background.
  final bool textOnDark;

  /// The frame style, for the `framed` template only.
  final BadgeFrame? frame;

  /// Corner radius the image is clipped to, 0 for square corners.
  final double imageCornerRadius;

  // -- Templates ------------------------------------------------------------

  // Template constructors. Kept as static methods rather than factory
  // constructors because each produces a fully-populated immutable value and
  // the switch in [forTemplate] reads better than five named factories.
  // ignore_for_file: prefer_constructors_over_static_methods

  static BadgeLayout _classic(Size panel) {
    // Image occupies the top ~60%; divider; then name and role below.
    final imageHeight = panel.height * 0.6;
    const dividerHeight = 2.0;
    const hPad = 12.0;
    const vPad = 10.0;
    const gap = 6.0;
    final textTop = imageHeight + dividerHeight + vPad;
    final textWidth = panel.width - hPad * 2;
    // Name gets roughly 60% of the remaining vertical space, role the rest.
    final remaining = panel.height - textTop - vPad;
    final nameHeight = remaining * 0.58;
    return BadgeLayout._(
      template: BadgeTemplate.classic,
      imageRect: Rect.fromLTWH(0, 0, panel.width, imageHeight),
      dividerY: imageHeight + dividerHeight / 2,
      nameRect: Rect.fromLTWH(hPad, textTop, textWidth, nameHeight),
      roleRect: Rect.fromLTWH(
        hPad,
        textTop + nameHeight + gap,
        textWidth,
        remaining - nameHeight - gap,
      ),
      nameMaxFontSize: 34,
      roleMaxFontSize: 20,
    );
  }

  static BadgeLayout _overlay(Size panel) {
    // Full-bleed image; solid band across the bottom holds name + role.
    const bandHeight = 96.0;
    const hPad = 12.0;
    const vPad = 8.0;
    const gap = 4.0;
    final bandTop = panel.height - bandHeight;
    const nameHeight = 44.0;
    return BadgeLayout._(
      template: BadgeTemplate.overlay,
      imageRect: Offset.zero & panel,
      nameRect: Rect.fromLTWH(
        hPad,
        bandTop + vPad,
        panel.width - hPad * 2,
        nameHeight,
      ),
      roleRect: Rect.fromLTWH(
        hPad,
        bandTop + vPad + nameHeight + gap,
        panel.width - hPad * 2,
        bandHeight - vPad * 2 - nameHeight - gap,
      ),
      nameMaxFontSize: 30,
      roleMaxFontSize: 18,
      textOnDark: true,
    );
  }

  static BadgeLayout _framed(Size panel, BadgeFrame frame) {
    // Inset image with a frame drawn around it (or over its corners), and
    // name/role beneath.
    const margin = 12.0;
    const textAreaHeight = 96.0;
    const hPad = 12.0;
    const gap = 6.0;
    final borderWidth = switch (frame) {
      BadgeFrame.bold => 6.0,
      BadgeFrame.double => 9.0,
      BadgeFrame.rounded => 8.0,
      BadgeFrame.corners => 0.0,
    };
    final imageRect = Rect.fromLTWH(
      margin + borderWidth,
      margin + borderWidth,
      panel.width - (margin + borderWidth) * 2,
      panel.height - textAreaHeight - (margin + borderWidth) * 2,
    );
    final textTop = imageRect.bottom + borderWidth + 8;
    const nameHeight = 44.0;
    return BadgeLayout._(
      template: BadgeTemplate.framed,
      frame: frame,
      imageRect: imageRect,
      imageCornerRadius: frame == BadgeFrame.rounded ? 16 : 0,
      borderWidth: borderWidth,
      nameRect: Rect.fromLTWH(
        hPad,
        textTop,
        panel.width - hPad * 2,
        nameHeight,
      ),
      roleRect: Rect.fromLTWH(
        hPad,
        textTop + nameHeight + gap,
        panel.width - hPad * 2,
        panel.height - textTop - nameHeight - gap - 8,
      ),
      nameMaxFontSize: 30,
      roleMaxFontSize: 18,
    );
  }
}

/// Fits a single line of [text] into [maxWidth] by shrinking the font size
/// from [maxFontSize] down to [minFontSize].
///
/// [measure] reports the rendered width of [text] at a given font size — the
/// caller supplies a `TextPainter`-backed closure, keeping this function pure
/// and unit-testable with a stub measurer.
///
/// If the text still overflows at [minFontSize], the caller is expected to
/// truncate with [truncateToFit]; this function returns [minFontSize] in that
/// case.
double fitFontSize({
  required String text,
  required double maxWidth,
  required double maxFontSize,
  required double minFontSize,
  required double Function(String text, double fontSize) measure,
}) {
  if (text.isEmpty) return maxFontSize;
  if (measure(text, maxFontSize) <= maxWidth) return maxFontSize;

  // Binary search between min and max font size.
  var lo = minFontSize;
  var hi = maxFontSize;
  // Bail out early when even the minimum doesn't fit.
  if (measure(text, lo) > maxWidth) return lo;
  while (hi - lo > 0.5) {
    final mid = (lo + hi) / 2;
    if (measure(text, mid) <= maxWidth) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// Truncates [text] with an ellipsis so it fits [maxWidth] at [fontSize],
/// per [measure].
///
/// Returns [text] unchanged if it already fits. Otherwise walks back to the
/// longest prefix that, with a trailing ellipsis, fits. Always returns at
/// least the ellipsis alone.
String truncateToFit({
  required String text,
  required double maxWidth,
  required double fontSize,
  required double Function(String text, double fontSize) measure,
}) {
  if (text.isEmpty || measure(text, fontSize) <= maxWidth) return text;
  const ellipsis = '…';
  // Binary search the longest fitting prefix.
  var lo = 0;
  var hi = text.length;
  while (lo < hi) {
    final mid = (lo + hi + 1) ~/ 2;
    final candidate = '${text.substring(0, mid)}$ellipsis';
    if (measure(candidate, fontSize) <= maxWidth) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return '${text.substring(0, lo)}$ellipsis';
}

/// Once a badge text line has this many characters, it breaks at the next
/// space (see [breakBadgeText]).
const int kBadgeTextBreakAfter = 8;

/// Splits [text] onto two lines for the badge: the line breaks at the first
/// space found at or after [kBadgeTextBreakAfter] characters.
///
/// Shorter texts, and texts whose only spaces come earlier, are returned
/// unchanged. At most one break is inserted; the second line is fitted and
/// truncated by the composer like any other line.
String breakBadgeText(String text) {
  if (text.length <= kBadgeTextBreakAfter) return text;
  final breakAt = text.indexOf(' ', kBadgeTextBreakAfter);
  if (breakAt == -1) return text;
  final head = text.substring(0, breakAt).trimRight();
  final tail = text.substring(breakAt + 1).trimLeft();
  if (head.isEmpty || tail.isEmpty) return text;
  return '$head\n$tail';
}

/// The text to draw for [text] on [template]: only the classic template
/// breaks long text onto two lines (see [breakBadgeText]), the others keep
/// it on one line and let it shrink to fit.
String badgeTextLines(String text, BadgeTemplate template) {
  return template == BadgeTemplate.classic ? breakBadgeText(text) : text;
}

/// Cover-fit source rect math: given a source image of [source] size and a
/// destination [dest], returns the largest centered rect of [source] that,
/// scaled uniformly, covers [dest] completely.
///
/// Used by the canvas renderer to `drawImageRect` the user's photo into the
/// template's `imageRect` without letterboxing.
Rect coverSourceRect({required Size source, required Rect dest}) {
  if (source.isEmpty || dest.isEmpty) return Offset.zero & source;
  final scale = math.max(
    dest.width / source.width,
    dest.height / source.height,
  );
  final cropWidth = dest.width / scale;
  final cropHeight = dest.height / scale;
  // Center the crop window on the source.
  final left = (source.width - cropWidth) / 2;
  final top = (source.height - cropHeight) / 2;
  return Rect.fromLTWH(left, top, cropWidth, cropHeight).intersect(
    Offset.zero & source,
  );
}

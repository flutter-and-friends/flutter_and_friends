import 'dart:ui' as ui;

import 'package:flutter/material.dart' as m;
import 'package:flutter/painting.dart';
import 'package:flutter_and_friends/friends_badge/models/models.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

/// Renders a badge composition (image + template + name/role) to a
/// [BadgeImage] suitable for the existing write flow.
///
/// The composition happens on an offscreen 240x416 Flutter [Canvas] via
/// [TextPainter]; the resulting PNG is decoded with `package:image` and
/// wrapped in [BadgeImage], which the rest of the badge pipeline (dither
/// carousel, `writeToBadge`) already understands.
///
/// Only pure black / white / red / yellow are painted so the output
/// quantizes cleanly onto the badge's `blackWhiteYellowRed` palette.
class BadgeComposer {
  const BadgeComposer._();

  // Palette colors (pure values — no mid-grays).
  static const _black = m.Color(0xFF000000);
  static const _white = m.Color(0xFFFFFFFF);
  static const _red = m.Color(0xFFFF0000);
  static const _yellow = m.Color(0xFFFFFF00);

  /// Composes a [BadgeImage] from [image], laying out [name] and [role]
  /// per [template] and using [font] for the display face.
  static Future<BadgeImage> compose({
    required img.Image image,
    required BadgeTemplate template,
    required String name,
    required String role,
    required BadgeFont font,
  }) async {
    final layout = BadgeLayout.forTemplate(template);
    final recorder = ui.PictureRecorder();
    final canvas = m.Canvas(recorder);
    final panelRect = Offset.zero & kBadgePanelSize;

    // White base so any uncovered pixels (e.g. under the framed template's
    // margin) quantize to white, not black.
    canvas.drawRect(panelRect, Paint()..color = _white);

    final uiImage = await _toUiImage(image);
    _drawImage(canvas, uiImage: uiImage, layout: layout);

    if (template.usesText) {
      _drawTemplateChrome(canvas, layout);
      _drawText(
        canvas,
        layout: layout,
        name: name,
        role: role,
        font: font,
      );
    }

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      kBadgePanelSize.width.toInt(),
      kBadgePanelSize.height.toInt(),
    );
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    final decoded = img.decodePng(byteData!.buffer.asUint8List());
    return BadgeImage(decoded!);
  }

  // -- Painting --------------------------------------------------------------

  /// Bridges an `img.Image` (what the cubit decodes) into a `ui.Image` (what
  /// the Canvas draws) by round-tripping through PNG.
  static Future<ui.Image> _toUiImage(img.Image image) async {
    final pngBytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _drawImage(
    m.Canvas canvas, {
    required ui.Image uiImage,
    required BadgeLayout layout,
  }) {
    final source = coverSourceRect(
      source: Size(
        uiImage.width.toDouble(),
        uiImage.height.toDouble(),
      ),
      dest: layout.imageRect,
    );
    canvas.drawImageRect(
      uiImage,
      source,
      layout.imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  /// Template-specific chrome: divider lines, overlay band, framed border
  /// and accent stripe.
  static void _drawTemplateChrome(m.Canvas canvas, BadgeLayout layout) {
    switch (layout.template) {
      case BadgeTemplate.imageOnly:
        break;
      case BadgeTemplate.classic:
        final y = layout.dividerY!;
        canvas.drawRect(
          Rect.fromLTWH(0, y - 1, kBadgePanelSize.width, 2),
          Paint()..color = _black,
        );
      case BadgeTemplate.overlay:
        // Solid black band from above the name rect to the bottom of the
        // panel.
        final bandTop = layout.nameRect.top - 8;
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            bandTop,
            kBadgePanelSize.width,
            kBadgePanelSize.height - bandTop,
          ),
          Paint()..color = _black,
        );
      case BadgeTemplate.framed:
        final border = layout.imageRect.inflate(layout.borderWidth);
        canvas.drawRect(
          border,
          Paint()
            ..color = _black
            ..style = PaintingStyle.stroke
            ..strokeWidth = layout.borderWidth,
        );
        // Accent stripe: red on top half, yellow on bottom half, so the
        // framed template carries both palette accents.
        final stripe = layout.accentStripeRect!;
        canvas
          ..drawRect(
            Rect.fromLTWH(
              stripe.left,
              stripe.top,
              stripe.width,
              stripe.height / 2,
            ),
            Paint()..color = _red,
          )
          ..drawRect(
            Rect.fromLTWH(
              stripe.left,
              stripe.top + stripe.height / 2,
              stripe.width,
              stripe.height / 2,
            ),
            Paint()..color = _yellow,
          );
    }
  }

  static void _drawText(
    m.Canvas canvas, {
    required BadgeLayout layout,
    required String name,
    required String role,
    required BadgeFont font,
  }) {
    final textColor = layout.textOnDark ? _white : _black;
    final displayStyle = _displayStyle(font);
    final sansStyle = _sansStyle(font);

    double measure(String text, double fontSize, m.TextStyle base) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: base.copyWith(fontSize: fontSize)),
        maxLines: 1,
        textDirection: m.TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    final fittedName = fitFontSize(
      text: name,
      maxWidth: layout.nameRect.width,
      maxFontSize: layout.nameMaxFontSize,
      minFontSize: 14,
      measure: (t, s) => measure(t, s, displayStyle),
    );
    final shownName = truncateToFit(
      text: name,
      maxWidth: layout.nameRect.width,
      fontSize: fittedName,
      measure: (t, s) => measure(t, s, displayStyle),
    );

    final fittedRole = fitFontSize(
      text: role,
      maxWidth: layout.roleRect.width,
      maxFontSize: layout.roleMaxFontSize,
      minFontSize: 12,
      measure: (t, s) => measure(t, s, sansStyle),
    );
    final shownRole = truncateToFit(
      text: role,
      maxWidth: layout.roleRect.width,
      fontSize: fittedRole,
      measure: (t, s) => measure(t, s, sansStyle),
    );

    if (shownName.isNotEmpty) {
      TextPainter(
        text: TextSpan(
          text: shownName,
          style: displayStyle.copyWith(
            fontSize: fittedName,
            color: textColor,
          ),
        ),
        maxLines: 1,
        textDirection: m.TextDirection.ltr,
      )
        ..layout(maxWidth: layout.nameRect.width)
        ..paint(canvas, layout.nameRect.topLeft);
    }

    if (shownRole.isNotEmpty) {
      TextPainter(
        text: TextSpan(
          text: shownRole,
          style: sansStyle.copyWith(
            fontSize: fittedRole,
            color: textColor,
          ),
        ),
        maxLines: 1,
        textDirection: m.TextDirection.ltr,
      )
        ..layout(maxWidth: layout.roleRect.width)
        ..paint(canvas, layout.roleRect.topLeft);
    }
  }

  // -- Fonts -----------------------------------------------------------------

  static m.TextStyle _displayStyle(BadgeFont font) => switch (font) {
    BadgeFont.display => GoogleFonts.oswald(
      fontWeight: m.FontWeight.w700,
      color: _black,
    ),
    BadgeFont.sans => GoogleFonts.roboto(
      fontWeight: m.FontWeight.w700,
      color: _black,
    ),
  };

  static m.TextStyle _sansStyle(BadgeFont font) => switch (font) {
    BadgeFont.display => GoogleFonts.roboto(
      fontWeight: m.FontWeight.w400,
      color: _black,
    ),
    BadgeFont.sans => GoogleFonts.roboto(
      fontWeight: m.FontWeight.w400,
      color: _black,
    ),
  };
}

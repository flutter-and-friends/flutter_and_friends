import 'dart:math' as math;
import 'dart:typed_data';
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
/// The pipeline has two phases with different threading constraints:
///
/// 1. [renderRgba] — rasterizes the composition on an offscreen 240x416
///    Flutter Canvas via [TextPainter] and reads it back as raw 8-bit RGBA.
///    `dart:ui` raster APIs only run on the root isolate, so this phase
///    stays there. It takes a ready [ui.Image] of the source photo (cached
///    by the caller) so no image decoding happens per compose.
/// 2. [badgeImageFromRgba] — wraps the RGBA bytes in an `img.Image` and
///    builds the [BadgeImage] (which resizes into badge spec). Pure Dart on
///    plain data — this is the phase that crosses the `integral_isolates`
///    boundary in the cubit, so it is a top-level function taking and
///    returning transferable values.
///
/// The hand-off is deliberately raw RGBA rather than PNG. On iOS, Impeller
/// renders `Picture.toImage` into a wide-gamut (16-bit float) texture and
/// `ImageByteFormat.png` encodes that as a 16-bit-per-channel PNG. The
/// `friends_badge` quantizer compares raw channel values against a 0..255
/// palette, so a 16-bit image dithers to an almost blank white panel.
/// `ImageByteFormat.rawStraightRgba` is always converted to 8-bit RGBA by the
/// engine, on every platform.
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

  /// Rasterizes the composition to raw 8-bit straight-alpha RGBA bytes
  /// ([kBadgePanelSize] wide and tall, 4 bytes per pixel) on the root
  /// isolate.
  ///
  /// [sourceImage] is the user's photo as a [ui.Image] — convert once (see
  /// [toUiImage]) and reuse across composes; converting per compose would
  /// re-encode the full-resolution source every keystroke.
  static Future<Uint8List> renderRgba({
    required ui.Image sourceImage,
    required BadgeTemplate template,
    required String name,
    required String role,
    required BadgeFont font,
    BadgeFrame frame = BadgeFrame.stripe,
  }) async {
    final layout = BadgeLayout.forTemplate(template, frame: frame);
    final recorder = ui.PictureRecorder();
    final canvas = m.Canvas(recorder);
    final panelRect = Offset.zero & kBadgePanelSize;

    // White base so any uncovered pixels (e.g. under the framed template's
    // margin) quantize to white, not black.
    canvas.drawRect(panelRect, Paint()..color = _white);

    _drawImage(canvas, uiImage: sourceImage, layout: layout);

    if (template.usesText) {
      paintTemplateChrome(canvas, layout);
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
    try {
      final byteData = await rendered.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      return byteData!.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } finally {
      rendered.dispose();
      picture.dispose();
    }
  }

  /// Bridges an `img.Image` (what the cubit decodes) into a [ui.Image] (what
  /// the Canvas draws) by round-tripping through PNG. Root-isolate only.
  static Future<ui.Image> toUiImage(img.Image image) async {
    final pngBytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // -- Painting --------------------------------------------------------------

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
    final radius = layout.imageCornerRadius;
    if (radius > 0) {
      canvas
        ..save()
        ..clipRRect(
          RRect.fromRectAndRadius(layout.imageRect, Radius.circular(radius)),
        );
    }
    canvas.drawImageRect(
      uiImage,
      source,
      layout.imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    if (radius > 0) canvas.restore();
  }

  /// Template-specific chrome: divider lines, overlay band, and the frame
  /// styles of the framed template. Public so the frame picker can draw
  /// miniatures with exactly the chrome the badge gets.
  static void paintTemplateChrome(m.Canvas canvas, BadgeLayout layout) {
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
        _drawFrame(canvas, layout);
    }
  }

  static void _drawFrame(m.Canvas canvas, BadgeLayout layout) {
    final image = layout.imageRect;
    switch (layout.frame ?? BadgeFrame.stripe) {
      case BadgeFrame.stripe:
        _strokeAround(canvas, image, width: layout.borderWidth, color: _black);
        // Accent stripe: red on top half, yellow on bottom half, so the
        // frame carries both palette accents.
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
      case BadgeFrame.double:
        _strokeAround(canvas, image, width: 2, color: _black);
        _strokeAround(canvas, image.inflate(6), width: 3, color: _black);
      case BadgeFrame.rounded:
        final radius = layout.imageCornerRadius;
        _strokeAround(canvas, image, width: 2, color: _yellow, radius: radius);
        _strokeAround(
          canvas,
          image.inflate(2),
          width: 8,
          color: _red,
          radius: radius + 2,
        );
      case BadgeFrame.corners:
        const thickness = 6.0;
        const length = 40.0;
        final paint = Paint()..color = _black;
        for (final corner in [
          image.topLeft,
          image.topRight,
          image.bottomLeft,
          image.bottomRight,
        ]) {
          final dx = corner.dx == image.left ? 1 : -1;
          final dy = corner.dy == image.top ? 1 : -1;
          canvas
            ..drawRect(
              Rect.fromPoints(
                corner,
                corner.translate(dx * length, dy * thickness),
              ),
              paint,
            )
            ..drawRect(
              Rect.fromPoints(
                corner,
                corner.translate(dx * thickness, dy * length),
              ),
              paint,
            );
        }
        // Accent bar: a red third, then yellow.
        final bar = layout.accentStripeRect!;
        final split = bar.width / 3;
        canvas
          ..drawRect(
            Rect.fromLTWH(bar.left, bar.top, split, bar.height),
            Paint()..color = _red,
          )
          ..drawRect(
            Rect.fromLTWH(
              bar.left + split,
              bar.top,
              bar.width - split,
              bar.height,
            ),
            Paint()..color = _yellow,
          );
    }
  }

  /// Strokes a band of [width] hugging the outside of [rect], with the
  /// rect's corners rounded by [radius] when it is greater than zero.
  static void _strokeAround(
    m.Canvas canvas,
    Rect rect, {
    required double width,
    required m.Color color,
    double radius = 0,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final band = rect.inflate(width / 2);
    if (radius > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(band, Radius.circular(radius + width / 2)),
        paint,
      );
    } else {
      canvas.drawRect(band, paint);
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
    _paintText(
      canvas,
      text: breakBadgeText(name),
      rect: layout.nameRect,
      style: _displayStyle(font).copyWith(color: textColor),
      maxFontSize: layout.nameMaxFontSize,
      minFontSize: 14,
    );
    _paintText(
      canvas,
      text: breakBadgeText(role),
      rect: layout.roleRect,
      style: _sansStyle(font).copyWith(color: textColor),
      maxFontSize: layout.roleMaxFontSize,
      minFontSize: 12,
    );
  }

  /// Paints [text] (one or two lines, see [breakBadgeText]) top-left in
  /// [rect] at the largest font size between [minFontSize] and
  /// [maxFontSize] at which every line fits the width and all lines fit the
  /// height, truncating lines that still overflow at [minFontSize].
  static void _paintText(
    m.Canvas canvas, {
    required String text,
    required Rect rect,
    required m.TextStyle style,
    required double maxFontSize,
    required double minFontSize,
  }) {
    if (text.isEmpty || rect.isEmpty) return;
    final lines = text.split('\n');

    TextPainter painterFor(String value, double fontSize) {
      return TextPainter(
        text: TextSpan(
          text: value,
          style: style.copyWith(fontSize: fontSize),
        ),
        maxLines: lines.length,
        textDirection: m.TextDirection.ltr,
      )..layout();
    }

    double measure(String value, double fontSize) =>
        painterFor(value, fontSize).width;

    // Line height scales linearly with font size, so one measurement at the
    // maximum gives the largest size whose lines still fit the rect height.
    final heightAtMax = painterFor(text, maxFontSize).height;
    final cappedMax = heightAtMax <= rect.height
        ? maxFontSize
        : math.max(minFontSize, maxFontSize * rect.height / heightAtMax);

    final fontSize = fitFontSize(
      text: text,
      maxWidth: rect.width,
      maxFontSize: cappedMax,
      minFontSize: minFontSize,
      measure: measure,
    );
    final shown = [
      for (final line in lines)
        truncateToFit(
          text: line,
          maxWidth: rect.width,
          fontSize: fontSize,
          measure: measure,
        ),
    ].join('\n');

    painterFor(shown, fontSize)
      ..layout(maxWidth: rect.width)
      ..paint(canvas, rect.topLeft);
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

/// Isolate entrypoint for the second compose phase: wrap the rendered RGBA
/// bytes (see [BadgeComposer.renderRgba]) in an `img.Image` and build the
/// [BadgeImage] (the constructor resizes into badge spec).
///
/// Must be a top-level function so it can be sent to a spawned isolate via
/// `integral_isolates`. Everything crossing the boundary is plain data:
/// `Uint8List` in, `BadgeImage` (two `img.Image` bitmaps) out.
BadgeImage badgeImageFromRgba(Uint8List rgba) {
  final width = kBadgePanelSize.width.toInt();
  final height = kBadgePanelSize.height.toInt();
  final expectedLength = width * height * 4;
  if (rgba.lengthInBytes != expectedLength) {
    throw ArgumentError.value(
      rgba.lengthInBytes,
      'rgba',
      'Expected $expectedLength bytes for a ${width}x$height RGBA image',
    );
  }
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    bytesOffset: rgba.offsetInBytes,
    numChannels: 4,
  );
  return BadgeImage(image);
}

/// Input for [composeBadge]: the rendered RGBA bytes and the dither kernel
/// the full-size preview should use.
class ComposeRequest {
  const ComposeRequest({required this.rgba, required this.kernel});

  final Uint8List rgba;
  final DitherKernel kernel;
}

/// Output of [composeBadge]: the [BadgeImage] plus the PNG previews the
/// editor shows, so that dithering and encoding never run on the UI thread.
class ComposedBadge {
  const ComposedBadge({
    required this.image,
    required this.kernel,
    required this.previewPng,
    required this.peekPngs,
  });

  final BadgeImage image;
  final DitherKernel kernel;

  /// [image] dithered with [kernel], PNG encoded.
  final Uint8List previewPng;

  /// A small PNG per supported kernel for the kernel carousel.
  final Map<DitherKernel, Uint8List> peekPngs;
}

/// Isolate entrypoint for the second compose phase: builds the [BadgeImage]
/// from the rendered RGBA bytes (see [badgeImageFromRgba]) and encodes the
/// previews the editor needs. `BadgeImage.getImageBytes` and
/// `getPeekImageBytes` dither and PNG-encode on every call with no caching,
/// which is far too slow to do inside `build` on each keystroke.
ComposedBadge composeBadge(ComposeRequest request) {
  final image = badgeImageFromRgba(request.rgba);
  return ComposedBadge(
    image: image,
    kernel: request.kernel,
    previewPng: image.getImageBytes(request.kernel),
    peekPngs: {
      for (final kernel in BadgeImage.allSupportedKernels)
        kernel: image.getPeekImageBytes(kernel),
    },
  );
}

/// Encodes the full-size preview of [image] dithered with [kernel]. Meant to
/// run off the UI thread, for example through `Isolate.run`.
Uint8List encodeBadgePreview(BadgeImage image, DitherKernel kernel) {
  return image.getImageBytes(kernel);
}

import 'dart:math';

import 'package:flutter/material.dart';

/// An hourglass that keeps running while the team waits: the sand runs from
/// the top bulb into the bottom one, then the glass flips over and starts
/// again.
///
/// Drawn rather than taken from the icon font so the loop is seamless: the
/// glass is symmetric and a full bulb is drawn completely filled, so the
/// picture at the end of the flip (bottom bulb full, turned upside down) is
/// pixel for pixel the picture the next cycle starts from.
class WaitingHourglass extends StatefulWidget {
  const WaitingHourglass({
    this.size = 56,
    this.color,
    this.sandColor,
    super.key,
  });

  final double size;

  /// The glass. Defaults to the theme's `onSurfaceVariant`.
  final Color? color;

  /// The sand. Defaults to the theme's `primary`.
  final Color? sandColor;

  @override
  State<WaitingHourglass> createState() => _WaitingHourglassState();
}

class _WaitingHourglassState extends State<WaitingHourglass>
    with SingleTickerProviderStateMixin {
  /// The sand runs until here, then the glass flips for the rest of the
  /// cycle.
  static const _flipStartsAt = 0.72;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.onSurfaceVariant;
    final sandColor = widget.sandColor ?? theme.colorScheme.primary;
    return Semantics(
      label: 'Waiting',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final sand = (t / _flipStartsAt).clamp(0.0, 1.0);
          final flip = t < _flipStartsAt
              ? 0.0
              : Curves.easeInOutCubic.transform(
                  (t - _flipStartsAt) / (1 - _flipStartsAt),
                );
          return Center(
            child: SizedBox.square(
              dimension: widget.size,
              child: Transform.rotate(
                angle: flip * pi,
                child: CustomPaint(
                  painter: HourglassPainter(
                    sand: sand,
                    color: color,
                    sandColor: sandColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Draws the glass with the top bulb `1 - sand` full and the bottom bulb
/// `sand` full, plus the falling stream while sand is moving.
class HourglassPainter extends CustomPainter {
  const HourglassPainter({
    required this.sand,
    required this.color,
    required this.sandColor,
  });

  /// 0 when all the sand is in the top bulb, 1 when it is all at the bottom.
  final double sand;
  final Color color;
  final Color sandColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final capHeight = h * 0.07;
    final capWidth = w * 0.72;
    final left = (w - capWidth) / 2 + capHeight * 0.4;
    final right = w - left;
    final top = capHeight;
    final bottom = h - capHeight;
    final centerX = w / 2;
    final centerY = h / 2;
    final neck = w * 0.045;
    final bulbHeight = centerY - top;

    final topBulb = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..cubicTo(
        right,
        top + bulbHeight * 0.6,
        centerX + neck,
        centerY - bulbHeight * 0.2,
        centerX + neck,
        centerY,
      )
      ..lineTo(centerX - neck, centerY)
      ..cubicTo(
        centerX - neck,
        centerY - bulbHeight * 0.2,
        left,
        top + bulbHeight * 0.6,
        left,
        top,
      )
      ..close();
    final bottomBulb = Path()
      ..moveTo(left, bottom)
      ..lineTo(right, bottom)
      ..cubicTo(
        right,
        bottom - bulbHeight * 0.6,
        centerX + neck,
        centerY + bulbHeight * 0.2,
        centerX + neck,
        centerY,
      )
      ..lineTo(centerX - neck, centerY)
      ..cubicTo(
        centerX - neck,
        centerY + bulbHeight * 0.2,
        left,
        bottom - bulbHeight * 0.6,
        left,
        bottom,
      )
      ..close();

    final sandPaint = Paint()..color = sandColor;
    canvas
      ..save()
      ..clipPath(topBulb)
      ..drawRect(
        Rect.fromLTRB(left, top + bulbHeight * sand, right, centerY),
        sandPaint,
      )
      ..restore()
      ..save()
      ..clipPath(bottomBulb)
      ..drawRect(
        Rect.fromLTRB(left, bottom - bulbHeight * sand, right, bottom),
        sandPaint,
      )
      ..restore();

    if (sand > 0 && sand < 1) {
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(centerX, bottom - bulbHeight * sand),
        Paint()
          ..color = sandColor
          ..strokeWidth = neck
          ..strokeCap = StrokeCap.round,
      );
    }

    final glass = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(topBulb, glass)
      ..drawPath(bottomBulb, glass);

    final cap = Paint()..color = color;
    final capRadius = Radius.circular(capHeight / 2);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((w - capWidth) / 2, 0, capWidth, capHeight),
          capRadius,
        ),
        cap,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((w - capWidth) / 2, bottom, capWidth, capHeight),
          capRadius,
        ),
        cap,
      );
  }

  @override
  bool shouldRepaint(HourglassPainter oldDelegate) {
    return oldDelegate.sand != sand ||
        oldDelegate.color != color ||
        oldDelegate.sandColor != sandColor;
  }
}

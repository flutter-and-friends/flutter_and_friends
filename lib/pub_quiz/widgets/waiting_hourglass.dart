import 'dart:math';

import 'package:flutter/material.dart';

/// An hourglass that keeps running while the team waits: the sand runs
/// through, then the glass flips over and starts again. The flip ends
/// upside down with the sand icon reversed, which is exactly the starting
/// frame, so the loop has no visible seam.
class WaitingHourglass extends StatefulWidget {
  const WaitingHourglass({this.size = 48, this.color, super.key});

  final double size;
  final Color? color;

  @override
  State<WaitingHourglass> createState() => _WaitingHourglassState();
}

class _WaitingHourglassState extends State<WaitingHourglass>
    with SingleTickerProviderStateMixin {
  static const _sandRunsOutAt = 0.45;
  static const _flipStartsAt = 0.7;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'Waiting',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final flip = t < _flipStartsAt
              ? 0.0
              : Curves.easeInOutCubic.transform(
                  (t - _flipStartsAt) / (1 - _flipStartsAt),
                );
          final icon = t < _sandRunsOutAt
              ? Icons.hourglass_top
              : Icons.hourglass_bottom;
          return Transform.rotate(
            angle: flip * pi,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: widget.size,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

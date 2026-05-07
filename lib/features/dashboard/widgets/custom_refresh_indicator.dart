import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A pull-to-refresh wrapping built on Flutter's RefreshIndicator but with
/// a custom CustomPainter ring + count of pulled distance.
class CustomRefresh extends StatelessWidget {
  const CustomRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      color: scheme.primary,
      backgroundColor: scheme.surface,
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}

class CustomRefreshArc extends StatelessWidget {
  const CustomRefreshArc({
    required this.progress,
    required this.color,
    super.key,
  });

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _ArcPainter(progress: progress, color: color),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final track = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, track);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.color != color;
}

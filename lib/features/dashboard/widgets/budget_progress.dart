import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/hero_tags.dart';

class BudgetRing extends StatefulWidget {
  const BudgetRing({
    required this.fraction,
    required this.label,
    required this.value,
    required this.isOver,
    this.size = 180,
    this.reducedMotion = false,
    super.key,
  });

  final double fraction;
  final String label;
  final String value;
  final bool isOver;
  final double size;
  final bool reducedMotion;

  @override
  State<BudgetRing> createState() => _BudgetRingState();
}

class _BudgetRingState extends State<BudgetRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: widget.fraction).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant BudgetRing old) {
    super.didUpdateWidget(old);
    if (old.fraction != widget.fraction) {
      _anim = Tween<double>(begin: old.fraction, end: widget.fraction).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.isOver
        ? scheme.error
        : (widget.fraction > 0.8 ? Colors.orange : scheme.primary);

    return Hero(
      tag: HeroTags.budgetRing,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => CustomPaint(
              painter: _RingPainter(
                progress: _anim.value,
                color: color,
                trackColor: scheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.value,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final stroke = 14.0;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final fill = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.7), color],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
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
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}

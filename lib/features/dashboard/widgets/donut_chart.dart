import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

class DonutSliceData {
  const DonutSliceData({
    required this.id,
    required this.fraction,
    required this.label,
    required this.color,
  });

  final String id;
  final double fraction;
  final String label;
  final Color color;
}

class DonutChart extends StatefulWidget {
  const DonutChart({
    required this.slices,
    required this.centerLabel,
    required this.centerValue,
    this.onSliceTapped,
    this.reducedMotion = false,
    super.key,
  });

  final List<DonutSliceData> slices;
  final String centerLabel;
  final String centerValue;
  final ValueChanged<DonutSliceData?>? onSliceTapped;
  final bool reducedMotion;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPos, Size size) {
    final painter = _DonutPainter(
      slices: widget.slices,
      progress: 1,
      selectedId: _selectedId,
    );
    final hit = painter.findSliceAt(localPos, size);
    Haptics.tap();
    setState(() => _selectedId = (hit?.id == _selectedId) ? null : hit?.id);
    widget.onSliceTapped?.call(hit);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onTapDown: (d) => _handleTap(d.localPosition, size),
                child: CustomPaint(
                  size: size,
                  painter: _DonutPainter(
                    slices: widget.slices,
                    progress: _ctrl.value,
                    selectedId: _selectedId,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.centerLabel,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.centerValue,
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
              );
            },
          );
        },
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    this.selectedId,
  });

  final List<DonutSliceData> slices;
  final double progress;
  final String? selectedId;

  // Cached per-slice paths from the last paint pass; used by hitTest().
  final Map<String, Path> _paths = {};

  @override
  void paint(Canvas canvas, Size size) {
    _buildPaths(size);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 6;
    final innerRadius = outerRadius * 0.62;

    if (slices.isEmpty) {
      final paint = Paint()
        ..color = AppColors.donutPalette.first.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerRadius - innerRadius;
      canvas.drawCircle(
        center,
        (outerRadius + innerRadius) / 2,
        paint,
      );
      return;
    }

    for (final s in slices) {
      final path = _paths[s.id];
      if (path == null) continue;

      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);

      final sep = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, sep);
    }
  }

  void _buildPaths(Size size) {
    _paths.clear();
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 6;
    final innerRadius = outerRadius * 0.62;

    var startAngle = -math.pi / 2;
    final totalSweep = 2 * math.pi * progress;
    var swept = 0.0;

    for (final s in slices) {
      final fullSweep = 2 * math.pi * s.fraction;
      final remaining = (totalSweep - swept).clamp(0.0, fullSweep);
      if (remaining > 0) {
        final isSelected = s.id == selectedId;
        final explode = isSelected ? 8.0 : 0.0;
        final midAngle = startAngle + remaining / 2;
        final sliceCenter = Offset(
          center.dx + math.cos(midAngle) * explode,
          center.dy + math.sin(midAngle) * explode,
        );
        _paths[s.id] = _slicePath(
          sliceCenter,
          outerRadius + (isSelected ? 4 : 0),
          innerRadius,
          startAngle,
          remaining,
        );
      }
      startAngle += fullSweep;
      swept += fullSweep;
    }
  }

  Path _slicePath(
    Offset center,
    double outer,
    double inner,
    double start,
    double sweep,
  ) {
    final outerRect = Rect.fromCircle(center: center, radius: outer);
    final innerRect = Rect.fromCircle(center: center, radius: inner);
    final p = Path();
    p.moveTo(
      center.dx + math.cos(start) * inner,
      center.dy + math.sin(start) * inner,
    );
    p.lineTo(
      center.dx + math.cos(start) * outer,
      center.dy + math.sin(start) * outer,
    );
    p.arcTo(outerRect, start, sweep, false);
    p.lineTo(
      center.dx + math.cos(start + sweep) * inner,
      center.dy + math.sin(start + sweep) * inner,
    );
    p.arcTo(innerRect, start + sweep, -sweep, false);
    p.close();
    return p;
  }

  /// Looks up which slice contains [localPos]. Renamed from `hitTest` so it
  /// doesn't collide with `CustomPainter.hitTest`'s `bool? Function(Offset)`
  /// override contract.
  DonutSliceData? findSliceAt(Offset localPos, Size size) {
    _buildPaths(size);
    for (final entry in _paths.entries) {
      if (entry.value.contains(localPos)) {
        return slices.firstWhere((s) => s.id == entry.key);
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    return old.progress != progress ||
        old.selectedId != selectedId ||
        old.slices != slices;
  }
}

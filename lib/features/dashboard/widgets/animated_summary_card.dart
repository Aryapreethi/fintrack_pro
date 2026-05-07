import 'package:flutter/material.dart';

import '../../../core/utils/haptics.dart';

/// A card with a count-up animated value, painted via TextPainter inside
/// CustomPainter for crisp typography control. Tap to flip and reveal back.
class AnimatedSummaryCard extends StatefulWidget {
  const AnimatedSummaryCard({
    required this.label,
    required this.value,
    required this.formatter,
    required this.heroTag,
    this.icon,
    this.subtitle,
    this.color,
    this.backLabel,
    this.backValue,
    this.reducedMotion = false,
    super.key,
  });

  final String label;
  final double value;
  final String Function(double) formatter;
  final Object heroTag;
  final IconData? icon;
  final String? subtitle;
  final Color? color;
  final String? backLabel;
  final double? backValue;
  final bool reducedMotion;

  @override
  State<AnimatedSummaryCard> createState() => _AnimatedSummaryCardState();
}

class _AnimatedSummaryCardState extends State<AnimatedSummaryCard>
    with TickerProviderStateMixin {
  late final AnimationController _countCtrl;
  late Animation<double> _countAnim;
  late final AnimationController _flipCtrl;
  double _previousValue = 0;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _countCtrl = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 900),
    );
    _countAnim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic),
    );
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _countCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedSummaryCard old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _previousValue = old.value;
      _countAnim = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic),
      );
      _countCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (widget.backValue == null) return;
    Haptics.light();
    if (_showBack) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.backValue != null ? _flip : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipCtrl, _countCtrl]),
        builder: (context, _) {
          final flipValue = _flipCtrl.value;
          final showingBack = flipValue >= 0.5;
          final angle = flipValue * 3.1415926;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(alpha: 0.12),
                ),
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: showingBack
                    ? (Matrix4.identity()..rotateY(3.1415926))
                    : Matrix4.identity(),
                child: showingBack
                    ? _buildBack(scheme, color)
                    : _buildFront(scheme, color),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(ColorScheme scheme, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Hero(
          tag: widget.heroTag,
          flightShuttleBuilder: (_, anim, _, _, _) => Material(
            color: Colors.transparent,
            child: Text(
              widget.formatter(_countAnim.value),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.formatter(_countAnim.value),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.subtitle!,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBack(ColorScheme scheme, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.backLabel ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.formatter(widget.backValue ?? 0),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

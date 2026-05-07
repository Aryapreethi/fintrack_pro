import 'package:flutter/material.dart';

import '../../../core/utils/haptics.dart';

class FlippableCard extends StatefulWidget {
  const FlippableCard({
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 480),
    this.reducedMotion = false,
    super.key,
  });

  final Widget front;
  final Widget back;
  final Duration duration;
  final bool reducedMotion;

  @override
  State<FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<FlippableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.reducedMotion ? Duration.zero : widget.duration,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    Haptics.light();
    if (_ctrl.value < 0.5) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final value = _ctrl.value;
          final showingBack = value >= 0.5;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(value * 3.1415926);
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: showingBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(3.1415926),
                    alignment: Alignment.center,
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}

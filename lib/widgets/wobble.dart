import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The flicker wobble applied to a die value while it's rolling.
///
/// Matches the prototype's `@keyframes wobble` — rotate/scale through
/// 0deg/1, -6deg/1.03, 5deg/0.98, -4deg/1.02, 0deg/1 over 350ms, easing
/// between each pair and looping until the die settles.
class Wobble extends StatefulWidget {
  const Wobble({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<Wobble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  late final Animation<double> _rotation = _sequence([0, -6, 5, -4, 0]);
  late final Animation<double> _scale = _sequence([1, 1.03, 0.98, 1.02, 1]);

  Animation<double> _sequence(List<double> stops) {
    return TweenSequence<double>([
      for (var i = 0; i < stops.length - 1; i++)
        TweenSequenceItem(
          tween: Tween(begin: stops[i], end: stops[i + 1])
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
    ]).animate(_controller);
  }

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(Wobble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat();
    } else {
      // Unwind to rest rather than snapping mid-tilt.
      _controller.animateTo(1.0).whenComplete(() {
        if (mounted && !widget.active) _controller.reset();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: AppShape.deg(_rotation.value),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

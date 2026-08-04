import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The warm paper field with its dot grain.
///
/// Mirrors the CSS
/// `radial-gradient(circle at 1px 1px, rgba(36,28,20,0.06) 1px, transparent 0)`
/// on a 14px tile: a 1px-radius dot near the top-left corner of every tile.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: CustomPaint(
        painter: const _GrainPainter(),
        child: child,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  static const _tile = 14.0;
  static const _dotRadius = 1.0;
  static const _dotOffset = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.grain;
    for (var y = _dotOffset; y < size.height + _tile; y += _tile) {
      for (var x = _dotOffset; x < size.width + _tile; x += _tile) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) => false;
}

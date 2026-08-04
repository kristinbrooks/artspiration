import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// A bordered surface with a flat offset shadow and a slight tilt — the base
/// shape for every card and button in the app.
///
/// The rotation wraps the shadow too, so the offset tilts with the card the way
/// a CSS `transform` on the shadowed element does.
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.child,
    required this.borderRadius,
    this.rotation = 0,
    this.background = AppColors.cardSurface,
    this.borderColor = AppColors.ink,
    this.borderWidth = 2.5,
    this.shadowColor = AppColors.ink,
    this.padding = EdgeInsets.zero,
    this.dashed = false,
    this.showShadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Degrees.
  final double rotation;

  final Color background;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final EdgeInsets padding;
  final bool dashed;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: dashed ? null : Border.all(color: borderColor, width: borderWidth),
        boxShadow: showShadow ? AppShape.sticker(shadowColor) : null,
      ),
      child: dashed
          ? CustomPaint(
              painter: _DashedBorderPainter(
                borderRadius: borderRadius,
                color: borderColor,
                strokeWidth: borderWidth,
              ),
              child: Padding(padding: padding, child: child),
            )
          : Padding(padding: padding, child: child),
    );

    if (rotation != 0) {
      surface = Transform.rotate(angle: AppShape.deg(rotation), child: surface);
    }
    return surface;
  }
}

/// Dashed variant of the border, used for the save button and the gallery
/// empty state. Flutter's [Border] has no dash support, so it's stroked by hand.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
  });

  final BorderRadius borderRadius;
  final Color color;
  final double strokeWidth;

  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()..addRRect(borderRadius.toRRect(rect).deflate(0));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

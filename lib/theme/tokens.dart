import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Design tokens from the Artspiration handoff.
///
/// The hand-drawn feel depends on values that look like mistakes but aren't:
/// four *different* corner radii per surface, a small rotation on nearly
/// everything, and flat offset shadows with no blur. Don't normalize them.
class AppColors {
  const AppColors._();

  /// Ink — all text and every border.
  static const ink = Color(0xFF241C14);

  /// Page background, under the dot grain.
  static const paper = Color(0xFFF7F1E4);

  /// Card surface. Slightly warmer than [cream].
  static const cardSurface = Color(0xFFFFFAF0);

  /// Fill/text that sits on ink, and the reroll/save button fill.
  static const cream = Color(0xFFFFF9EE);

  static const mutedBrown = Color(0xFF6B5F4D);
  static const emptyTitle = Color(0xFF8A7C62);
  static const emptyBody = Color(0xFFA3977F);

  // Inert dice — locked or switched off — use this ramp rather than the warm
  // muted browns above. It replaces the handoff's #E9E2D0 disabled fill, which
  // read as faded paper rather than as unavailable. Near-neutral, only a few
  // points of blue over red: enough to sit cooler than the warm paper without
  // the ramp itself reading as blue.
  static const offSurface = Color(0xFFE5E6E7);
  static const offShadow = Color(0xFFB5B6B9);
  static const offBorder = Color(0xFF9C9DA1);

  /// Text and pill fill on a switched-off die.
  static const offInk = Color(0xFF83858A);

  static const dashedRule = Color(0xFFB3A688);
  static const removeRed = Color(0xFFA34A3A);

  /// The grain dots scattered over [paper].
  static const grain = Color(0x0F241C14); // rgba(36,28,20,0.06)
}

/// Nunito ships as a variable font, so weight is applied through the `wght`
/// axis rather than by selecting a separate file. [fontWeight] is set too so
/// that any fallback font still renders at roughly the right weight.
class AppText {
  const AppText._();

  static const _kalam = 'Kalam';
  static const _nunito = 'Nunito';

  static TextStyle nunito(
    double size, {
    double weight = 400,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _nunito,
      fontSize: size,
      fontWeight: _nearestWeight(weight),
      fontVariations: [FontVariation('wght', weight)],
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle kalam(
    double size, {
    double weight = 700,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _kalam,
      fontSize: size,
      // Kalam is bundled as static 400/700 instances, so no variations here.
      fontWeight: weight >= 700 ? FontWeight.w700 : FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static FontWeight _nearestWeight(double weight) {
    final index = (weight / 100).round().clamp(1, 9) - 1;
    return FontWeight.values[index];
  }
}

/// Shape language: four differing radii plus a small rotation.
class AppShape {
  const AppShape._();

  /// Flat "sticker" shadow — 5px/5px offset, no blur, ever.
  static List<BoxShadow> sticker([Color color = AppColors.ink]) {
    return [BoxShadow(color: color, offset: const Offset(5, 5))];
  }

  /// CSS `border-radius: tl tr br bl`.
  static BorderRadius radii(double tl, double tr, double br, double bl) {
    return BorderRadius.only(
      topLeft: Radius.circular(tl),
      topRight: Radius.circular(tr),
      bottomRight: Radius.circular(br),
      bottomLeft: Radius.circular(bl),
    );
  }

  /// Degrees to radians. Positive is clockwise in both CSS and Flutter.
  static double deg(double degrees) => degrees * math.pi / 180.0;
}

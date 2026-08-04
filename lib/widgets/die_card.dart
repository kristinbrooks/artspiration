import 'package:flutter/widgets.dart';

import '../data/categories.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'sticker.dart';
import 'wobble.dart';

/// One prompt die: category pill, lock toggle, current value, reroll.
class DieCard extends StatelessWidget {
  const DieCard({
    super.key,
    required this.category,
    required this.state,
    required this.onToggleLock,
    required this.onReroll,
  });

  final DieCategory category;
  final DieState state;
  final VoidCallback onToggleLock;
  final VoidCallback onReroll;

  @override
  Widget build(BuildContext context) {
    final off = !state.enabled;

    return Sticker(
      rotation: category.cardRotation,
      borderRadius: category.borderRadius,
      // A die that's out of play keeps its place in the grid but goes flat and
      // colourless, so the layout doesn't reshuffle when one is switched off.
      background: off ? AppColors.offSurface : AppColors.cardSurface,
      borderColor: off ? AppColors.offBorder : AppColors.ink,
      shadowColor: off ? AppColors.offShadow : AppColors.ink,
      // The handoff specifies 14px vertical padding and 8px internal gaps, at
      // six dice. At eight, that pushes the last row off an iPhone screen, so
      // the card is tightened just enough for the full grid to fit.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: _CategoryPill(category: category, off: off)),
              const SizedBox(width: 4),
              // Nothing to lock on a die that isn't rolling.
              if (!off)
                _LockToggle(locked: state.locked, onTap: onToggleLock),
            ],
          ),
          const SizedBox(height: 6),
          Wobble(
            active: state.spinning,
            child: SizedBox(
              // Exactly one line tall, so every card is the same height and the
              // full grid fits a phone screen whatever the roll. Long values
              // scale down rather than wrapping. Derived from the text scaler
              // so large-text users still get bigger type (and a taller grid
              // they can scroll) instead of everything shrinking to fit.
              height: MediaQuery.textScalerOf(context).scale(19) * 1.25,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  state.value,
                  maxLines: 1,
                  softWrap: false,
                  style: AppText.kalam(
                    19,
                    height: 1.25,
                    color: off ? AppColors.offInk : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _RerollButton(locked: state.locked, off: off, onTap: onReroll),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category, this.off = false});

  final DieCategory category;
  final bool off;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: AppShape.deg(category.pillRotation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          // Losing the accent is what makes an off die read as off at a glance.
          color: off ? AppColors.offInk : category.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          category.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppText.kalam(
            11.5,
            color: const Color(0xFFFFFFFF),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _LockToggle extends StatelessWidget {
  const _LockToggle({required this.locked, required this.onTap});

  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        toggled: locked,
        label: locked ? 'Locked' : 'Lock',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: locked ? AppColors.ink : const Color(0x00000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
          child: Text(
            locked ? 'LOCKED' : 'LOCK',
            style: AppText.nunito(
              10,
              weight: 800,
              color: locked ? AppColors.cream : AppColors.ink,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _RerollButton extends StatelessWidget {
  const _RerollButton({
    required this.locked,
    required this.off,
    required this.onTap,
  });

  final bool locked;

  /// The die is out of play. Shares the locked fill and text — both are inert —
  /// but takes the muted border too, since the whole card is muted.
  final bool off;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inert = locked || off;

    return Opacity(
      opacity: inert ? 0.6 : 1,
      child: GestureDetector(
        onTap: inert ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: inert ? AppColors.offSurface : AppColors.cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: off ? AppColors.offBorder : AppColors.ink,
              width: 2,
            ),
          ),
          child: Text(
            '↻ Reroll',
            style: AppText.nunito(
              12.5,
              weight: 700,
              color: inert ? AppColors.offInk : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

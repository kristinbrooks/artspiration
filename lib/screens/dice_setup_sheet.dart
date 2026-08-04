import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';

import '../data/categories.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/sticker.dart';

/// Lets someone choose which dice are in play, for a simpler prompt.
///
/// A sheet rather than a control on each card: the roll card's top row is
/// already a category pill plus the lock toggle at roughly 170px wide, and a
/// third control there would force the layout to wrap on every die.
Future<void> showDiceSetupSheet(
  BuildContext context,
  ArtspirationState state,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0x00000000),
    isScrollControlled: true,
    builder: (context) => _DiceSetupSheet(state: state),
  );
}

class _DiceSetupSheet extends StatelessWidget {
  const _DiceSetupSheet({required this.state});

  final ArtspirationState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final enabled = state.enabledCategories.length;
        // The last die can't be switched off, so its row goes inert rather than
        // failing silently under a tap.
        final atMinimum = enabled == 1;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(
              top: BorderSide(color: AppColors.ink, width: 2.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Transform.rotate(
                      angle: AppShape.deg(-1.5),
                      child: Text('Which dice?', style: AppText.kalam(24)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Switch off what you don’t want in the prompt',
                      textAlign: TextAlign.center,
                      style: AppText.nunito(13, color: AppColors.mutedBrown),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final category in DieCategory.values) ...[
                    _DieRow(
                      category: category,
                      enabled: state.die(category).enabled,
                      locked: atMinimum && state.die(category).enabled,
                      onTap: () => state.setEnabled(
                        category,
                        !state.die(category).enabled,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 2),
                  _DoneButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DieRow extends StatelessWidget {
  const _DieRow({
    required this.category,
    required this.enabled,
    required this.locked,
    required this.onTap,
  });

  final DieCategory category;
  final bool enabled;

  /// The only die still in play — it can't be switched off.
  final bool locked;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Semantics(
        button: true,
        toggled: enabled,
        label: category.label,
        child: Sticker(
          borderRadius: category.borderRadius,
          background: enabled ? AppColors.cardSurface : AppColors.offSurface,
          borderColor: enabled ? AppColors.ink : AppColors.offBorder,
          shadowColor: enabled ? AppColors.ink : AppColors.offShadow,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: enabled ? category.accent : AppColors.offInk,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.label.toUpperCase(),
                  style: AppText.kalam(
                    11.5,
                    color: const Color(0xFFFFFFFF),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              _StateBadge(enabled: enabled, locked: locked),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.enabled, required this.locked});

  final bool enabled;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final label = locked ? 'KEEP' : (enabled ? 'ON' : 'OFF');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? AppColors.ink : const Color(0x00000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? AppColors.ink : AppColors.offBorder,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: AppText.nunito(
          10,
          weight: 800,
          color: enabled ? AppColors.cream : AppColors.offInk,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Sticker(
        rotation: -0.8,
        borderRadius: AppShape.radii(20, 26, 22, 28),
        background: AppColors.ink,
        shadowColor: DieCategory.style.accent,
        padding: const EdgeInsets.all(14),
        child: Center(
          child: Text('Done', style: AppText.kalam(20, color: AppColors.cream)),
        ),
      ),
    );
  }
}

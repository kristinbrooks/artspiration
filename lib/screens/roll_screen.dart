import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../data/categories.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/die_card.dart';
import '../widgets/sticker.dart';
import 'dice_setup_sheet.dart';

class RollScreen extends StatelessWidget {
  const RollScreen({super.key, required this.state, required this.topInset});

  final ArtspirationState state;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, topInset, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RollHeader(state: state),
                // Was 18 (16px column gap + 2px header margin); trimmed to pay
                // for the picker button's height.
                const SizedBox(height: 7),
                _DiceGrid(state: state),
              ],
            ),
          ),
        ),
        // Pinned rather than scrolled with the dice: past six dice the grid is
        // taller than a phone frame, and saving is the action that ends the
        // session — it shouldn't sit below the fold. Opaque paper and the same
        // hairline the tab bar uses, so the grid reads as scrolling underneath
        // a fixed bar instead of being clipped mid-card.
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(
              top: BorderSide(color: Color(0x1F241C14), width: 2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _RollAllButton(onTap: state.rollAll),
                const SizedBox(height: 12),
                _SaveButton(onTap: state.saveToGallery),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RollHeader extends StatelessWidget {
  const _RollHeader({required this.state});

  final ArtspirationState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.rotate(
          angle: AppShape.deg(-2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _DieLogo(),
              const SizedBox(width: 8),
              // Flexible so a large text scale shrinks the title into the row
              // rather than overflowing it.
              Flexible(
                child: Text(
                  'Artspiration',
                  maxLines: 1,
                  style: AppText.kalam(28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // This row was the "Lock what you like, reroll the rest" tagline. The
        // grid clears an iPhone screen by only a few pixels, so the picker
        // could either share that line as a cramped chip or take it over
        // outright — and a control people can find beats a restatement of what
        // the buttons already say.
        _DicePicker(state: state),
      ],
    );
  }
}

/// Opens the setup sheet, and doubles as a readout of how many dice are in
/// play — otherwise a switched-off die is only visible by scanning the grid.
class _DicePicker extends StatelessWidget {
  const _DicePicker({required this.state});

  final ArtspirationState state;

  @override
  Widget build(BuildContext context) {
    final enabled = state.enabledCategories.length;
    final total = DieCategory.values.length;

    return GestureDetector(
      onTap: () => showDiceSetupSheet(context, state),
      child: Semantics(
        button: true,
        label: '$enabled of $total dice in play. Choose dice.',
        child: Sticker(
          rotation: 1,
          borderRadius: AppShape.radii(13, 9, 13, 9),
          // Always filled. This used to invert only when dice were sitting out,
          // but the count in the label already says that, and the solid version
          // reads far more like a button.
          background: AppColors.ink,
          borderWidth: 2,
          showShadow: false,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 14,
                color: AppColors.cream,
              ),
              const SizedBox(width: 6),
              Text(
                'Choose dice · $enabled/$total',
                style: AppText.nunito(
                  12.5,
                  weight: 800,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 26x26 die with three pips on the diagonal — drawn, not an asset.
class _DieLogo extends StatelessWidget {
  const _DieLogo();

  @override
  Widget build(BuildContext context) {
    const pip = SizedBox(
      width: 5,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paper,
          shape: BoxShape.circle,
        ),
      ),
    );

    return SizedBox(
      width: 26,
      height: 26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Stack(
          children: [
            Positioned(top: 4, left: 4, child: pip),
            Positioned(top: 10.5, left: 10.5, child: pip),
            Positioned(bottom: 4, right: 4, child: pip),
          ],
        ),
      ),
    );
  }
}

/// Two columns, 14px gutter. Cards in a row share a height, matching the
/// stretch behavior of the CSS grid they came from.
///
/// An odd number of dice leaves the final cell empty rather than stretching
/// the last card across both columns — same as the CSS grid would.
class _DiceGrid extends StatelessWidget {
  const _DiceGrid({required this.state});

  final ArtspirationState state;

  // 14px in the handoff; tightened so eight dice clear an iPhone screen.
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    const categories = DieCategory.values;
    final rows = <Widget>[];

    for (var i = 0; i < categories.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: _gap));
      final hasSecond = i + 1 < categories.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _cardFor(categories[i])),
              const SizedBox(width: _gap),
              Expanded(
                child: hasSecond
                    ? _cardFor(categories[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _cardFor(DieCategory category) {
    return DieCard(
      category: category,
      state: state.die(category),
      onToggleLock: () => state.toggleLock(category),
      onReroll: () => state.spin(category),
    );
  }
}

class _RollAllButton extends StatelessWidget {
  const _RollAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Sticker(
        rotation: -0.8,
        borderRadius: AppShape.radii(20, 26, 22, 28),
        background: AppColors.ink,
        shadowColor: DieCategory.style.accent, // mustard
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Roll All Dice',
            style: AppText.kalam(22, color: AppColors.cream),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Sticker(
        borderRadius: BorderRadius.circular(14),
        background: AppColors.cream,
        borderWidth: 2,
        dashed: true,
        showShadow: false,
        padding: const EdgeInsets.all(11),
        child: Center(
          child: Text(
            '+ Save this roll to Gallery',
            style: AppText.nunito(14, weight: 800),
          ),
        ),
      ),
    );
  }
}

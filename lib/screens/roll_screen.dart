import 'package:flutter/widgets.dart';

import '../data/categories.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/die_card.dart';
import '../widgets/sticker.dart';

class RollScreen extends StatelessWidget {
  const RollScreen({super.key, required this.state});

  final ArtspirationState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RollHeader(),
        const SizedBox(height: 18), // 16px column gap + 2px header margin
        _DiceGrid(state: state),
        const SizedBox(height: 20), // 16px gap + 4px button margin
        _RollAllButton(onTap: state.rollAll),
        const SizedBox(height: 16),
        _SaveButton(onTap: state.saveToGallery),
      ],
    );
  }
}

class _RollHeader extends StatelessWidget {
  const _RollHeader();

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
        const SizedBox(height: 4),
        Text(
          'Lock what you like, reroll the rest',
          style: AppText.nunito(13, color: AppColors.mutedBrown),
        ),
      ],
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
class _DiceGrid extends StatelessWidget {
  const _DiceGrid({required this.state});

  final ArtspirationState state;

  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    const categories = DieCategory.values;
    final rows = <Widget>[];

    for (var i = 0; i < categories.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: _gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _cardFor(categories[i])),
              const SizedBox(width: _gap),
              Expanded(child: _cardFor(categories[i + 1])),
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

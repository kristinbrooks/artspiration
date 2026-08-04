import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';

/// Persistent two-tab bar. The prototype used Unicode glyphs as placeholders;
/// these are the real icons the handoff called for.
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: Color(0x1F241C14), width: 2)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset > 0 ? bottomInset : 22),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: Icons.casino_rounded,
                label: 'Roll',
                active: current == AppTab.roll,
                onTap: () => onChanged(AppTab.roll),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TabButton(
                icon: Icons.grid_view_rounded,
                label: 'Gallery',
                active: current == AppTab.gallery,
                onTap: () => onChanged(AppTab.gallery),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.cream : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.nunito(13, weight: 800, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

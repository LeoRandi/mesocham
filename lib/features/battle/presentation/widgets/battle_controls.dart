import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BattleControls extends StatelessWidget {
  const BattleControls({
    super.key,
    required this.onFight,
    required this.fightEnabled,
    required this.compact,
  });

  final VoidCallback onFight;
  final bool fightEnabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 43 : 58,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(compact ? 12 : 17),
        border: Border.all(color: AppColors.sand.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _BattleAction(
            label: 'FIGHT',
            icon: Icons.sports_mma_rounded,
            enabled: fightEnabled,
            onTap: onFight,
            compact: compact,
          ),
          _BattleAction(
            label: 'TEAM SKILL',
            icon: Icons.auto_awesome_rounded,
            enabled: false,
            compact: compact,
          ),
          _BattleAction(
            label: 'SPECIES',
            icon: Icons.style_rounded,
            enabled: false,
            compact: compact,
          ),
          _BattleAction(
            label: 'SWAP',
            icon: Icons.swap_horiz_rounded,
            enabled: false,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _BattleAction extends StatelessWidget {
  const _BattleAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.compact,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.amber
        : AppColors.bone.withValues(alpha: 0.24);

    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Material(
          color: enabled
              ? AppColors.amber.withValues(alpha: 0.11)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 10 : 15),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(compact ? 10 : 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: compact ? 15 : 21),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 7 : 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

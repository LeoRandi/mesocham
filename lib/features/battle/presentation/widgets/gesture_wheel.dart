import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/champion.dart';

class GestureWheel extends StatelessWidget {
  const GestureWheel({
    super.key,
    required this.champion,
    required this.selected,
    required this.onSelected,
    required this.enabled,
    required this.compact,
    required this.label,
  });

  final Champion champion;
  final BattleGesture? selected;
  final ValueChanged<BattleGesture> onSelected;
  final bool enabled;
  final bool compact;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        width: compact ? 295 : 420,
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 13,
          compact ? 5 : 8,
          compact ? 8 : 13,
          compact ? 7 : 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.sand.withValues(alpha: 0.48),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: BattleGesture.values
              .map(
                (gesture) => Expanded(
                  child: _GestureChoice(
                    gesture: gesture,
                    moveName: champion.moveFor(gesture).name,
                    critical: champion.moveFor(gesture).isCritical,
                    selected: selected == gesture,
                    enabled: enabled,
                    compact: compact,
                    onTap: () => onSelected(gesture),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _GestureChoice extends StatelessWidget {
  const _GestureChoice({
    required this.gesture,
    required this.moveName,
    required this.critical,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  final BattleGesture gesture;
  final String moveName;
  final bool critical;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(gesture);
    final iconSize = compact ? 22.0 : 33.0;

    return Semantics(
      button: enabled,
      selected: selected,
      label: '${_labelFor(gesture)}, $moveName${critical ? ', critical' : ''}',
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: AnimatedScale(
            scale: selected ? 1.11 : 0.92,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.symmetric(horizontal: compact ? 3 : 5),
              padding: EdgeInsets.symmetric(vertical: compact ? 4 : 7),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.98)
                    : color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : color.withValues(alpha: 0.72),
                  width: selected ? 2.2 : 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.7),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconFor(gesture),
                    size: iconSize,
                    color: selected ? AppColors.ink : color,
                  ),
                  SizedBox(width: compact ? 4 : 7),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labelFor(gesture).toUpperCase(),
                          maxLines: 1,
                          style: TextStyle(
                            color: selected ? AppColors.ink : AppColors.bone,
                            fontSize: compact ? 8 : 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        Text(
                          moveName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.ink.withValues(alpha: 0.78)
                                : AppColors.sand.withValues(alpha: 0.7),
                            fontSize: compact ? 6 : 8,
                            fontWeight: critical
                                ? FontWeight.w900
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _colorFor(BattleGesture gesture) => switch (gesture) {
    BattleGesture.rock => AppColors.rock,
    BattleGesture.paper => AppColors.paper,
    BattleGesture.scissors => AppColors.scissors,
  };

  IconData _iconFor(BattleGesture gesture) => switch (gesture) {
    BattleGesture.rock => Icons.sports_mma_rounded,
    BattleGesture.paper => Icons.front_hand_rounded,
    BattleGesture.scissors => Icons.content_cut_rounded,
  };

  String _labelFor(BattleGesture gesture) => switch (gesture) {
    BattleGesture.rock => 'Rock',
    BattleGesture.paper => 'Paper',
    BattleGesture.scissors => 'Scissors',
  };
}

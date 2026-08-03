import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/champion_move.dart';

/// The move summary shared by the Museum and battle hover previews.
class ChampionMoveDetails extends StatelessWidget {
  const ChampionMoveDetails({
    super.key,
    required this.move,
    required this.compact,
    this.obscured = false,
  });

  final ChampionMove move;
  final bool compact;
  final bool obscured;

  @override
  Widget build(BuildContext context) {
    final accent = obscured ? AppColors.deepEarth : _gestureColor(move.gesture);
    final potencyLabel = move.potency == move.potency.roundToDouble()
        ? move.potency.toStringAsFixed(0)
        : move.potency.toStringAsFixed(1);

    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(minHeight: compact ? 76 : 108),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(compact ? 11 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obscured ? '???' : move.name,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: compact ? 12 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: compact ? 5 : 8),
                    Text(
                      obscured ? '???' : move.description,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.84),
                        fontSize: compact ? 9.5 : 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!obscured && move.effectTurns > 0) ...[
                      SizedBox(height: compact ? 5 : 8),
                      Text(
                        'Effect duration: ${move.effectTurns} turns',
                        style: TextStyle(
                          color: AppColors.deepEarth,
                          fontSize: compact ? 8.5 : 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _MovePowerPanel(
              potencyLabel: obscured ? '???' : potencyLabel,
              critical: !obscured && move.isCritical,
              color: accent,
              compact: compact,
              obscured: obscured,
            ),
          ],
        ),
      ),
    );
  }
}

class _MovePowerPanel extends StatelessWidget {
  const _MovePowerPanel({
    required this.potencyLabel,
    required this.critical,
    required this.color,
    required this.compact,
    required this.obscured,
  });

  final String potencyLabel;
  final bool critical;
  final Color color;
  final bool compact;
  final bool obscured;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: obscured
          ? 'Unknown move power'
          : '$potencyLabel power${critical ? ', critical move' : ''}',
      child: Container(
        width: compact ? 78 : 112,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border(
            left: BorderSide(
              color: color.withValues(alpha: 0.82),
              width: compact ? 1.5 : 2,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                potencyLabel,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: compact ? 25 : 36,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: compact ? 3 : 5),
            Text(
              'POWER',
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.72),
                fontSize: compact ? 8 : 11,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 1 : 1.5,
              ),
            ),
            if (critical) ...[
              SizedBox(height: compact ? 6 : 9),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: compact ? 3 : 5),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.8),
                  ),
                ),
                child: Text(
                  'CRITICAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: compact ? 6.5 : 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color _gestureColor(BattleGesture gesture) => switch (gesture) {
  BattleGesture.rock => AppColors.rock,
  BattleGesture.paper => AppColors.paper,
  BattleGesture.scissors => AppColors.scissors,
};

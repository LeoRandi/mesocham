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
    this.focusNodes,
  }) : assert(focusNodes == null || focusNodes.length == 3);

  final Champion champion;
  final BattleGesture? selected;
  final ValueChanged<BattleGesture> onSelected;
  final bool enabled;
  final bool compact;
  final String label;
  final List<FocusNode>? focusNodes;

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
          children: [
            for (var index = 0; index < BattleGesture.values.length; index++)
              Expanded(
                child: _GestureChoice(
                  gesture: BattleGesture.values[index],
                  moveName: champion.moveFor(BattleGesture.values[index]).name,
                  critical: champion
                      .moveFor(BattleGesture.values[index])
                      .isCritical,
                  selected: selected == BattleGesture.values[index],
                  enabled: enabled,
                  compact: compact,
                  focusNode: focusNodes?[index],
                  shortcutNumber: focusNodes == null ? null : index + 1,
                  onTap: () => onSelected(BattleGesture.values[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GestureChoice extends StatefulWidget {
  const _GestureChoice({
    required this.gesture,
    required this.moveName,
    required this.critical,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.focusNode,
    required this.shortcutNumber,
    required this.onTap,
  });

  final BattleGesture gesture;
  final String moveName;
  final bool critical;
  final bool selected;
  final bool enabled;
  final bool compact;
  final FocusNode? focusNode;
  final int? shortcutNumber;
  final VoidCallback onTap;

  @override
  State<_GestureChoice> createState() => _GestureChoiceState();
}

class _GestureChoiceState extends State<_GestureChoice> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(widget.gesture);
    final iconSize = widget.compact ? 22.0 : 33.0;
    final shortcutPrefix = widget.shortcutNumber == null
        ? ''
        : '${widget.shortcutNumber}, ';
    final displayLabel = widget.shortcutNumber == null
        ? _labelFor(widget.gesture).toUpperCase()
        : '${widget.shortcutNumber}  ${_labelFor(widget.gesture).toUpperCase()}';

    return Semantics(
      button: widget.enabled,
      selected: widget.selected,
      label:
          '$shortcutPrefix${_labelFor(widget.gesture)}, ${widget.moveName}${widget.critical ? ', critical' : ''}',
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: widget.shortcutNumber == null
                ? null
                : ValueKey('battle-move-${widget.gesture.name}'),
            focusNode: widget.focusNode,
            canRequestFocus: widget.enabled,
            onFocusChange: (focused) => setState(() => _focused = focused),
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedScale(
              scale: widget.selected ? 1.11 : (_focused ? 1.02 : 0.92),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 3 : 5,
                ),
                padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 7),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? color.withValues(alpha: 0.98)
                      : color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: widget.selected || _focused
                        ? Colors.white
                        : color.withValues(alpha: 0.72),
                    width: widget.selected || _focused ? 2.2 : 1.2,
                  ),
                  boxShadow: widget.selected || _focused
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
                      _iconFor(widget.gesture),
                      size: iconSize,
                      color: widget.selected ? AppColors.ink : color,
                    ),
                    SizedBox(width: widget.compact ? 4 : 7),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayLabel,
                            maxLines: 1,
                            style: TextStyle(
                              color: widget.selected
                                  ? AppColors.ink
                                  : AppColors.bone,
                              fontSize: widget.compact ? 8 : 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                          Text(
                            widget.moveName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.selected
                                  ? AppColors.ink.withValues(alpha: 0.78)
                                  : AppColors.sand.withValues(alpha: 0.7),
                              fontSize: widget.compact ? 6 : 8,
                              fontWeight: widget.critical
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

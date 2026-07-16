import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class BattleControls extends StatelessWidget {
  const BattleControls({
    super.key,
    required this.onFight,
    required this.fightEnabled,
    required this.compact,
    required this.focusNodes,
    required this.canFocus,
  }) : assert(focusNodes.length == 4);

  final VoidCallback onFight;
  final bool fightEnabled;
  final bool compact;
  final List<FocusNode> focusNodes;
  final bool canFocus;

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
            focusNode: focusNodes[0],
            canFocus: canFocus,
            shortcutNumber: 1,
          ),
          _BattleAction(
            label: 'TEAM SKILL',
            icon: Icons.auto_awesome_rounded,
            enabled: false,
            compact: compact,
            focusNode: focusNodes[1],
            canFocus: canFocus,
            shortcutNumber: 2,
          ),
          _BattleAction(
            label: 'SPECIES',
            icon: Icons.style_rounded,
            enabled: false,
            compact: compact,
            focusNode: focusNodes[2],
            canFocus: canFocus,
            shortcutNumber: 3,
          ),
          _BattleAction(
            label: 'SWAP',
            icon: Icons.swap_horiz_rounded,
            enabled: false,
            compact: compact,
            focusNode: focusNodes[3],
            canFocus: canFocus,
            shortcutNumber: 4,
          ),
        ],
      ),
    );
  }
}

class _BattleAction extends StatefulWidget {
  const _BattleAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.compact,
    required this.focusNode,
    required this.canFocus,
    required this.shortcutNumber,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool compact;
  final FocusNode focusNode;
  final bool canFocus;
  final int shortcutNumber;
  final VoidCallback? onTap;

  @override
  State<_BattleAction> createState() => _BattleActionState();
}

class _BattleActionState extends State<_BattleAction> {
  bool _focused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.space)) {
      return KeyEventResult.ignored;
    }

    if (widget.enabled) {
      widget.onTap?.call();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled
        ? AppColors.amber
        : AppColors.bone.withValues(alpha: 0.24);
    final radius = BorderRadius.circular(widget.compact ? 10 : 15);

    return Expanded(
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: '${widget.shortcutNumber}, ${widget.label}',
        child: Focus(
          key: ValueKey('battle-action-${widget.shortcutNumber}'),
          focusNode: widget.focusNode,
          canRequestFocus: widget.canFocus,
          onFocusChange: (focused) => setState(() => _focused = focused),
          onKeyEvent: _handleKeyEvent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _focused ? AppColors.bone : Colors.transparent,
                width: 2,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : const [],
            ),
            child: Material(
              color: widget.enabled
                  ? AppColors.amber.withValues(alpha: 0.11)
                  : Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                canRequestFocus: false,
                onTap: widget.enabled
                    ? () {
                        widget.focusNode.requestFocus();
                        widget.onTap?.call();
                      }
                    : null,
                borderRadius: radius,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: color,
                      size: widget.compact ? 15 : 21,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.shortcutNumber}  ${widget.label}',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: color,
                        fontSize: widget.compact ? 7 : 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
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
}

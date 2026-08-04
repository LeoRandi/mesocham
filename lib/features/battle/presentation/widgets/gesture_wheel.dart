import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../champions/domain/entities/champion.dart';
import '../../../champions/domain/entities/champion_move.dart';
import '../../../champions/presentation/widgets/battle_gesture_icon.dart';
import '../../../champions/presentation/widgets/champion_move_details.dart';
import '../../domain/entities/battle_gesture.dart';

class GestureDetailsController {
  Object? _pinnedOwner;
  VoidCallback? _dismissPinnedDetails;

  void pin(Object owner, VoidCallback dismiss) {
    if (identical(_pinnedOwner, owner)) return;
    final previousDismiss = _dismissPinnedDetails;
    _pinnedOwner = owner;
    _dismissPinnedDetails = dismiss;
    previousDismiss?.call();
  }

  void release(Object owner) {
    if (!identical(_pinnedOwner, owner)) return;
    _pinnedOwner = null;
    _dismissPinnedDetails = null;
  }

  void dismiss() {
    final dismissPinnedDetails = _dismissPinnedDetails;
    _pinnedOwner = null;
    _dismissPinnedDetails = null;
    dismissPinnedDetails?.call();
  }
}

class GestureWheel extends StatelessWidget {
  const GestureWheel({
    super.key,
    required this.champion,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.label,
    required this.isOpponent,
    required this.showDetails,
    this.onSelected,
    this.focusNodes,
    this.detailsController,
  }) : assert(focusNodes == null || focusNodes.length == 3);

  final Champion champion;
  final BattleGesture? selected;
  final ValueChanged<BattleGesture>? onSelected;
  final bool enabled;
  final bool compact;
  final String label;
  final bool isOpponent;
  final bool showDetails;
  final List<FocusNode>? focusNodes;
  final GestureDetailsController? detailsController;

  @override
  Widget build(BuildContext context) {
    final side = compact ? 188.0 : 244.0;
    final buttonSize = (compact ? 59.0 : 76.0) * 4 / 3;
    final accent = isOpponent ? AppColors.danger : AppColors.paper;

    return Semantics(
      label: label,
      child: SizedBox.square(
        dimension: side,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: _OrbitRing(
                key: ValueKey(
                  '${isOpponent ? 'opponent' : 'player'}-fight-ring-outer',
                ),
                diameter: side * 0.92,
                color: accent,
                strokeWidth: compact ? 2.5 : 3.5,
              ),
            ),
            Center(
              child: _OrbitRing(
                key: ValueKey(
                  '${isOpponent ? 'opponent' : 'player'}-fight-ring-inner',
                ),
                diameter: side * 0.61,
                color: accent,
                strokeWidth: compact ? 2 : 3,
              ),
            ),
            for (var index = 0; index < BattleGesture.values.length; index++)
              _positionedChoice(
                gesture: BattleGesture.values[index],
                index: index,
                side: side,
                buttonSize: buttonSize,
              ),
          ],
        ),
      ),
    );
  }

  Widget _positionedChoice({
    required BattleGesture gesture,
    required int index,
    required double side,
    required double buttonSize,
  }) {
    final center = _gestureCenter(gesture);
    return Positioned(
      left: side * center.dx - buttonSize / 2,
      top: side * center.dy - buttonSize / 2,
      width: buttonSize,
      height: buttonSize,
      child: _GestureChoice(
        gesture: gesture,
        move: champion.moveFor(gesture),
        selected: selected == gesture,
        enabled: enabled,
        compact: compact,
        isOpponent: isOpponent,
        showDetails: showDetails,
        focusNode: focusNodes?[index],
        shortcutNumber: focusNodes == null ? null : index + 1,
        onTap: onSelected == null ? null : () => onSelected!(gesture),
        detailsController: detailsController,
      ),
    );
  }

  Offset _gestureCenter(BattleGesture gesture) {
    if (isOpponent) {
      return switch (gesture) {
        BattleGesture.rock => const Offset(0.5, 0.79),
        BattleGesture.paper => const Offset(0.79, 0.23),
        BattleGesture.scissors => const Offset(0.21, 0.23),
      };
    }
    return switch (gesture) {
      BattleGesture.rock => const Offset(0.5, 0.21),
      BattleGesture.paper => const Offset(0.79, 0.77),
      BattleGesture.scissors => const Offset(0.21, 0.77),
    };
  }
}

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({
    super.key,
    required this.diameter,
    required this.color,
    required this.strokeWidth,
  });

  final double diameter;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: strokeWidth),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 8,
              spreadRadius: 1,
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
    required this.move,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.isOpponent,
    required this.showDetails,
    required this.focusNode,
    required this.shortcutNumber,
    required this.onTap,
    required this.detailsController,
  });

  final BattleGesture gesture;
  final ChampionMove move;
  final bool selected;
  final bool enabled;
  final bool compact;
  final bool isOpponent;
  final bool showDetails;
  final FocusNode? focusNode;
  final int? shortcutNumber;
  final VoidCallback? onTap;
  final GestureDetailsController? detailsController;

  @override
  State<_GestureChoice> createState() => _GestureChoiceState();
}

class _GestureChoiceState extends State<_GestureChoice> {
  bool _focused = false;
  bool _hovered = false;
  bool _detailsPinned = false;
  OverlayEntry? _detailsEntry;
  Offset _pointerPosition = Offset.zero;

  @override
  void didUpdateWidget(covariant _GestureChoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showDetails || oldWidget.move != widget.move) {
      widget.detailsController?.release(this);
      _detailsPinned = false;
      _removeDetails();
    }
  }

  @override
  void dispose() {
    widget.detailsController?.release(this);
    _removeDetails();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(widget.gesture);
    final shortcutPrefix = widget.shortcutNumber == null
        ? ''
        : '${widget.shortcutNumber}, ';
    final highlighted = _focused || _hovered || _detailsPinned;
    final selectable = widget.enabled && widget.onTap != null;

    return Semantics(
      button: selectable,
      selected: widget.selected,
      label:
          '$shortcutPrefix${_labelFor(widget.gesture)}, ${widget.move.name}'
          '${widget.move.isCritical ? ', critical' : ''}',
      child: MouseRegion(
        cursor: selectable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (event) {
          setState(() => _hovered = true);
          _showDetails(event.position);
        },
        onHover: (event) => _updateDetailsPosition(event.position),
        onExit: (_) {
          setState(() => _hovered = false);
          if (!_detailsPinned) _removeDetails();
        },
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            key: ValueKey(
              '${widget.isOpponent ? 'opponent-move' : 'battle-move'}-'
              '${widget.gesture.name}',
            ),
            focusNode: widget.focusNode,
            canRequestFocus: selectable,
            customBorder: const CircleBorder(),
            onFocusChange: (focused) => setState(() => _focused = focused),
            onTap: selectable
                ? () {
                    if (widget.detailsController case final controller?) {
                      controller.dismiss();
                    } else {
                      _dismissPinnedPreview();
                    }
                    widget.focusNode?.requestFocus();
                    widget.onTap!();
                  }
                : null,
            onLongPress: widget.showDetails ? _pinDetails : null,
            child: AnimatedScale(
              scale: widget.selected ? 1.13 : (highlighted ? 1.06 : 0.96),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                key: widget.selected
                    ? ValueKey('selected-battle-move-${widget.gesture.name}')
                    : null,
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected
                      ? color.withValues(alpha: 0.42)
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.selected || highlighted
                        ? Colors.white
                        : Colors.transparent,
                    width: widget.selected ? 3 : 2,
                  ),
                  boxShadow: widget.selected || highlighted
                      ? [
                          BoxShadow(
                            color: color.withValues(
                              alpha: widget.selected ? 0.9 : 0.58,
                            ),
                            blurRadius: widget.selected ? 22 : 14,
                            spreadRadius: widget.selected ? 4 : 2,
                          ),
                        ]
                      : const [],
                ),
                padding: EdgeInsets.all(widget.compact ? 2 : 3),
                child: BattleGestureIcon(
                  gesture: widget.gesture,
                  critical: widget.move.isCritical,
                  size: (widget.compact ? 54 : 70) * 4 / 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pinDetails() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    widget.detailsController?.pin(this, _dismissPinnedPreview);
    setState(() => _detailsPinned = true);
    _showDetails(
      renderObject.localToGlobal(renderObject.size.center(Offset.zero)),
    );
  }

  void _dismissPinnedPreview() {
    widget.detailsController?.release(this);
    if (!_detailsPinned) return;
    if (mounted) {
      setState(() => _detailsPinned = false);
    } else {
      _detailsPinned = false;
    }
    if (!_hovered) _removeDetails();
  }

  void _showDetails(Offset globalPosition) {
    if (!widget.showDetails) return;
    _pointerPosition = globalPosition;
    _detailsEntry ??= OverlayEntry(builder: _buildDetailsOverlay);
    if (!_detailsEntry!.mounted) {
      Overlay.of(context, rootOverlay: true).insert(_detailsEntry!);
    }
    _detailsEntry!.markNeedsBuild();
  }

  void _updateDetailsPosition(Offset globalPosition) {
    if (_detailsEntry == null) {
      _showDetails(globalPosition);
      return;
    }
    _pointerPosition = globalPosition;
    _detailsEntry!.markNeedsBuild();
  }

  Widget _buildDetailsOverlay(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final popupWidth = math.min(
      widget.compact ? 320.0 : 390.0,
      screenSize.width - 16,
    );
    const pointerGap = 10.0;
    final showAbovePointer = !widget.isOpponent;
    final availableHeight = showAbovePointer
        ? _pointerPosition.dy - pointerGap - 8
        : screenSize.height - _pointerPosition.dy - pointerGap - 8;
    final maximumHeight = math.min(220.0, math.max(76.0, availableHeight));
    var left = _pointerPosition.dx - popupWidth / 2;
    left = left.clamp(8.0, math.max(8.0, screenSize.width - popupWidth - 8));

    return Positioned(
      left: left,
      top: showAbovePointer ? null : _pointerPosition.dy + pointerGap,
      bottom: showAbovePointer
          ? screenSize.height - _pointerPosition.dy + pointerGap
          : null,
      width: popupWidth,
      child: IgnorePointer(
        ignoring: !_detailsPinned,
        child: AbsorbPointer(
          child: Material(
            key: ValueKey(
              '${widget.isOpponent ? 'opponent' : 'player'}-move-details-'
              '${widget.gesture.name}',
            ),
            elevation: 18,
            shadowColor: Colors.black,
            color: AppColors.bone,
            borderRadius: BorderRadius.circular(widget.compact ? 9 : 12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maximumHeight),
              child: SingleChildScrollView(
                child: ChampionMoveDetails(move: widget.move, compact: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeDetails() {
    _detailsEntry?.remove();
    _detailsEntry?.dispose();
    _detailsEntry = null;
  }

  Color _colorFor(BattleGesture gesture) => switch (gesture) {
    BattleGesture.rock => AppColors.rock,
    BattleGesture.paper => AppColors.paper,
    BattleGesture.scissors => AppColors.scissors,
  };

  String _labelFor(BattleGesture gesture) => switch (gesture) {
    BattleGesture.rock => 'Rock',
    BattleGesture.paper => 'Paper',
    BattleGesture.scissors => 'Scissors',
  };
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/input/number_focus_shortcuts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/demo_battle_factory.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
import '../../domain/entities/battle_status.dart';
import '../../domain/entities/combatant.dart';
import '../../domain/services/ai_move_strategy.dart';
import '../../domain/services/battle_rules.dart';
import '../controllers/battle_controller.dart';
import '../widgets/battle_backdrop.dart';
import '../widgets/battle_controls.dart';
import '../widgets/champion_card.dart';
import '../widgets/gesture_wheel.dart';
import '../widgets/health_bar.dart';

class BattleRoomPage extends StatefulWidget {
  const BattleRoomPage({super.key});

  @override
  State<BattleRoomPage> createState() => _BattleRoomPageState();
}

class _BattleRoomPageState extends State<BattleRoomPage> {
  late final BattleController _controller;
  final _battleActionFocusNodes = List.generate(
    4,
    (index) => FocusNode(debugLabel: 'Battle action ${index + 1}'),
  );
  final _moveFocusNodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'Battle move ${index + 1}'),
  );
  final _swapFocusNodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'Battle swap ${index + 1}'),
  );
  final _showdownFocusNode = FocusNode(debugLabel: 'Showdown');
  final _gameOverMenuFocusNode = FocusNode(debugLabel: 'Game over menu');
  final _rematchFocusNode = FocusNode(debugLabel: 'Rematch');

  @override
  void initState() {
    super.initState();
    _controller = BattleController(
      playerTeam: DemoBattleFactory.playerTeam(),
      opponentTeam: DemoBattleFactory.opponentTeam(),
      rules: const StandardBattleRules(),
      opponentStrategy: FossilRaceAiStrategy(),
    );
  }

  void _startFight() {
    _controller.startFight();
    _requestFocusAfterFrame(_moveFocusNodes.first);
  }

  Future<void> _showdown() async {
    await _controller.showdown();
    if (!mounted) return;

    _requestFocusAfterFrame(
      _controller.phase == BattlePhase.gameOver
          ? _rematchFocusNode
          : _battleActionFocusNodes.first,
    );
  }

  void _resetBattle() {
    _controller.resetBattle();
    _requestFocusAfterFrame(_battleActionFocusNodes.first);
  }

  void _startSwap() {
    _controller.startSwap();
    _requestFocusAfterFrame(_swapFocusNodes.first);
  }

  void _cancelSwap() {
    _controller.cancelSwap();
    _requestFocusAfterFrame(_battleActionFocusNodes.first);
  }

  Future<void> _swapPlayerTo(int index) async {
    await _controller.swapPlayerTo(index);
    if (!mounted) return;

    _requestFocusAfterFrame(
      _controller.phase == BattlePhase.gameOver
          ? _rematchFocusNode
          : _battleActionFocusNodes.first,
    );
  }

  void _requestFocusAfterFrame(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  List<FocusNode?> get _numberedFocusNodes => switch (_controller.phase) {
    BattlePhase.command => _battleActionFocusNodes,
    BattlePhase.choosingMove => [
      ..._moveFocusNodes,
      if (_controller.canShowdown) _showdownFocusNode else null,
    ],
    BattlePhase.resolving => const [],
    BattlePhase.swapping => _swapFocusNodes,
    BattlePhase.gameOver => [_gameOverMenuFocusNode, _rematchFocusNode],
  };

  @override
  void dispose() {
    _controller.dispose();
    for (final focusNode in [
      ..._battleActionFocusNodes,
      ..._moveFocusNodes,
      ..._swapFocusNodes,
      _showdownFocusNode,
      _gameOverMenuFocusNode,
      _rematchFocusNode,
    ]) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Shortcuts(
          shortcuts: numberFocusShortcuts(_numberedFocusNodes),
          child: Focus(
            autofocus: true,
            skipTraversal: true,
            child: FocusTraversalGroup(
              child: Scaffold(
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxHeight < 560 ||
                          constraints.maxWidth < 900;
                      return _BattleRoom(
                        controller: _controller,
                        compact: compact,
                        battleActionFocusNodes: _battleActionFocusNodes,
                        moveFocusNodes: _moveFocusNodes,
                        swapFocusNodes: _swapFocusNodes,
                        showdownFocusNode: _showdownFocusNode,
                        gameOverMenuFocusNode: _gameOverMenuFocusNode,
                        rematchFocusNode: _rematchFocusNode,
                        onFight: _startFight,
                        onSwap: _startSwap,
                        onCancelSwap: _cancelSwap,
                        onSelectSwapTarget: _swapPlayerTo,
                        onShowdown: _showdown,
                        onRematch: _resetBattle,
                        onExit: () => Navigator.of(context).pop(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BattleRoom extends StatelessWidget {
  const _BattleRoom({
    required this.controller,
    required this.compact,
    required this.battleActionFocusNodes,
    required this.moveFocusNodes,
    required this.swapFocusNodes,
    required this.showdownFocusNode,
    required this.gameOverMenuFocusNode,
    required this.rematchFocusNode,
    required this.onFight,
    required this.onSwap,
    required this.onCancelSwap,
    required this.onSelectSwapTarget,
    required this.onShowdown,
    required this.onRematch,
    required this.onExit,
  });

  final BattleController controller;
  final bool compact;
  final List<FocusNode> battleActionFocusNodes;
  final List<FocusNode> moveFocusNodes;
  final List<FocusNode> swapFocusNodes;
  final FocusNode showdownFocusNode;
  final FocusNode gameOverMenuFocusNode;
  final FocusNode rematchFocusNode;
  final VoidCallback onFight;
  final VoidCallback onSwap;
  final VoidCallback onCancelSwap;
  final ValueChanged<int> onSelectSwapTarget;
  final VoidCallback onShowdown;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final overlayVisible = controller.isFightOverlayVisible;

    return Stack(
      fit: StackFit.expand,
      children: [
        const BattleBackdrop(),
        Column(
          children: [
            Expanded(
              child: _ChampionZone(
                combatant: controller.opponent,
                reserveCardCount: controller.opponentTeam.swapIndexes.length,
                isOpponent: true,
                compact: compact,
                showChampion: !overlayVisible,
                fightEnabled: false,
                swapEnabled: false,
                onFight: () {},
                onSwap: () {},
              ),
            ),
            Container(
              height: compact ? 2 : 3,
              decoration: BoxDecoration(
                color: AppColors.bone,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.48),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ChampionZone(
                combatant: controller.player,
                reserveCardCount: controller.playerSwapIndexes.length,
                isOpponent: false,
                compact: compact,
                showChampion: !overlayVisible,
                fightEnabled: controller.phase == BattlePhase.command,
                swapEnabled: controller.canSwap,
                battleActionFocusNodes: battleActionFocusNodes,
                canFocusBattleActions: controller.phase == BattlePhase.command,
                onFight: onFight,
                onSwap: onSwap,
              ),
            ),
          ],
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: overlayVisible ? 1 : 0,
            duration: const Duration(milliseconds: 460),
            curve: Curves.easeInOut,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE6140F0C),
                    Color(0xF20A0807),
                    Color(0xE6140F0C),
                  ],
                ),
              ),
            ),
          ),
        ),
        _MoveSelectionLayer(
          controller: controller,
          compact: compact,
          moveFocusNodes: moveFocusNodes,
          showdownFocusNode: showdownFocusNode,
          onShowdown: onShowdown,
        ),
        _SwapSelectionLayer(
          controller: controller,
          compact: compact,
          focusNodes: swapFocusNodes,
          onCancel: onCancelSwap,
          onSelected: onSelectSwapTarget,
        ),
        if (controller.lastResolution != null)
          _ResultBanner(
            resolution: controller.lastResolution!,
            compact: compact,
          ),
        if (controller.phase == BattlePhase.gameOver)
          _GameOverPanel(
            player: controller.player,
            opponent: controller.opponent,
            menuFocusNode: gameOverMenuFocusNode,
            rematchFocusNode: rematchFocusNode,
            onRematch: onRematch,
            onExit: onExit,
          ),
        Positioned(
          left: compact ? 10 : 18,
          top: compact ? 8 : 14,
          child: IconButton(
            onPressed: onExit,
            tooltip: 'Back to menu',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        Positioned(
          right: compact ? 12 : 22,
          top: compact ? 10 : 18,
          child: _ModeBadge(compact: compact),
        ),
      ],
    );
  }
}

class _ChampionZone extends StatelessWidget {
  const _ChampionZone({
    required this.combatant,
    required this.reserveCardCount,
    required this.isOpponent,
    required this.compact,
    required this.showChampion,
    required this.fightEnabled,
    required this.swapEnabled,
    required this.onFight,
    required this.onSwap,
    this.battleActionFocusNodes,
    this.canFocusBattleActions = false,
  }) : assert(isOpponent || battleActionFocusNodes?.length == 4);

  final Combatant combatant;
  final int reserveCardCount;
  final bool isOpponent;
  final bool compact;
  final bool showChampion;
  final bool fightEnabled;
  final bool swapEnabled;
  final VoidCallback onFight;
  final VoidCallback onSwap;
  final List<FocusNode>? battleActionFocusNodes;
  final bool canFocusBattleActions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlsHeight = compact ? 48.0 : 64.0;
        final availableForCard =
            constraints.maxHeight -
            (isOpponent ? (compact ? 42 : 52) : controlsHeight + 30);
        final cardHeight = math
            .max(
              compact ? 68.0 : 100.0,
              math.min(compact ? 100.0 : 158.0, availableForCard),
            )
            .toDouble();
        final showReserves = constraints.maxWidth > 620;

        return Stack(
          children: [
            if (showReserves)
              Align(
                alignment: isOpponent
                    ? const Alignment(-0.78, -0.02)
                    : const Alignment(-0.78, 0.02),
                child: _ReserveStrip(
                  label: isOpponent ? 'RIVAL DECK' : 'SPECIES CARDS',
                  compact: compact,
                ),
              ),
            if (showReserves)
              Align(
                alignment: isOpponent
                    ? const Alignment(0.78, -0.02)
                    : const Alignment(0.78, 0.02),
                child: _ReserveStrip(
                  label: isOpponent ? 'DEFEATED' : 'RESERVE',
                  compact: compact,
                  cardCount: reserveCardCount,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                top: isOpponent ? (compact ? 6 : 10) : 0,
                bottom: isOpponent ? 0 : controlsHeight,
              ),
              child: Center(
                child: AnimatedOpacity(
                  opacity: showChampion ? 1 : 0,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: showChampion ? 1 : 0.38,
                    duration: const Duration(milliseconds: 430),
                    curve: Curves.easeInBack,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOpponent ? 'RIVAL CHAMPION' : 'YOUR CHAMPION',
                          style: TextStyle(
                            color: isOpponent
                                ? AppColors.danger
                                : AppColors.teal,
                            fontSize: compact ? 8 : 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        ChampionCard(
                          champion: combatant.champion,
                          height: cardHeight,
                          defeated: combatant.isDefeated,
                        ),
                        SizedBox(height: compact ? 3 : 6),
                        HealthBar(
                          current: combatant.currentHealth,
                          maximum: combatant.maxHealth,
                          width: cardHeight * 0.88,
                          compact: compact,
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        _StatusStrip(combatant: combatant, compact: compact),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isOpponent)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: compact ? 100 : 180,
                    right: compact ? 100 : 180,
                    bottom: compact ? 3 : 6,
                  ),
                  child: BattleControls(
                    onFight: onFight,
                    onSwap: onSwap,
                    fightEnabled: fightEnabled,
                    swapEnabled: swapEnabled,
                    compact: compact,
                    focusNodes: battleActionFocusNodes!,
                    canFocus: canFocusBattleActions,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReserveStrip extends StatelessWidget {
  const _ReserveStrip({
    required this.label,
    required this.compact,
    this.cardCount = 3,
  });

  final String label;
  final bool compact;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final cardSize = compact ? 37.0 : 53.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.sand.withValues(alpha: 0.64),
            fontSize: compact ? 7 : 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: compact ? 3 : 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            cardCount,
            (index) => Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
              child: MiniChampionCard(size: cardSize),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveSelectionLayer extends StatelessWidget {
  const _MoveSelectionLayer({
    required this.controller,
    required this.compact,
    required this.moveFocusNodes,
    required this.showdownFocusNode,
    required this.onShowdown,
  });

  final BattleController controller;
  final bool compact;
  final List<FocusNode> moveFocusNodes;
  final FocusNode showdownFocusNode;
  final VoidCallback onShowdown;

  @override
  Widget build(BuildContext context) {
    final visible = controller.isFightOverlayVisible;
    final selecting = controller.phase == BattlePhase.choosingMove;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: visible ? 1 : 0.82,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: GestureWheel(
                        champion: controller.opponent.champion,
                        selected: null,
                        enabled: false,
                        compact: compact,
                        label: 'Rival move wheel',
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  Expanded(
                    child: Center(
                      child: GestureWheel(
                        champion: controller.player.champion,
                        selected: controller.playerGesture,
                        onSelected: controller.selectPlayerGesture,
                        enabled: selecting,
                        compact: compact,
                        label: 'Choose your move',
                        focusNodes: moveFocusNodes,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: compact ? 10 : 42,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 230),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: controller.canShowdown
                        ? FilledButton.icon(
                            key: const ValueKey('showdown'),
                            focusNode: showdownFocusNode,
                            onPressed: onShowdown,
                            icon: const Icon(Icons.bolt_rounded),
                            label: const Text('4  SHOWDOWN'),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 12 : 22,
                                vertical: compact ? 12 : 17,
                              ),
                              textStyle: TextStyle(
                                fontSize: compact ? 9 : 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: compact ? 0.5 : 1,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapSelectionLayer extends StatelessWidget {
  const _SwapSelectionLayer({
    required this.controller,
    required this.compact,
    required this.focusNodes,
    required this.onCancel,
    required this.onSelected,
  }) : assert(focusNodes.length == 3);

  final BattleController controller;
  final bool compact;
  final List<FocusNode> focusNodes;
  final VoidCallback onCancel;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final visible = controller.isSwapOverlayVisible;
    final swapIndexes = controller.playerSwapIndexes;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.58),
          child: Center(
            child: Container(
              width: compact ? 430 : 560,
              margin: const EdgeInsets.all(20),
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 22,
                compact ? 14 : 20,
                compact ? 16 : 22,
                compact ? 16 : 22,
              ),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.teal, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.32),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SWAP CHAMPION',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: compact ? 12 : 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  Row(
                    children: [
                      for (var index = 0; index < swapIndexes.length; index++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 8,
                              right: index == swapIndexes.length - 1 ? 0 : 8,
                            ),
                            child: _SwapTargetButton(
                              combatant: controller
                                  .playerTeam
                                  .combatants[swapIndexes[index]],
                              shortcutNumber: index + 1,
                              compact: compact,
                              focusNode: focusNodes[index],
                              onPressed: () => onSelected(swapIndexes[index]),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  TextButton.icon(
                    focusNode: focusNodes[2],
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('3  CANCEL'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwapTargetButton extends StatelessWidget {
  const _SwapTargetButton({
    required this.combatant,
    required this.shortcutNumber,
    required this.compact,
    required this.focusNode,
    required this.onPressed,
  });

  final Combatant combatant;
  final int shortcutNumber;
  final bool compact;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$shortcutNumber, swap to ${combatant.champion.name}',
      child: Material(
        color: AppColors.ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          focusNode: focusNode,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$shortcutNumber',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                ChampionCard(
                  champion: combatant.champion,
                  height: compact ? 86 : 116,
                  defeated: combatant.isDefeated,
                ),
                SizedBox(height: compact ? 7 : 10),
                HealthBar(
                  current: combatant.currentHealth,
                  maximum: combatant.maxHealth,
                  width: compact ? 92 : 124,
                  compact: true,
                ),
                SizedBox(height: compact ? 5 : 7),
                _StatusStrip(combatant: combatant, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.combatant, required this.compact});

  final Combatant combatant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (combatant.statuses.isEmpty) {
      return SizedBox(height: compact ? 10 : 14);
    }

    return SizedBox(
      height: compact ? 12 : 16,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: compact ? 3 : 5,
        runSpacing: 2,
        children: [
          for (final status in combatant.statuses)
            Tooltip(
              message: status.type.label,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status.type).withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _statusColor(status.type)),
                ),
                child: Text(
                  status.stacks > 1
                      ? '${status.type.shortLabel}x${status.stacks}'
                      : status.type.shortLabel,
                  style: TextStyle(
                    color: AppColors.bone,
                    fontSize: compact ? 6.5 : 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(StatusType type) => switch (type) {
    StatusType.intimidation => AppColors.amber,
    StatusType.bleeding => AppColors.danger,
    StatusType.brokenBone => const Color(0xFFECE0CC),
    StatusType.alphaMomentum => AppColors.teal,
    StatusType.protectiveScales => const Color(0xFF82B0FF),
    StatusType.famine => const Color(0xFFA36B34),
    StatusType.jaggedScales => const Color(0xFFC7D16B),
  };
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.resolution, required this.compact});

  final BattleResolution resolution;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, color, detail) = switch (resolution.outcome) {
      BattleOutcome.playerVictory => (
        'DIRECT HIT',
        AppColors.teal,
        _effectDetail(
          damage: resolution.damageToOpponent,
          healing: resolution.healingToPlayer,
          reserveDamage: resolution.reserveDamageToOpponent,
          swapped: resolution.playerSwapped,
        ),
      ),
      BattleOutcome.opponentVictory => (
        'RIVAL STRIKES',
        AppColors.danger,
        _effectDetail(
          damage: resolution.damageToPlayer,
          healing: resolution.healingToOpponent,
          reserveDamage: resolution.reserveDamageToPlayer,
          swapped: resolution.opponentSwapped,
        ),
      ),
      BattleOutcome.draw => (
        'DRAW',
        AppColors.amber,
        '${_formatAmount(resolution.damageToPlayer)} / '
            '${_formatAmount(resolution.damageToOpponent)} DAMAGE',
      ),
    };

    return IgnorePointer(
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 28,
            vertical: compact ? 7 : 11,
          ),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color, blurRadius: 24)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11 : 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                detail,
                style: TextStyle(
                  color: AppColors.bone,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 9 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _effectDetail({
    required double damage,
    required double healing,
    required double reserveDamage,
    required bool swapped,
  }) {
    final parts = <String>[];
    if (damage > 0) parts.add('${_formatAmount(damage)} DAMAGE');
    if (reserveDamage > 0) parts.add('${_formatAmount(reserveDamage)} RESERVE');
    if (healing > 0) parts.add('${_formatAmount(healing)} HEAL');
    if (swapped) parts.add('SWAP');
    return parts.isEmpty ? 'NO DAMAGE' : parts.join(' · ');
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.player,
    required this.opponent,
    required this.menuFocusNode,
    required this.rematchFocusNode,
    required this.onRematch,
    required this.onExit,
  });

  final Combatant player;
  final Combatant opponent;
  final FocusNode menuFocusNode;
  final FocusNode rematchFocusNode;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final bothDefeated = player.isDefeated && opponent.isDefeated;
    final playerWon = opponent.isDefeated && !player.isDefeated;
    final title = bothDefeated
        ? 'DOUBLE K.O.'
        : playerWon
        ? 'EXPEDITION WON'
        : 'CHAMPION DEFEATED';
    final color = bothDefeated
        ? AppColors.amber
        : playerWon
        ? AppColors.teal
        : AppColors.danger;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.64),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 25),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                playerWon
                    ? Icons.emoji_events_rounded
                    : Icons.crisis_alert_rounded,
                color: color,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The Fossil Race demo is ready for another match.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.sand),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    key: const ValueKey('game-over-menu'),
                    focusNode: menuFocusNode,
                    onPressed: onExit,
                    child: const Text('1  MENU'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const ValueKey('game-over-rematch'),
                    focusNode: rematchFocusNode,
                    onPressed: onRematch,
                    child: const Text('2  REMATCH'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.sand.withValues(alpha: 0.42)),
      ),
      child: Text(
        'FOSSIL RACE · ROUND 1',
        style: TextStyle(
          color: AppColors.sand,
          fontSize: compact ? 7 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

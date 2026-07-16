import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/input/number_focus_shortcuts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/demo_battle_factory.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
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
  final _showdownFocusNode = FocusNode(debugLabel: 'Showdown');
  final _gameOverMenuFocusNode = FocusNode(debugLabel: 'Game over menu');
  final _rematchFocusNode = FocusNode(debugLabel: 'Rematch');

  @override
  void initState() {
    super.initState();
    _controller = BattleController(
      player: DemoBattleFactory.player(),
      opponent: DemoBattleFactory.opponent(),
      rules: const StandardBattleRules(),
      opponentStrategy: const AlwaysRockAiStrategy(),
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
    BattlePhase.gameOver => [_gameOverMenuFocusNode, _rematchFocusNode],
  };

  @override
  void dispose() {
    _controller.dispose();
    for (final focusNode in [
      ..._battleActionFocusNodes,
      ..._moveFocusNodes,
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
                        showdownFocusNode: _showdownFocusNode,
                        gameOverMenuFocusNode: _gameOverMenuFocusNode,
                        rematchFocusNode: _rematchFocusNode,
                        onFight: _startFight,
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
    required this.showdownFocusNode,
    required this.gameOverMenuFocusNode,
    required this.rematchFocusNode,
    required this.onFight,
    required this.onShowdown,
    required this.onRematch,
    required this.onExit,
  });

  final BattleController controller;
  final bool compact;
  final List<FocusNode> battleActionFocusNodes;
  final List<FocusNode> moveFocusNodes;
  final FocusNode showdownFocusNode;
  final FocusNode gameOverMenuFocusNode;
  final FocusNode rematchFocusNode;
  final VoidCallback onFight;
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
                isOpponent: true,
                compact: compact,
                showChampion: !overlayVisible,
                fightEnabled: false,
                onFight: () {},
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
                isOpponent: false,
                compact: compact,
                showChampion: !overlayVisible,
                fightEnabled: controller.phase == BattlePhase.command,
                battleActionFocusNodes: battleActionFocusNodes,
                canFocusBattleActions: controller.phase == BattlePhase.command,
                onFight: onFight,
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
    required this.isOpponent,
    required this.compact,
    required this.showChampion,
    required this.fightEnabled,
    required this.onFight,
    this.battleActionFocusNodes,
    this.canFocusBattleActions = false,
  }) : assert(isOpponent || battleActionFocusNodes?.length == 4);

  final Combatant combatant;
  final bool isOpponent;
  final bool compact;
  final bool showChampion;
  final bool fightEnabled;
  final VoidCallback onFight;
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
                  cardCount: isOpponent ? 2 : 3,
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
                          maximum: combatant.champion.maxHealth,
                          width: cardHeight * 0.88,
                          compact: compact,
                        ),
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
                    fightEnabled: fightEnabled,
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
                        selected: controller.opponentGesture,
                        onSelected: (_) {},
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
        '${resolution.damageToOpponent} DAMAGE',
      ),
      BattleOutcome.opponentVictory => (
        'RIVAL STRIKES',
        AppColors.danger,
        '${resolution.damageToPlayer} DAMAGE',
      ),
      BattleOutcome.draw => (
        'DRAW',
        AppColors.amber,
        '${resolution.damageToPlayer} / ${resolution.damageToOpponent} DAMAGE',
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

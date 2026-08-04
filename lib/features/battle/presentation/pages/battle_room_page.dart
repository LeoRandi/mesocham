import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/input/number_focus_shortcuts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../champions/domain/entities/champion_move.dart';
import '../../../champions/domain/repositories/champion_catalog.dart';
import '../../../champions/presentation/widgets/champion_card.dart';
import '../../../champions/presentation/widgets/champion_type_emblem.dart';
import '../../../companions/presentation/companion_assets.dart';
import '../../../companions/presentation/widgets/companion_orb.dart';
import '../../../decks/domain/entities/player_deck.dart';
import '../../../home/data/player_preferences.dart';
import '../../../species_cards/domain/entities/species_card.dart';
import '../../../species_cards/presentation/species_card_assets.dart';
import '../../../species_cards/presentation/widgets/species_card_widgets.dart';
import '../../application/services/battle_session.dart';
import '../../application/services/fossil_race_team_factory.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
import '../../domain/entities/battle_species_card_slot.dart';
import '../../domain/entities/battle_status.dart';
import '../../domain/entities/battle_team.dart';
import '../../domain/entities/combatant.dart';
import '../../domain/services/ai_move_strategy.dart';
import '../../domain/services/battle_rules.dart';
import '../../domain/services/companion_randomizer.dart';
import '../controllers/battle_controller.dart';
import '../widgets/battle_backdrop.dart';
import '../widgets/battle_controls.dart';
import '../widgets/gesture_wheel.dart';

enum _BattleLayoutFlow { normal, fight, swap, speciesCards }

class BattleRoomPage extends StatefulWidget {
  const BattleRoomPage({
    super.key,
    required this.catalog,
    required this.playerPreferences,
    this.playerDeck,
  });

  final ChampionCatalog catalog;
  final PlayerPreferences playerPreferences;
  final PlayerDeck? playerDeck;

  @override
  State<BattleRoomPage> createState() => _BattleRoomPageState();
}

class _BattleRoomPageState extends State<BattleRoomPage> {
  static const _preResolutionDelay = Duration(milliseconds: 420);
  static const _resultDisplayDuration = Duration(milliseconds: 1250);
  // These transitions communicate where the action palette and its menus go,
  // so keep them long enough to read as motion instead of a layout jump.
  static const _flowAnimationDuration = Duration(milliseconds: 520);

  BattleController? _controller;
  Object? _loadError;
  _BattleLayoutFlow _presentedFlow = _BattleLayoutFlow.normal;
  bool _flowTransitioning = false;
  final _battleActionFocusNodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'Battle action ${index + 1}'),
  );
  final _moveFocusNodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'Battle move ${index + 1}'),
  );
  final _mixedMoveOptionFocusNodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'Mixed move option ${index + 1}'),
  );
  final _swapFocusNodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'Battle swap ${index + 1}'),
  );
  final _speciesCardFocusNodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'Species card ${index + 1}'),
  );
  final _speciesCardCancelFocusNode = FocusNode(
    debugLabel: 'Cancel species cards',
  );
  final _showdownFocusNode = FocusNode(debugLabel: 'Showdown');
  final _gameOverMenuFocusNode = FocusNode(debugLabel: 'Game over menu');
  final _rematchFocusNode = FocusNode(debugLabel: 'Rematch');
  final _gestureDetailsController = GestureDetailsController();

  @override
  void initState() {
    super.initState();
    _loadBattle();
  }

  Future<void> _loadBattle() async {
    try {
      final collection = await widget.playerPreferences
          .getChampionCollectionCounts();
      final playerName =
          await widget.playerPreferences.getPlayerName() ?? 'Jugador';
      final teams = FossilRaceTeamFactory(
        catalog: widget.catalog,
      ).create(collection, playerChampionIds: widget.playerDeck?.championIds);
      if (!mounted) return;

      setState(() {
        final companionRandomizer = CompanionRandomizer();
        _loadError = null;
        _controller = BattleController(
          playerTeam: teams.playerTeam,
          opponentTeam: teams.opponentTeam,
          playerName: playerName,
          opponentName: 'John(CPU)',
          session: BattleSession(
            rules: StandardBattleRules(
              companionRandomizer: companionRandomizer,
            ),
            opponentStrategy: FossilRaceAiStrategy(),
            companionRandomizer: companionRandomizer,
          ),
        );
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Future<void> _startFight() async {
    if (_flowTransitioning || _presentedFlow == _BattleLayoutFlow.fight) return;
    if (_presentedFlow != _BattleLayoutFlow.normal) {
      _hideFlowThenStartFight();
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    controller.startFight();
    if (!controller.isFightOverlayVisible) return;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.fight;
    });
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);
    _requestFocusAfterFrame(_moveFocusNodes.first);
  }

  void _selectSpeciesCard(int index) {
    _controller?.selectPlayerSpeciesCard(index);
  }

  Future<void> _startSpeciesCards() async {
    if (_presentedFlow == _BattleLayoutFlow.swap ||
        _presentedFlow == _BattleLayoutFlow.fight) {
      _switchFlow(_BattleLayoutFlow.speciesCards);
      return;
    }
    if (_flowTransitioning ||
        _presentedFlow == _BattleLayoutFlow.speciesCards) {
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    controller.startSpeciesCardSelection();
    if (!controller.isSpeciesCardOverlayVisible) return;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.speciesCards;
    });
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);
    _focusFirstAvailableSpeciesCard(controller);
  }

  void _focusFirstAvailableSpeciesCard(BattleController controller) {
    var focusedAvailableCard = false;
    for (
      var index = 0;
      index < controller.playerTeam.speciesCardSlots.length;
      index++
    ) {
      if (controller.state.canSelectPlayerSpeciesCard(index)) {
        _requestFocusAfterFrame(_speciesCardFocusNodes[index]);
        focusedAvailableCard = true;
        break;
      }
    }
    if (!focusedAvailableCard && controller.isSpeciesCardOverlayVisible) {
      _requestFocusAfterFrame(_speciesCardCancelFocusNode);
    }
  }

  Future<void> _cancelSpeciesCards() async {
    if (_flowTransitioning) return;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.normal;
    });
    _controller?.cancelSpeciesCardSelection();
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);
    _requestFocusAfterFrame(_battleActionFocusNodes.first);
  }

  Future<void> _showdown() async {
    final controller = _controller;
    if (controller == null || !controller.beginShowdown()) return;

    await Future<void>.delayed(_preResolutionDelay);
    if (!mounted) return;
    if (!controller.resolvePendingAction()) return;

    await Future<void>.delayed(_resultDisplayDuration);
    if (!mounted) return;
    if (!controller.completeResolution()) return;

    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.normal;
    });
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);

    _requestFocusAfterFrame(
      controller.phase == BattlePhase.gameOver
          ? _rematchFocusNode
          : _battleActionFocusNodes.first,
    );
  }

  void _resetBattle() {
    _controller?.resetBattle();
    setState(() {
      _presentedFlow = _BattleLayoutFlow.normal;
      _flowTransitioning = false;
    });
    _requestFocusAfterFrame(_battleActionFocusNodes.first);
  }

  Future<void> _startSwap() async {
    if (_presentedFlow == _BattleLayoutFlow.speciesCards ||
        _presentedFlow == _BattleLayoutFlow.fight) {
      _switchFlow(_BattleLayoutFlow.swap);
      return;
    }
    if (_flowTransitioning || _presentedFlow == _BattleLayoutFlow.swap) return;
    final controller = _controller;
    if (controller == null) return;
    controller.startSwap();
    if (!controller.isSwapOverlayVisible) return;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.swap;
    });
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);
    _requestFocusAfterFrame(_swapFocusNodes.first);
  }

  Future<void> _cancelSwap() async {
    if (_flowTransitioning) return;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.normal;
    });
    _controller?.cancelSwap();
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);
    _requestFocusAfterFrame(_battleActionFocusNodes.first);
  }

  Future<void> _switchFlow(_BattleLayoutFlow nextFlow) async {
    if (_flowTransitioning || _presentedFlow == nextFlow) return;
    final controller = _controller;
    if (controller == null) return;
    final previousFlow = _presentedFlow;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.normal;
    });
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;

    switch (previousFlow) {
      case _BattleLayoutFlow.fight:
        controller.cancelFight();
      case _BattleLayoutFlow.swap:
        controller.cancelSwap();
      case _BattleLayoutFlow.speciesCards:
        controller.cancelSpeciesCardSelection();
      case _BattleLayoutFlow.normal:
        break;
    }
    if (nextFlow == _BattleLayoutFlow.swap) {
      controller.startSwap();
    } else {
      controller.startSpeciesCardSelection();
    }
    setState(() => _presentedFlow = nextFlow);
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);
    if (nextFlow == _BattleLayoutFlow.swap) {
      _requestFocusAfterFrame(_swapFocusNodes.first);
    } else {
      _focusFirstAvailableSpeciesCard(controller);
    }
  }

  Future<void> _hideFlowThenStartFight() async {
    if (_flowTransitioning) return;
    final controller = _controller;
    if (controller == null) return;
    final previousFlow = _presentedFlow;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.normal;
    });
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    if (previousFlow == _BattleLayoutFlow.swap) {
      controller.cancelSwap();
    } else {
      controller.cancelSpeciesCardSelection();
    }
    controller.startFight();
    if (!controller.isFightOverlayVisible) {
      setState(() => _flowTransitioning = false);
      return;
    }
    setState(() => _presentedFlow = _BattleLayoutFlow.fight);
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted) return;
    setState(() => _flowTransitioning = false);
    _requestFocusAfterFrame(_moveFocusNodes.first);
  }

  Future<void> _swapPlayerTo(int index) async {
    final controller = _controller;
    if (controller == null || _flowTransitioning) return;
    setState(() {
      _flowTransitioning = true;
      _presentedFlow = _BattleLayoutFlow.normal;
    });
    await Future<void>.delayed(_flowAnimationDuration);
    if (!mounted || !controller.beginSwap(index)) {
      if (mounted) setState(() => _flowTransitioning = false);
      return;
    }
    setState(() => _flowTransitioning = false);

    await Future<void>.delayed(_preResolutionDelay);
    if (!mounted) return;
    if (!controller.resolvePendingAction()) return;

    await Future<void>.delayed(_resultDisplayDuration);
    if (!mounted) return;
    if (!controller.completeResolution()) return;

    _requestFocusAfterFrame(
      controller.phase == BattlePhase.gameOver
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

  List<FocusNode?> get _numberedFocusNodes => switch (_controller!.phase) {
    BattlePhase.command => _battleActionFocusNodes,
    BattlePhase.choosingMove =>
      _controller!.requiresPlayerMoveOption
          ? [
              ..._mixedMoveOptionFocusNodes,
              if (_controller!.canShowdown) _showdownFocusNode else null,
            ]
          : [
              ..._moveFocusNodes,
              if (_controller!.canShowdown) _showdownFocusNode else null,
            ],
    BattlePhase.resolving => const [],
    BattlePhase.swapping => _swapFocusNodes,
    BattlePhase.choosingSpeciesCard => [
      ..._speciesCardFocusNodes,
      _speciesCardCancelFocusNode,
    ],
    BattlePhase.gameOver => [_gameOverMenuFocusNode, _rematchFocusNode],
  };

  @override
  void dispose() {
    _controller?.dispose();
    for (final focusNode in [
      ..._battleActionFocusNodes,
      ..._moveFocusNodes,
      ..._mixedMoveOptionFocusNodes,
      ..._swapFocusNodes,
      ..._speciesCardFocusNodes,
      _speciesCardCancelFocusNode,
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
    final controller = _controller;
    if (controller == null) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const BattleBackdrop(),
            Center(
              child: _loadError == null
                  ? const CircularProgressIndicator(color: AppColors.amber)
                  : _BattleLoadError(
                      onRetry: () {
                        setState(() => _loadError = null);
                        _loadBattle();
                      },
                      onExit: () => Navigator.of(context).pop(),
                    ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Shortcuts(
          shortcuts: numberFocusShortcuts(_numberedFocusNodes),
          child: Focus(
            autofocus: true,
            skipTraversal: true,
            child: FocusTraversalGroup(
              child: Scaffold(
                body: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _gestureDetailsController.dismiss(),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact =
                            constraints.maxHeight < 560 ||
                            constraints.maxWidth < 900;
                        return _BattleRoom(
                          controller: controller,
                          compact: compact,
                          presentedFlow: _presentedFlow,
                          flowTransitioning: _flowTransitioning,
                          battleActionFocusNodes: _battleActionFocusNodes,
                          moveFocusNodes: _moveFocusNodes,
                          mixedMoveOptionFocusNodes: _mixedMoveOptionFocusNodes,
                          swapFocusNodes: _swapFocusNodes,
                          speciesCardFocusNodes: _speciesCardFocusNodes,
                          speciesCardCancelFocusNode:
                              _speciesCardCancelFocusNode,
                          showdownFocusNode: _showdownFocusNode,
                          gameOverMenuFocusNode: _gameOverMenuFocusNode,
                          rematchFocusNode: _rematchFocusNode,
                          gestureDetailsController: _gestureDetailsController,
                          onFight: _startFight,
                          onSpeciesCards: _startSpeciesCards,
                          onSelectSpeciesCard: _selectSpeciesCard,
                          onCancelSpeciesCards: _cancelSpeciesCards,
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
          ),
        );
      },
    );
  }
}

class _BattleLoadError extends StatelessWidget {
  const _BattleLoadError({required this.onRetry, required this.onExit});

  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.deepEarth,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not assemble a Fossil Race team.',
              style: TextStyle(
                color: AppColors.bone,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(onPressed: onExit, child: const Text('MENU')),
                FilledButton(onPressed: onRetry, child: const Text('RETRY')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleRoom extends StatelessWidget {
  const _BattleRoom({
    required this.controller,
    required this.compact,
    required this.presentedFlow,
    required this.flowTransitioning,
    required this.battleActionFocusNodes,
    required this.moveFocusNodes,
    required this.mixedMoveOptionFocusNodes,
    required this.swapFocusNodes,
    required this.speciesCardFocusNodes,
    required this.speciesCardCancelFocusNode,
    required this.showdownFocusNode,
    required this.gameOverMenuFocusNode,
    required this.rematchFocusNode,
    required this.gestureDetailsController,
    required this.onFight,
    required this.onSpeciesCards,
    required this.onSelectSpeciesCard,
    required this.onCancelSpeciesCards,
    required this.onSwap,
    required this.onCancelSwap,
    required this.onSelectSwapTarget,
    required this.onShowdown,
    required this.onRematch,
    required this.onExit,
  });

  final BattleController controller;
  final bool compact;
  final _BattleLayoutFlow presentedFlow;
  final bool flowTransitioning;
  final List<FocusNode> battleActionFocusNodes;
  final List<FocusNode> moveFocusNodes;
  final List<FocusNode> mixedMoveOptionFocusNodes;
  final List<FocusNode> swapFocusNodes;
  final List<FocusNode> speciesCardFocusNodes;
  final FocusNode speciesCardCancelFocusNode;
  final FocusNode showdownFocusNode;
  final FocusNode gameOverMenuFocusNode;
  final FocusNode rematchFocusNode;
  final GestureDetailsController gestureDetailsController;
  final VoidCallback onFight;
  final VoidCallback onSpeciesCards;
  final ValueChanged<int> onSelectSpeciesCard;
  final VoidCallback onCancelSpeciesCards;
  final VoidCallback onSwap;
  final VoidCallback onCancelSwap;
  final ValueChanged<int> onSelectSwapTarget;
  final VoidCallback onShowdown;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final overlayVisible =
        presentedFlow == _BattleLayoutFlow.fight &&
        controller.isFightOverlayVisible;
    final resolution = controller.lastResolution;
    final pendingSpeciesCardIndex = controller.pendingPlayerSpeciesCardIndex;
    SpeciesCard? pendingPlayerSpeciesCard;
    if (pendingSpeciesCardIndex != null &&
        pendingSpeciesCardIndex >= 0 &&
        pendingSpeciesCardIndex <
            controller.playerTeam.speciesCardSlots.length) {
      final pendingSlot =
          controller.playerTeam.speciesCardSlots[pendingSpeciesCardIndex];
      if (!pendingSlot.consumed && !pendingSlot.lost) {
        pendingPlayerSpeciesCard = pendingSlot.card;
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const BattleBackdrop(),
        LayoutBuilder(
          builder: (context, constraints) {
            final logWidth = math.max(120.0, constraints.maxWidth / 6);
            final groundSize = (constraints.maxHeight * 0.27)
                .clamp(86.0, 168.0)
                .toDouble();
            final wildCompanion = controller.wildCompanionStack.isEmpty
                ? null
                : controller.wildCompanionStack.first;
            final companionDiameter = groundSize * 0.48;
            return Stack(
              children: [
                Positioned(
                  left: 20 + logWidth + 8,
                  top: (constraints.maxHeight - groundSize) / 2,
                  width: groundSize,
                  height: groundSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Image.asset(
                            'assets/images/companion_ground.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      if (wildCompanion != null)
                        Positioned(
                          left: (groundSize - companionDiameter) / 2,
                          top: groundSize * 0.1,
                          child: CompanionOrb(
                            key: ValueKey(
                              'available-companion-${wildCompanion.name}',
                            ),
                            companion: wildCompanion,
                            diameter: companionDiameter,
                            wild: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        Column(
          children: [
            Expanded(
              child: _ChampionZone(
                team: controller.opponentTeam,
                isOpponent: true,
                showControls: false,
                compact: compact,
                resolutionSequence: controller.resolutionSequence,
                damagedIndexes: resolution?.damagedOpponentIndexes ?? const [],
                showChampion: true,
                fightEnabled: false,
                swapEnabled: false,
                speciesCardSelectionEnabled: false,
                onFight: () {},
                onSpeciesCards: () {},
                onSwap: () {},
              ),
            ),
            Expanded(
              child: _ChampionZone(
                team: controller.playerTeam,
                isOpponent: false,
                showControls: false,
                compact: compact,
                resolutionSequence: controller.resolutionSequence,
                damagedIndexes: resolution?.damagedPlayerIndexes ?? const [],
                showChampion: true,
                fightEnabled: controller.phase == BattlePhase.command,
                swapEnabled: controller.canSwap,
                speciesCardSelectionEnabled:
                    controller.phase == BattlePhase.command,
                pendingSpeciesCard: pendingPlayerSpeciesCard,
                battleActionFocusNodes: battleActionFocusNodes,
                canFocusBattleActions: controller.phase == BattlePhase.command,
                onFight: onFight,
                onSpeciesCards: onSpeciesCards,
                onSwap: onSwap,
              ),
            ),
          ],
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
        _CombatLogOverlay(entries: controller.combatLog),
        _FlowBackdrop(
          visible: overlayVisible,
          filterKey: const ValueKey('fight-background-filter'),
          dimOpacity: 0.5,
        ),
        _MoveSelectionLayer(
          controller: controller,
          visible: overlayVisible,
          compact: compact,
          moveFocusNodes: moveFocusNodes,
          mixedMoveOptionFocusNodes: mixedMoveOptionFocusNodes,
          showdownFocusNode: showdownFocusNode,
          gestureDetailsController: gestureDetailsController,
          onShowdown: onShowdown,
        ),
        _FlowBackdrop(
          visible:
              presentedFlow == _BattleLayoutFlow.swap ||
              presentedFlow == _BattleLayoutFlow.speciesCards ||
              (flowTransitioning &&
                  (controller.isSwapOverlayVisible ||
                      controller.isSpeciesCardOverlayVisible)),
          filterKey: const ValueKey('swap-background-filter'),
        ),
        _SwapSelectionLayer(
          controller: controller,
          compact: compact,
          visible: presentedFlow == _BattleLayoutFlow.swap,
          flowTransitioning: flowTransitioning,
          focusNodes: swapFocusNodes,
          onSelected: onSelectSwapTarget,
        ),
        _SpeciesCardSelectionLayer(
          controller: controller,
          compact: compact,
          visible: presentedFlow == _BattleLayoutFlow.speciesCards,
          flowTransitioning: flowTransitioning,
          focusNodes: speciesCardFocusNodes,
          onSelected: onSelectSpeciesCard,
        ),
        _BattleActionPaletteLayer(
          controller: controller,
          compact: compact,
          flow: presentedFlow,
          flowTransitioning: flowTransitioning,
          battleActionFocusNodes: battleActionFocusNodes,
          swapFocusNodes: swapFocusNodes,
          speciesCardCancelFocusNode: speciesCardCancelFocusNode,
          onFight: onFight,
          onSpeciesCards: onSpeciesCards,
          onCancelSpeciesCards: onCancelSpeciesCards,
          onSwap: onSwap,
          onCancelSwap: onCancelSwap,
        ),
      ],
    );
  }
}

class _CombatLogOverlay extends StatefulWidget {
  const _CombatLogOverlay({required this.entries});

  final List<String> entries;

  @override
  State<_CombatLogOverlay> createState() => _CombatLogOverlayState();
}

class _CombatLogOverlayState extends State<_CombatLogOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToLatest();
  }

  @override
  void didUpdateWidget(covariant _CombatLogOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length != oldWidget.entries.length) {
      _scrollToLatest();
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = math.min(
          math.max(120.0, constraints.maxWidth / 6),
          math.max(120.0, constraints.maxWidth - 40),
        );

        return Stack(
          children: [
            Positioned(
              left: 20,
              top: 20,
              bottom: 20,
              width: panelWidth,
              child: _CombatLogPanel(
                entries: widget.entries,
                scrollController: _scrollController,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CombatLogPanel extends StatelessWidget {
  const _CombatLogPanel({
    required this.entries,
    required this.scrollController,
  });

  final List<String> entries;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Registro de combate',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.94),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.82),
            width: 1.5,
          ),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.48),
              blurRadius: 18,
              offset: const Offset(5, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                color: AppColors.deepEarth.withValues(alpha: 0.96),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'REGISTRO DE COMBATE',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final separator = entry == '---';
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: separator ? 8 : 5,
                          top: separator && index > 0 ? 4 : 0,
                        ),
                        child: SelectableText(
                          entry,
                          style: TextStyle(
                            color: separator ? AppColors.amber : AppColors.bone,
                            fontSize: 7,
                            height: 1.3,
                            fontWeight: separator
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    },
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

class _ChampionZone extends StatelessWidget {
  const _ChampionZone({
    required this.team,
    required this.isOpponent,
    required this.showControls,
    required this.compact,
    required this.resolutionSequence,
    required this.damagedIndexes,
    required this.showChampion,
    required this.fightEnabled,
    required this.swapEnabled,
    required this.speciesCardSelectionEnabled,
    required this.onFight,
    required this.onSpeciesCards,
    required this.onSwap,
    this.battleActionFocusNodes,
    this.canFocusBattleActions = false,
    this.pendingSpeciesCard,
  }) : assert(isOpponent || battleActionFocusNodes?.length == 3);

  final BattleTeam team;
  final bool isOpponent;
  final bool showControls;
  final bool compact;
  final int resolutionSequence;
  final List<int> damagedIndexes;
  final bool showChampion;
  final bool fightEnabled;
  final bool swapEnabled;
  final bool speciesCardSelectionEnabled;
  final VoidCallback onFight;
  final VoidCallback onSpeciesCards;
  final VoidCallback onSwap;
  final List<FocusNode>? battleActionFocusNodes;
  final bool canFocusBattleActions;
  final SpeciesCard? pendingSpeciesCard;

  @override
  Widget build(BuildContext context) {
    final combatant = team.active;
    final activeDamageTrigger = damagedIndexes.contains(team.activeIndex)
        ? resolutionSequence
        : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = math.max(
          76.0,
          math.min(220.0, constraints.maxHeight - 58),
        );
        final reserveWidth = (constraints.maxWidth * 0.116)
            .clamp(96.0, 150.0)
            .toDouble();
        final controlsSide = math.min(
          170.0,
          math.max(
            90.0,
            math.min(constraints.maxHeight * 0.54, constraints.maxWidth * 0.18),
          ),
        );
        final speciesCardsEnabled =
            speciesCardSelectionEnabled && !team.active.isDefeated;
        final activeCardWidth = cardHeight * ChampionCard.aspectRatio;
        final activeCardLeft = (constraints.maxWidth - activeCardWidth) / 2;
        final pendingGap = compact ? 10.0 : 14.0;
        final combatLogRight =
            20 + math.max(120.0, constraints.maxWidth / 6) + 8;
        final pendingAvailableWidth =
            activeCardLeft - pendingGap - combatLogRight;
        final pendingPanelWidth = math.min(
          reserveWidth,
          math.max(72.0, pendingAvailableWidth),
        );
        final pendingPanelHeight = math.min(
          constraints.maxHeight * 0.46,
          pendingPanelWidth * 0.78,
        );
        final pendingPanelLeft =
            activeCardLeft - pendingGap - pendingPanelWidth;

        return Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: showChampion ? 1 : 0,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: showChampion ? 1 : 0.38,
                    duration: const Duration(milliseconds: 430),
                    curve: Curves.easeInBack,
                    child: _ActiveChampionStack(
                      combatant: combatant,
                      cardHeight: cardHeight,
                      isOpponent: isOpponent,
                      damageTrigger: activeDamageTrigger,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: isOpponent ? 12 : 16,
              right: -2,
              bottom: isOpponent ? 16 : 12,
              width: reserveWidth,
              child: _ReserveCardGroup(
                team: team,
                compact: compact,
                accent: isOpponent ? AppColors.danger : AppColors.paper,
                resolutionSequence: resolutionSequence,
                damagedIndexes: damagedIndexes,
              ),
            ),
            if (!isOpponent && pendingAvailableWidth >= 72)
              Positioned(
                left: pendingPanelLeft,
                bottom: -2,
                width: pendingPanelWidth,
                height: pendingPanelHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  reverseDuration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final motion = Tween<Offset>(
                      begin: const Offset(0, 1.05),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: motion, child: child),
                    );
                  },
                  child: pendingSpeciesCard == null
                      ? const SizedBox.shrink(
                          key: ValueKey('no-pending-player-species-card'),
                        )
                      : _PendingSpeciesCardPanel(
                          key: ValueKey(
                            'pending-player-species-card-${pendingSpeciesCard!.name}',
                          ),
                          card: pendingSpeciesCard!,
                          compact: compact,
                        ),
                ),
              ),
            if (!isOpponent && showControls)
              Positioned(
                right: reserveWidth + 26,
                top: (constraints.maxHeight - controlsSide) / 2,
                width: controlsSide,
                height: controlsSide,
                child: BattleControls(
                  onFight: onFight,
                  onSpeciesCards: onSpeciesCards,
                  onSwap: onSwap,
                  fightEnabled: fightEnabled,
                  speciesCardsEnabled: speciesCardsEnabled,
                  swapEnabled: swapEnabled,
                  focusNodes: battleActionFocusNodes!,
                  canFocus: canFocusBattleActions,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActiveChampionStack extends StatelessWidget {
  const _ActiveChampionStack({
    required this.combatant,
    required this.cardHeight,
    required this.isOpponent,
    required this.damageTrigger,
  });

  final Combatant combatant;
  final double cardHeight;
  final bool isOpponent;
  final int damageTrigger;

  @override
  Widget build(BuildContext context) {
    final cardWidth = cardHeight * ChampionCard.aspectRatio;
    final sideExtent = cardHeight * 0.3;
    final companionDiameter = cardHeight * 0.25;
    final companionTop = cardHeight * 0.07;
    final availableCompanionHeight = cardHeight * 0.86 - companionDiameter;
    final companionStep = combatant.companions.length <= 1
        ? 0.0
        : math.min(
            companionDiameter * 0.72,
            availableCompanionHeight / (combatant.companions.length - 1),
          );
    final speciesCard = combatant.equippedSpeciesCard;
    final speciesWidth = cardHeight * 0.52;
    final speciesHeight = cardHeight * 0.34;

    return SizedBox(
      width: cardWidth + sideExtent * 2,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < combatant.companions.length; index++)
            Positioned(
              left: sideExtent - companionDiameter * 0.58,
              top: companionTop + companionStep * index,
              child: CompanionOrb(
                key: ValueKey(
                  '${isOpponent ? 'opponent' : 'player'}-companion-'
                  '$index-${combatant.companions[index].name}',
                ),
                companion: combatant.companions[index],
                diameter: companionDiameter,
              ),
            ),
          if (speciesCard != null)
            Positioned(
              left: sideExtent + cardWidth - speciesWidth * 0.32 - 12,
              top: cardHeight * 0.36 - speciesHeight / 2,
              child: _ActiveSpeciesCard(
                card: speciesCard,
                accent: isOpponent ? AppColors.danger : AppColors.paper,
                width: speciesWidth,
                height: speciesHeight,
              ),
            ),
          Positioned(
            left: sideExtent,
            child: ChampionCard(
              key: ValueKey(
                '${isOpponent ? 'opponent' : 'player'}-active-champion-card',
              ),
              champion: combatant.champion,
              height: cardHeight,
              currentHealth: combatant.currentHealth,
              maximumHealth: combatant.maxHealth,
              defeated: combatant.isDefeated,
              obscured: false,
              damageTrigger: damageTrigger,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSpeciesCardPanel extends StatelessWidget {
  const _PendingSpeciesCardPanel({
    super.key,
    required this.card,
    required this.compact,
  });

  final SpeciesCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tooltip = '${card.name}\n${card.effectDescription}';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        key: const ValueKey('pending-player-species-card-panel'),
        image: true,
        label: '$tooltip. Activada.',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(13),
              topRight: Radius.circular(13),
            ),
            border: Border.all(color: AppColors.paper, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 5 : 7,
              compact ? 5 : 7,
              compact ? 5 : 7,
              compact ? 4 : 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Activada',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.bone,
                    fontSize: compact ? 9 : 11,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      card.assetPath,
                      key: const ValueKey('pending-player-species-card-image'),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
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

class _ActiveSpeciesCard extends StatelessWidget {
  const _ActiveSpeciesCard({
    required this.card,
    required this.accent,
    required this.width,
    required this.height,
  });

  final SpeciesCard card;
  final Color accent;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tooltip = '${card.name}\n${card.effectDescription}';

    return Transform.rotate(
      angle: -math.pi / 2,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: Semantics(
          image: true,
          label: '$tooltip. Active.',
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.deepEarth,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      card.assetPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                Positioned(
                  left: width * 0.34,
                  bottom: -height * 0.13,
                  width: width * 0.32,
                  height: height * 0.28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      border: Border.all(color: AppColors.ink),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            'Active',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _ReserveCardGroup extends StatelessWidget {
  const _ReserveCardGroup({
    required this.compact,
    required this.accent,
    required this.team,
    this.resolutionSequence = 0,
    this.damagedIndexes = const [],
  });

  final bool compact;
  final Color accent;
  final BattleTeam team;
  final int resolutionSequence;
  final List<int> damagedIndexes;

  @override
  Widget build(BuildContext context) {
    final reserveIndexes = [
      for (var index = 0; index < team.combatants.length; index++)
        if (index != team.activeIndex) index,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1A130F0B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          bottomLeft: Radius.circular(15),
        ),
        border: Border.all(color: accent, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 5 : 7,
          compact ? 6 : 8,
          compact ? 5 : 7,
          compact ? 5 : 7,
        ),
        child: Column(
          children: [
            Text(
              'Reserve',
              style: TextStyle(
                color: AppColors.bone,
                fontSize: compact ? 12 : 15,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: compact ? 5 : 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gap = compact ? 6.0 : 9.0;
                  final cardHeight = math.min(
                    (constraints.maxHeight -
                            gap * math.max(0, reserveIndexes.length - 1)) /
                        math.max(1, reserveIndexes.length),
                    (constraints.maxWidth - 4) / 0.7,
                  );
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (
                        var position = 0;
                        position < reserveIndexes.length;
                        position++
                      ) ...[
                        SpeciesCardBearer(
                          bearerHeight: cardHeight,
                          card: team
                              .combatants[reserveIndexes[position]]
                              .equippedSpeciesCard,
                          effectActive: false,
                          mini: true,
                          child: MiniChampionCard.combatant(
                            key: ValueKey(
                              '${team.activeIndex}-'
                              '${reserveIndexes[position]}',
                            ),
                            size: cardHeight,
                            imageAssetPath:
                                team
                                    .combatants[reserveIndexes[position]]
                                    .champion
                                    .closeUpAssetPath ??
                                team
                                    .combatants[reserveIndexes[position]]
                                    .champion
                                    .imageAssetPath,
                            currentHealth: team
                                .combatants[reserveIndexes[position]]
                                .currentHealth,
                            maximumHealth: team
                                .combatants[reserveIndexes[position]]
                                .maxHealth,
                            defeated: team
                                .combatants[reserveIndexes[position]]
                                .isDefeated,
                            obscured: false,
                            damageTrigger:
                                damagedIndexes.contains(
                                  reserveIndexes[position],
                                )
                                ? resolutionSequence
                                : 0,
                          ),
                        ),
                        if (position != reserveIndexes.length - 1)
                          SizedBox(height: gap),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveSelectionLayer extends StatelessWidget {
  const _MoveSelectionLayer({
    required this.controller,
    required this.visible,
    required this.compact,
    required this.moveFocusNodes,
    required this.mixedMoveOptionFocusNodes,
    required this.showdownFocusNode,
    required this.gestureDetailsController,
    required this.onShowdown,
  });

  final BattleController controller;
  final bool visible;
  final bool compact;
  final List<FocusNode> moveFocusNodes;
  final List<FocusNode> mixedMoveOptionFocusNodes;
  final FocusNode showdownFocusNode;
  final GestureDetailsController gestureDetailsController;
  final VoidCallback onShowdown;

  @override
  Widget build(BuildContext context) {
    final selecting = controller.phase == BattlePhase.choosingMove;

    return ExcludeFocus(
      excluding: !visible,
      child: IgnorePointer(
        ignoring: !visible,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final halfHeight = constraints.maxHeight / 2;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: halfHeight,
                  child: _FlowPanelMotion(
                    key: const ValueKey('opponent-fight-wheel-motion'),
                    visible: visible,
                    hiddenOffset: const Offset(0, -1.12),
                    child: Center(
                      child: GestureWheel(
                        key: const ValueKey('opponent-fight-wheel'),
                        champion: controller.opponent.champion,
                        selected: null,
                        enabled: false,
                        compact: compact,
                        label: 'Rival move wheel',
                        isOpponent: true,
                        showDetails: visible,
                        detailsController: gestureDetailsController,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: halfHeight,
                  child: _FlowPanelMotion(
                    key: const ValueKey('player-fight-wheel-motion'),
                    visible: visible,
                    hiddenOffset: const Offset(0, 1.12),
                    child: Center(
                      child: GestureWheel(
                        key: const ValueKey('player-fight-wheel'),
                        champion: controller.player.champion,
                        selected: controller.playerGesture,
                        onSelected: controller.selectPlayerGesture,
                        enabled: selecting,
                        compact: compact,
                        label: 'Choose your move',
                        isOpponent: false,
                        showDetails: visible,
                        focusNodes: moveFocusNodes,
                        detailsController: gestureDetailsController,
                      ),
                    ),
                  ),
                ),
                if (selecting && controller.requiresPlayerMoveOption)
                  Positioned(
                    left: compact ? 8 : 28,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _MixedMoveOptionPanel(
                        compact: compact,
                        choiceType:
                            controller.selectedPlayerMove!.mixedMoveChoice,
                        selectedOption: controller.playerMoveOption,
                        focusNodes: mixedMoveOptionFocusNodes,
                        onSelected: controller.selectPlayerMoveOption,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: halfHeight - (compact ? 20 : 25),
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
                              label: const Text('SHOWDOWN'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: AppColors.teal,
                                side: BorderSide(
                                  color: AppColors.bone.withValues(alpha: 0.7),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 16 : 26,
                                  vertical: compact ? 11 : 15,
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
            );
          },
        ),
      ),
    );
  }
}

class _MixedMoveOptionPanel extends StatelessWidget {
  const _MixedMoveOptionPanel({
    required this.compact,
    required this.choiceType,
    required this.selectedOption,
    required this.focusNodes,
    required this.onSelected,
  }) : assert(focusNodes.length == 3);

  final bool compact;
  final MixedMoveChoice choiceType;
  final int? selectedOption;
  final List<FocusNode> focusNodes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final (title, labels) = switch (choiceType) {
      MixedMoveChoice.falseEvolution => (
        'EVOLUCIÓN FALSA',
        const ['CURA AL EQUIPO', 'DAÑO Y RELEVO', 'RELEVO RIVAL'],
      ),
      MixedMoveChoice.arborealVersatility => (
        'VERSATILIDAD ARBORÍCOLA',
        const ['40 DE DAÑO', 'CURA Y LIMPIEZA', 'DAÑO Y RELEVO'],
      ),
    };
    return Container(
      width: compact ? 126 : 178,
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.amber,
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: compact ? 5 : 8),
          for (var index = 0; index < labels.length; index++) ...[
            SizedBox(
              width: double.infinity,
              child: ChoiceChip(
                key: ValueKey('mixed-move-option-$index'),
                focusNode: focusNodes[index],
                label: Text(labels[index], textAlign: TextAlign.center),
                selected: selectedOption == index,
                onSelected: (_) => onSelected(index),
                labelStyle: TextStyle(
                  color: selectedOption == index
                      ? AppColors.ink
                      : AppColors.bone,
                  fontSize: compact ? 7 : 9,
                  fontWeight: FontWeight.w800,
                ),
                selectedColor: AppColors.amber,
                backgroundColor: AppColors.charcoal,
                side: BorderSide(
                  color: selectedOption == index
                      ? AppColors.amber
                      : AppColors.bone.withValues(alpha: 0.35),
                ),
                showCheckmark: false,
              ),
            ),
            if (index != labels.length - 1) SizedBox(height: compact ? 3 : 5),
          ],
        ],
      ),
    );
  }
}

class _BattleActionPaletteLayer extends StatelessWidget {
  const _BattleActionPaletteLayer({
    required this.controller,
    required this.compact,
    required this.flow,
    required this.flowTransitioning,
    required this.battleActionFocusNodes,
    required this.swapFocusNodes,
    required this.speciesCardCancelFocusNode,
    required this.onFight,
    required this.onSpeciesCards,
    required this.onCancelSpeciesCards,
    required this.onSwap,
    required this.onCancelSwap,
  });

  final BattleController controller;
  final bool compact;
  final _BattleLayoutFlow flow;
  final bool flowTransitioning;
  final List<FocusNode> battleActionFocusNodes;
  final List<FocusNode> swapFocusNodes;
  final FocusNode speciesCardCancelFocusNode;
  final VoidCallback onFight;
  final VoidCallback onSpeciesCards;
  final VoidCallback onCancelSpeciesCards;
  final VoidCallback onSwap;
  final VoidCallback onCancelSwap;

  @override
  Widget build(BuildContext context) {
    final actionPaletteVisible =
        controller.phase == BattlePhase.command ||
        controller.isFightOverlayVisible ||
        controller.phase == BattlePhase.swapping ||
        controller.phase == BattlePhase.choosingSpeciesCard;
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfHeight = constraints.maxHeight / 2;
        final normalReserveWidth = (constraints.maxWidth * 0.116)
            .clamp(96.0, 150.0)
            .toDouble();
        final playerPanelWidth = (constraints.maxWidth * 0.345)
            .clamp(238.0, 390.0)
            .toDouble();
        final menuRight = compact ? 42.0 : 58.0;
        final normalSide = math.min(
          170.0,
          math.max(
            90.0,
            math.min(halfHeight * 0.54, constraints.maxWidth * 0.18),
          ),
        );
        final swapSide = math.min(
          170.0,
          math.max(
            100.0,
            math.min(halfHeight * 0.62, constraints.maxWidth * 0.18),
          ),
        );
        final fightSide = math.min(
          170.0,
          math.max(
            100.0,
            math.min(halfHeight * 0.58, constraints.maxWidth * 0.18),
          ),
        );
        final speciesSide = math.min(
          170.0,
          math.max(
            100.0,
            math.min(constraints.maxHeight * 0.28, constraints.maxWidth * 0.17),
          ),
        );

        final (right, top, width, height) = switch (flow) {
          _BattleLayoutFlow.normal => (
            normalReserveWidth + 26,
            halfHeight + (halfHeight - normalSide) / 2,
            normalSide,
            normalSide,
          ),
          _BattleLayoutFlow.fight => (
            normalReserveWidth +
                26 +
                (normalSide -
                        fightSide * BattleControls.expandedFightWidthFactor) /
                    2,
            halfHeight +
                (halfHeight -
                        fightSide * BattleControls.expandedFightHeightFactor) /
                    2 -
                (compact ? 20 : 28),
            fightSide * BattleControls.expandedFightWidthFactor,
            fightSide * BattleControls.expandedFightHeightFactor,
          ),
          _BattleLayoutFlow.swap => (
            playerPanelWidth + (compact ? 20 : 26),
            halfHeight +
                (halfHeight -
                        swapSide * BattleControls.expandedSwapHeightFactor) /
                    2,
            swapSide * BattleControls.expandedSwapWidthFactor,
            swapSide * BattleControls.expandedSwapHeightFactor,
          ),
          _BattleLayoutFlow.speciesCards => (
            menuRight + (compact ? 86 : 112),
            (constraints.maxHeight -
                    speciesSide *
                        BattleControls.expandedSpeciesCardsHeightFactor) /
                2,
            speciesSide * BattleControls.expandedSpeciesCardsWidthFactor,
            speciesSide * BattleControls.expandedSpeciesCardsHeightFactor,
          ),
        };

        return Stack(
          fit: StackFit.expand,
          children: [
            _AnimatedPalettePlacement(
              key: const ValueKey('animated-battle-action-palette'),
              targetRect: Rect.fromLTWH(
                constraints.maxWidth - right - width,
                top,
                width,
                height,
              ),
              child: ExcludeFocus(
                excluding: flowTransitioning || !actionPaletteVisible,
                child: IgnorePointer(
                  ignoring: flowTransitioning || !actionPaletteVisible,
                  child: AnimatedOpacity(
                    opacity: actionPaletteVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: _AnimatedBattleControls(
                      controller: controller,
                      flow: flow,
                      battleActionFocusNodes: battleActionFocusNodes,
                      swapFocusNodes: swapFocusNodes,
                      speciesCardCancelFocusNode: speciesCardCancelFocusNode,
                      onFight: onFight,
                      onSpeciesCards: onSpeciesCards,
                      onCancelSpeciesCards: onCancelSpeciesCards,
                      onSwap: onSwap,
                      onCancelSwap: onCancelSwap,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedPalettePlacement extends StatefulWidget {
  const _AnimatedPalettePlacement({
    super.key,
    required this.targetRect,
    required this.child,
  });

  final Rect targetRect;
  final Widget child;

  @override
  State<_AnimatedPalettePlacement> createState() =>
      _AnimatedPalettePlacementState();
}

class _AnimatedPalettePlacementState extends State<_AnimatedPalettePlacement>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Rect _fromRect;
  late Rect _toRect;

  @override
  void initState() {
    super.initState();
    _fromRect = widget.targetRect;
    _toRect = widget.targetRect;
    _controller = AnimationController(
      vsync: this,
      duration: _BattleRoomPageState._flowAnimationDuration,
      animationBehavior: AnimationBehavior.preserve,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedPalettePlacement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetRect == widget.targetRect) return;
    _fromRect = _currentRect;
    _toRect = widget.targetRect;
    _controller.forward(from: 0);
  }

  Rect get _currentRect => Rect.lerp(
    _fromRect,
    _toRect,
    Curves.easeInOutCubic.transform(_controller.value),
  )!;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final rect = _currentRect;
        return Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class _AnimatedBattleControls extends StatefulWidget {
  const _AnimatedBattleControls({
    required this.controller,
    required this.flow,
    required this.battleActionFocusNodes,
    required this.swapFocusNodes,
    required this.speciesCardCancelFocusNode,
    required this.onFight,
    required this.onSpeciesCards,
    required this.onCancelSpeciesCards,
    required this.onSwap,
    required this.onCancelSwap,
  });

  final BattleController controller;
  final _BattleLayoutFlow flow;
  final List<FocusNode> battleActionFocusNodes;
  final List<FocusNode> swapFocusNodes;
  final FocusNode speciesCardCancelFocusNode;
  final VoidCallback onFight;
  final VoidCallback onSpeciesCards;
  final VoidCallback onCancelSpeciesCards;
  final VoidCallback onSwap;
  final VoidCallback onCancelSwap;

  @override
  State<_AnimatedBattleControls> createState() =>
      _AnimatedBattleControlsState();
}

class _AnimatedBattleControlsState extends State<_AnimatedBattleControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expansionController;
  _BattleLayoutFlow _expansionFlow = _BattleLayoutFlow.normal;

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      vsync: this,
      duration: _BattleRoomPageState._flowAnimationDuration,
      animationBehavior: AnimationBehavior.preserve,
    );
    if (widget.flow != _BattleLayoutFlow.normal) {
      _expansionFlow = widget.flow;
      _expansionController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedBattleControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow == widget.flow) return;
    if (widget.flow == _BattleLayoutFlow.normal) {
      _expansionController.reverse();
    } else {
      _expansionFlow = widget.flow;
      _expansionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapEnabled =
        widget.controller.playerSwapIndexes.isNotEmpty &&
        !widget.controller.player.hasStatus(StatusType.swapLocked);
    final focusNodes = switch (widget.flow) {
      _BattleLayoutFlow.normal => widget.battleActionFocusNodes,
      _BattleLayoutFlow.fight => <FocusNode?>[
        null,
        widget.battleActionFocusNodes[1],
        widget.battleActionFocusNodes[2],
      ],
      _BattleLayoutFlow.swap => <FocusNode?>[
        null,
        null,
        widget.swapFocusNodes[2],
      ],
      _BattleLayoutFlow.speciesCards => <FocusNode?>[
        null,
        widget.speciesCardCancelFocusNode,
        null,
      ],
    };
    final actionKeyPrefix = switch (widget.flow) {
      _BattleLayoutFlow.normal => 'battle-action',
      _BattleLayoutFlow.fight => 'fight-palette-action',
      _BattleLayoutFlow.swap => 'swap-palette-action',
      _BattleLayoutFlow.speciesCards => 'species-palette-action',
    };

    return AnimatedBuilder(
      animation: _expansionController,
      builder: (context, child) {
        return BattleControls(
          onFight: widget.onFight,
          onSpeciesCards: widget.flow == _BattleLayoutFlow.speciesCards
              ? widget.onCancelSpeciesCards
              : widget.onSpeciesCards,
          onSwap: widget.flow == _BattleLayoutFlow.swap
              ? widget.onCancelSwap
              : widget.onSwap,
          fightEnabled: widget.flow == _BattleLayoutFlow.fight
              ? false
              : widget.flow == _BattleLayoutFlow.normal
              ? widget.controller.phase == BattlePhase.command
              : true,
          speciesCardsEnabled: widget.flow == _BattleLayoutFlow.normal
              ? widget.controller.canOpenSpeciesCards
              : !widget.controller.player.isDefeated,
          swapEnabled: widget.flow == _BattleLayoutFlow.normal
              ? widget.controller.canSwap
              : widget.flow == _BattleLayoutFlow.swap || swapEnabled,
          focusNodes: focusNodes,
          canFocus: true,
          expandedFight: _expansionFlow == _BattleLayoutFlow.fight,
          expandedSwap: _expansionFlow == _BattleLayoutFlow.swap,
          expandedSpeciesCards:
              _expansionFlow == _BattleLayoutFlow.speciesCards,
          expansionProgress: Curves.easeInOutCubic.transform(
            _expansionController.value,
          ),
          actionKeyPrefix: actionKeyPrefix,
          dimDisabledActions:
              widget.flow != _BattleLayoutFlow.swap &&
              widget.flow != _BattleLayoutFlow.fight,
        );
      },
    );
  }
}

class _FlowBackdrop extends StatefulWidget {
  const _FlowBackdrop({
    required this.visible,
    required this.filterKey,
    this.dimOpacity = 0.42,
  });

  final bool visible;
  final Key filterKey;
  final double dimOpacity;

  @override
  State<_FlowBackdrop> createState() => _FlowBackdropState();
}

class _FlowBackdropState extends State<_FlowBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _BattleRoomPageState._flowAnimationDuration,
      animationBehavior: AnimationBehavior.preserve,
      value: widget.visible ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _FlowBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final amount = Curves.easeInOutCubic.transform(_controller.value);
            return BackdropFilter(
              key: widget.filterKey,
              filter: ui.ImageFilter.blur(
                sigmaX: 4 * amount,
                sigmaY: 4 * amount,
              ),
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: widget.dimOpacity * amount,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FlowPanelMotion extends StatefulWidget {
  const _FlowPanelMotion({
    super.key,
    required this.visible,
    required this.hiddenOffset,
    required this.child,
  });

  final bool visible;
  final Offset hiddenOffset;
  final Widget child;

  @override
  State<_FlowPanelMotion> createState() => _FlowPanelMotionState();
}

class _FlowPanelMotionState extends State<_FlowPanelMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Offset> _translation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _BattleRoomPageState._flowAnimationDuration,
      animationBehavior: AnimationBehavior.preserve,
      value: widget.visible ? 1 : 0,
    );
    _updateTranslation();
  }

  @override
  void didUpdateWidget(covariant _FlowPanelMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hiddenOffset != widget.hiddenOffset) {
      _updateTranslation();
    }
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _updateTranslation() {
    _translation = Tween<Offset>(begin: widget.hiddenOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(position: _translation, child: widget.child),
    );
  }
}

class _SwapSelectionLayer extends StatelessWidget {
  const _SwapSelectionLayer({
    required this.controller,
    required this.compact,
    required this.visible,
    required this.flowTransitioning,
    required this.focusNodes,
    required this.onSelected,
  }) : assert(focusNodes.length == 3);

  final BattleController controller;
  final bool compact;
  final bool visible;
  final bool flowTransitioning;
  final List<FocusNode> focusNodes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfHeight = constraints.maxHeight / 2;
        final opponentPanelWidth = (constraints.maxWidth * 0.24)
            .clamp(180.0, 280.0)
            .toDouble();
        final playerPanelWidth = (constraints.maxWidth * 0.345)
            .clamp(238.0, 390.0)
            .toDouble();

        return ExcludeFocus(
          excluding: !visible || flowTransitioning,
          child: ExcludeSemantics(
            excluding: !visible,
            child: IgnorePointer(
              ignoring: !visible || flowTransitioning,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: compact ? 12 : 16,
                    right: -2,
                    width: opponentPanelWidth,
                    height: halfHeight - (compact ? 22 : 28),
                    child: _FlowPanelMotion(
                      key: const ValueKey('opponent-swap-panel-motion'),
                      visible: visible,
                      hiddenOffset: const Offset(1.08, 0),
                      child: _ExpandedReserveCardGroup(
                        key: const ValueKey('expanded-opponent-reserve'),
                        team: controller.opponentTeam,
                        compact: compact,
                        accent: AppColors.danger,
                      ),
                    ),
                  ),
                  Positioned(
                    top: halfHeight + (compact ? 10 : 14),
                    right: -2,
                    bottom: compact ? 12 : 16,
                    width: playerPanelWidth,
                    child: _FlowPanelMotion(
                      key: const ValueKey('player-swap-panel-motion'),
                      visible: visible,
                      hiddenOffset: const Offset(1.08, 0),
                      child: _ExpandedReserveCardGroup(
                        key: const ValueKey('expanded-player-reserve'),
                        team: controller.playerTeam,
                        compact: compact,
                        accent: AppColors.paper,
                        eligibleSwapIndexes:
                            controller.player.hasStatus(StatusType.swapLocked)
                            ? const []
                            : controller.playerSwapIndexes,
                        focusNodes: focusNodes,
                        onSelected: onSelected,
                      ),
                    ),
                  ),
                  if (visible)
                    const SizedBox(key: ValueKey('swap-flow-visible')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeciesCardSelectionLayer extends StatelessWidget {
  const _SpeciesCardSelectionLayer({
    required this.controller,
    required this.compact,
    required this.visible,
    required this.flowTransitioning,
    required this.focusNodes,
    required this.onSelected,
  }) : assert(focusNodes.length == 3);

  final BattleController controller;
  final bool compact;
  final bool visible;
  final bool flowTransitioning;
  final List<FocusNode> focusNodes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfHeight = constraints.maxHeight / 2;
        final logWidth = math.max(120.0, constraints.maxWidth / 6);
        final menuLeft = 20 + logWidth + (compact ? 8 : 12);
        final menuRight = compact ? 42.0 : 58.0;
        final topHeight = (halfHeight * 0.64).clamp(142.0, 210.0);
        final bottomHeight = (halfHeight * 0.72).clamp(158.0, 230.0);

        return ExcludeFocus(
          excluding: !visible || flowTransitioning,
          child: ExcludeSemantics(
            excluding: !visible,
            child: IgnorePointer(
              ignoring: !visible || flowTransitioning,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: menuLeft,
                    right: menuRight,
                    top: -2,
                    height: topHeight,
                    child: _FlowPanelMotion(
                      key: const ValueKey('opponent-species-panel-motion'),
                      visible: visible,
                      hiddenOffset: const Offset(0, -1.08),
                      child: _SpeciesCardMenu(
                        key: const ValueKey('opponent-species-card-menu'),
                        team: controller.opponentTeam,
                        compact: compact,
                        isOpponent: true,
                      ),
                    ),
                  ),
                  Positioned(
                    left: menuLeft,
                    right: menuRight,
                    bottom: -2,
                    height: bottomHeight,
                    child: _FlowPanelMotion(
                      key: const ValueKey('player-species-panel-motion'),
                      visible: visible,
                      hiddenOffset: const Offset(0, 1.08),
                      child: _SpeciesCardMenu(
                        key: const ValueKey('player-species-card-menu'),
                        team: controller.playerTeam,
                        compact: compact,
                        isOpponent: false,
                        selectedIndex:
                            controller.state.pendingPlayerSpeciesCardIndex,
                        focusNodes: focusNodes,
                        onSelected: onSelected,
                      ),
                    ),
                  ),
                  if (visible)
                    const SizedBox(key: ValueKey('species-flow-visible')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeciesCardMenu extends StatelessWidget {
  const _SpeciesCardMenu({
    super.key,
    required this.team,
    required this.compact,
    required this.isOpponent,
    this.selectedIndex,
    this.focusNodes,
    this.onSelected,
  });

  final BattleTeam team;
  final bool compact;
  final bool isOpponent;
  final int? selectedIndex;
  final List<FocusNode>? focusNodes;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = isOpponent ? AppColors.danger : AppColors.paper;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.earth.withValues(alpha: 0.62),
        borderRadius: BorderRadius.only(
          bottomLeft: isOpponent ? const Radius.circular(13) : Radius.zero,
          bottomRight: isOpponent ? const Radius.circular(13) : Radius.zero,
          topLeft: isOpponent ? Radius.zero : const Radius.circular(13),
          topRight: isOpponent ? Radius.zero : const Radius.circular(13),
        ),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 12,
            offset: Offset(0, isOpponent ? 3 : -3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 9 : 12,
          compact ? 8 : 11,
          compact ? 9 : 12,
          compact ? 9 : 11,
        ),
        child: Row(
          children: [
            for (var index = 0; index < team.speciesCardSlots.length; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
                  child: _SpeciesCardOption(
                    team: team,
                    slot: team.speciesCardSlots[index],
                    index: index,
                    compact: compact,
                    isOpponent: isOpponent,
                    selected: !isOpponent && selectedIndex == index,
                    focusNode: isOpponent ? null : focusNodes?[index],
                    onPressed: isOpponent ? null : () => onSelected!(index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesCardOption extends StatelessWidget {
  const _SpeciesCardOption({
    required this.team,
    required this.slot,
    required this.index,
    required this.compact,
    required this.isOpponent,
    required this.selected,
    required this.focusNode,
    required this.onPressed,
  });

  final BattleTeam team;
  final BattleSpeciesCardSlot slot;
  final int index;
  final bool compact;
  final bool isOpponent;
  final bool selected;
  final FocusNode? focusNode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final activeCanReceive =
        !team.active.isDefeated && team.active.equippedSpeciesCard == null;
    final enabled =
        !isOpponent && activeCanReceive && !slot.consumed && !slot.lost;
    final dimmed =
        slot.consumed || slot.lost || (!isOpponent && !activeCanReceive);
    final (status, statusColor) = selected
        ? ('SELECTED', AppColors.teal)
        : _status();
    final tooltip = '${slot.card.name}\n${slot.card.effectDescription}';

    return Semantics(
      selected: selected,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.deepEarth,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.teal : AppColors.paper,
                    width: selected ? 4 : 2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.9),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      slot.card.assetPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                    if (dimmed)
                      ColoredBox(color: Colors.black.withValues(alpha: 0.48)),
                    if (selected)
                      ColoredBox(color: AppColors.teal.withValues(alpha: 0.12)),
                  ],
                ),
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            SizedBox(
              height: compact ? 34 : 40,
              child: Semantics(
                button: !isOpponent,
                enabled: enabled,
                label: '$status, ${slot.card.name}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(color: AppColors.bone, width: 2)
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.72),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : const [],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey(
                        '${isOpponent ? 'opponent' : 'player'}-species-card-$index',
                      ),
                      focusNode: focusNode,
                      canRequestFocus: enabled,
                      onTap: enabled ? onPressed : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              status,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 11 : 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _status() {
    if (slot.lost) return ('LOST', const Color(0xFFFF4444));
    if (slot.consumed) {
      final bearerIndex = slot.bearerIndex;
      if (bearerIndex != null && bearerIndex < team.combatants.length) {
        return (
          'Currently on: ${team.combatants[bearerIndex].champion.name}',
          const Color(0xFFFF8A2A),
        );
      }
      return ('ALREADY ATTACHED', const Color(0xFFFF8A2A));
    }
    if (isOpponent) return ('READY', const Color(0xFF148CF1));
    if (team.active.equippedSpeciesCard != null || team.active.isDefeated) {
      return ('UNAVAILABLE', AppColors.earth);
    }
    return ('ACTIVATE', const Color(0xFF31C960));
  }
}

class _ExpandedReserveCardGroup extends StatelessWidget {
  const _ExpandedReserveCardGroup({
    super.key,
    required this.team,
    required this.compact,
    required this.accent,
    this.eligibleSwapIndexes = const [],
    this.focusNodes,
    this.onSelected,
  });

  final BattleTeam team;
  final bool compact;
  final Color accent;
  final List<int> eligibleSwapIndexes;
  final List<FocusNode>? focusNodes;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final reserveIndexes = [
      for (var index = 0; index < team.combatants.length; index++)
        if (index != team.activeIndex) index,
    ];
    final showSwapButtons = onSelected != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.earth.withValues(alpha: 0.58),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          bottomLeft: Radius.circular(15),
        ),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 10,
            offset: const Offset(-2, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 6 : 8,
          compact ? 7 : 9,
          compact ? 7 : 9,
          compact ? 6 : 8,
        ),
        child: Column(
          children: [
            Text(
              'Reserve',
              style: TextStyle(
                color: AppColors.bone,
                fontSize: compact ? 12 : 15,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: compact ? 5 : 8),
            Expanded(
              child: Column(
                children: [
                  for (
                    var position = 0;
                    position < reserveIndexes.length;
                    position++
                  ) ...[
                    Expanded(
                      child: _ExpandedReserveRow(
                        reserveIndex: reserveIndexes[position],
                        combatant: team.combatants[reserveIndexes[position]],
                        compact: compact,
                        showSwapButton: showSwapButtons,
                        swapEnabled: eligibleSwapIndexes.contains(
                          reserveIndexes[position],
                        ),
                        focusNode: showSwapButtons && focusNodes != null
                            ? focusNodes![position]
                            : null,
                        onSwap: showSwapButtons
                            ? () => onSelected!(reserveIndexes[position])
                            : null,
                      ),
                    ),
                    if (position != reserveIndexes.length - 1)
                      SizedBox(height: compact ? 5 : 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedReserveRow extends StatelessWidget {
  const _ExpandedReserveRow({
    required this.reserveIndex,
    required this.combatant,
    required this.compact,
    required this.showSwapButton,
    required this.swapEnabled,
    this.focusNode,
    this.onSwap,
  });

  final int reserveIndex;
  final Combatant combatant;
  final bool compact;
  final bool showSwapButton;
  final bool swapEnabled;
  final FocusNode? focusNode;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = constraints.maxHeight;
        final cardHeight = math.min(rowHeight, compact ? 82.0 : 98.0);
        final horizontalGap = compact ? 5.0 : 7.0;
        final swapButtonWidth = math.min(
          cardHeight * 0.88,
          constraints.maxWidth * 0.31,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Tooltip(
              message: combatant.champion.name,
              child: MiniChampionCard.combatant(
                key: ValueKey('expanded-reserve-${combatant.champion.name}'),
                size: cardHeight,
                imageAssetPath:
                    combatant.champion.closeUpAssetPath ??
                    combatant.champion.imageAssetPath,
                currentHealth: combatant.currentHealth,
                maximumHealth: combatant.maxHealth,
                defeated: combatant.isDefeated,
                obscured: false,
                damageTrigger: 0,
              ),
            ),
            SizedBox(width: horizontalGap),
            Expanded(
              child: _ReserveChampionDetails(
                combatant: combatant,
                compact: compact,
              ),
            ),
            if (showSwapButton) ...[
              SizedBox(width: horizontalGap),
              SizedBox(
                width: swapButtonWidth,
                height: cardHeight * 0.84,
                child: _ReserveSwapButton(
                  key: ValueKey('swap-target-$reserveIndex'),
                  combatant: combatant,
                  enabled: swapEnabled,
                  focusNode: focusNode,
                  onPressed: onSwap,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ReserveChampionDetails extends StatelessWidget {
  const _ReserveChampionDetails({
    required this.combatant,
    required this.compact,
  });

  final Combatant combatant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final companions = combatant.companions;
    final speciesCard = combatant.equippedSpeciesCard;
    final gap = compact ? 3.0 : 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  image: true,
                  label: '${combatant.champion.type.name} champion type',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest.shortestSide;
                      return Center(
                        child: ChampionTypeEmblem(
                          type: combatant.champion.type,
                          size: size,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Tooltip(
                  message: companions.isEmpty
                      ? 'No companions'
                      : companions
                            .map((companion) => companion.name)
                            .join(', '),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.sand.withValues(alpha: 0.34),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: companions.isEmpty
                        ? const SizedBox.expand()
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                companions.first.assetPath,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              ),
                              const ColoredBox(color: Color(0x47000000)),
                              Center(
                                child: Text(
                                  '${companions.length}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 14 : 17,
                                    fontWeight: FontWeight.w900,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: Tooltip(
            message: speciesCard == null
                ? 'No equipped species card'
                : '${speciesCard.name}\n${speciesCard.effectDescription}',
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: speciesCard == null
                  ? const SizedBox.expand()
                  : Image.asset(
                      speciesCard.assetPath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReserveSwapButton extends StatelessWidget {
  const _ReserveSwapButton({
    super.key,
    required this.combatant,
    required this.enabled,
    required this.focusNode,
    required this.onPressed,
  });

  final Combatant combatant;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Swap to ${combatant.champion.name}',
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: enabled ? AppColors.teal : AppColors.earth,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.ink, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            focusNode: focusNode,
            canRequestFocus: enabled,
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/images/swap_icon.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'SWAP',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
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

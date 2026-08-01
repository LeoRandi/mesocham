import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/input/number_focus_shortcuts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../champions/domain/entities/champion_move.dart';
import '../../../champions/domain/repositories/champion_catalog.dart';
import '../../../champions/presentation/widgets/champion_card.dart';
import '../../../companions/domain/entities/companion.dart';
import '../../../companions/presentation/widgets/companion_orb.dart';
import '../../../home/data/player_preferences.dart';
import '../../../species_cards/presentation/widgets/species_card_widgets.dart';
import '../../application/services/battle_session.dart';
import '../../application/services/fossil_race_team_factory.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
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

class BattleRoomPage extends StatefulWidget {
  const BattleRoomPage({
    super.key,
    required this.catalog,
    required this.playerPreferences,
  });

  final ChampionCatalog catalog;
  final PlayerPreferences playerPreferences;

  @override
  State<BattleRoomPage> createState() => _BattleRoomPageState();
}

class _BattleRoomPageState extends State<BattleRoomPage> {
  static const _preResolutionDelay = Duration(milliseconds: 420);
  static const _resultDisplayDuration = Duration(milliseconds: 1250);

  BattleController? _controller;
  Object? _loadError;
  bool _combatLogOpen = false;
  final _battleActionFocusNodes = List.generate(
    4,
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
  final _showdownFocusNode = FocusNode(debugLabel: 'Showdown');
  final _gameOverMenuFocusNode = FocusNode(debugLabel: 'Game over menu');
  final _rematchFocusNode = FocusNode(debugLabel: 'Rematch');

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
      ).create(collection);
      if (!mounted) return;

      setState(() {
        final companionRandomizer = CompanionRandomizer();
        _loadError = null;
        _combatLogOpen = false;
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

  void _startFight() {
    _controller?.startFight();
    _requestFocusAfterFrame(_moveFocusNodes.first);
  }

  void _selectSpeciesCard(int index) {
    _controller?.selectPlayerSpeciesCard(index);
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

    _requestFocusAfterFrame(
      controller.phase == BattlePhase.gameOver
          ? _rematchFocusNode
          : _battleActionFocusNodes.first,
    );
  }

  void _resetBattle() {
    _controller?.resetBattle();
    _requestFocusAfterFrame(_battleActionFocusNodes.first);
  }

  void _startSwap() {
    _controller?.startSwap();
    _requestFocusAfterFrame(_swapFocusNodes.first);
  }

  void _cancelSwap() {
    _controller?.cancelSwap();
    _requestFocusAfterFrame(_battleActionFocusNodes.first);
  }

  Future<void> _swapPlayerTo(int index) async {
    final controller = _controller;
    if (controller == null || !controller.beginSwap(index)) return;

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
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxHeight < 560 ||
                          constraints.maxWidth < 900;
                      final mobileLog = constraints.maxWidth < 700;
                      return _BattleRoom(
                        controller: controller,
                        compact: compact,
                        mobileLog: mobileLog,
                        combatLogOpen: _combatLogOpen,
                        battleActionFocusNodes: _battleActionFocusNodes,
                        moveFocusNodes: _moveFocusNodes,
                        mixedMoveOptionFocusNodes: _mixedMoveOptionFocusNodes,
                        swapFocusNodes: _swapFocusNodes,
                        showdownFocusNode: _showdownFocusNode,
                        gameOverMenuFocusNode: _gameOverMenuFocusNode,
                        rematchFocusNode: _rematchFocusNode,
                        onFight: _startFight,
                        onSelectSpeciesCard: _selectSpeciesCard,
                        onSwap: _startSwap,
                        onCancelSwap: _cancelSwap,
                        onSelectSwapTarget: _swapPlayerTo,
                        onShowdown: _showdown,
                        onRematch: _resetBattle,
                        onExit: () => Navigator.of(context).pop(),
                        onOpenCombatLog: () {
                          setState(() => _combatLogOpen = true);
                        },
                        onCloseCombatLog: () {
                          setState(() => _combatLogOpen = false);
                        },
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
    required this.mobileLog,
    required this.combatLogOpen,
    required this.battleActionFocusNodes,
    required this.moveFocusNodes,
    required this.mixedMoveOptionFocusNodes,
    required this.swapFocusNodes,
    required this.showdownFocusNode,
    required this.gameOverMenuFocusNode,
    required this.rematchFocusNode,
    required this.onFight,
    required this.onSelectSpeciesCard,
    required this.onSwap,
    required this.onCancelSwap,
    required this.onSelectSwapTarget,
    required this.onShowdown,
    required this.onRematch,
    required this.onExit,
    required this.onOpenCombatLog,
    required this.onCloseCombatLog,
  });

  final BattleController controller;
  final bool compact;
  final bool mobileLog;
  final bool combatLogOpen;
  final List<FocusNode> battleActionFocusNodes;
  final List<FocusNode> moveFocusNodes;
  final List<FocusNode> mixedMoveOptionFocusNodes;
  final List<FocusNode> swapFocusNodes;
  final FocusNode showdownFocusNode;
  final FocusNode gameOverMenuFocusNode;
  final FocusNode rematchFocusNode;
  final VoidCallback onFight;
  final ValueChanged<int> onSelectSpeciesCard;
  final VoidCallback onSwap;
  final VoidCallback onCancelSwap;
  final ValueChanged<int> onSelectSwapTarget;
  final VoidCallback onShowdown;
  final VoidCallback onRematch;
  final VoidCallback onExit;
  final VoidCallback onOpenCombatLog;
  final VoidCallback onCloseCombatLog;

  @override
  Widget build(BuildContext context) {
    final overlayVisible = controller.isFightOverlayVisible;
    final resolution = controller.lastResolution;

    return Stack(
      fit: StackFit.expand,
      children: [
        const BattleBackdrop(),
        Column(
          children: [
            Expanded(
              child: _ChampionZone(
                team: controller.opponentTeam,
                isOpponent: true,
                compact: compact,
                resolutionSequence: controller.resolutionSequence,
                damagedIndexes: resolution?.damagedOpponentIndexes ?? const [],
                showChampion: !overlayVisible,
                fightEnabled: false,
                swapEnabled: false,
                speciesCardSelectionEnabled: false,
                onFight: () {},
                onSelectSpeciesCard: (_) {},
                onSwap: () {},
              ),
            ),
            Container(
              height: compact ? 1 : 1.5,
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.62),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.24),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ChampionZone(
                team: controller.playerTeam,
                isOpponent: false,
                compact: compact,
                resolutionSequence: controller.resolutionSequence,
                damagedIndexes: resolution?.damagedPlayerIndexes ?? const [],
                showChampion: !overlayVisible,
                fightEnabled: controller.phase == BattlePhase.command,
                swapEnabled: controller.canSwap,
                selectedSpeciesCardIndex:
                    controller.pendingPlayerSpeciesCardIndex,
                speciesCardSelectionEnabled:
                    controller.phase == BattlePhase.command,
                battleActionFocusNodes: battleActionFocusNodes,
                canFocusBattleActions: controller.phase == BattlePhase.command,
                onFight: onFight,
                onSelectSpeciesCard: onSelectSpeciesCard,
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
        if (controller.wildCompanionStack.isNotEmpty)
          IgnorePointer(
            child: Align(
              alignment: const Alignment(-0.34, 0),
              child: AnimatedOpacity(
                opacity: overlayVisible ? 0.82 : 1,
                duration: const Duration(milliseconds: 260),
                child: _WildCompanionStack(
                  companions: controller.wildCompanionStack,
                  compact: compact,
                ),
              ),
            ),
          ),
        _MoveSelectionLayer(
          controller: controller,
          compact: compact,
          moveFocusNodes: moveFocusNodes,
          mixedMoveOptionFocusNodes: mixedMoveOptionFocusNodes,
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
        _CombatLogOverlay(
          entries: controller.combatLog,
          mobile: mobileLog,
          open: combatLogOpen,
          onOpen: onOpenCombatLog,
          onClose: onCloseCombatLog,
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

class _CombatLogOverlay extends StatefulWidget {
  const _CombatLogOverlay({
    required this.entries,
    required this.mobile,
    required this.open,
    required this.onOpen,
    required this.onClose,
  });

  final List<String> entries;
  final bool mobile;
  final bool open;
  final VoidCallback onOpen;
  final VoidCallback onClose;

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
    if (widget.entries.length != oldWidget.entries.length ||
        (widget.mobile && widget.open && !oldWidget.open)) {
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
        final panelWidth = widget.mobile
            ? math.min(constraints.maxWidth * 0.82, 360.0)
            : math.min(constraints.maxWidth * 0.25, 380.0);
        final availableHeight = math.max(120.0, constraints.maxHeight - 32);
        final panelHeight = math.min(
          math.max(240.0, constraints.maxHeight * 0.72),
          availableHeight,
        );
        final top = (constraints.maxHeight - panelHeight) / 2;
        final panelLeft = widget.mobile
            ? (widget.open ? 0.0 : -panelWidth - 8)
            : 16.0;
        final toggleLeft = widget.open ? panelWidth : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              left: panelLeft,
              top: top,
              width: panelWidth,
              height: panelHeight,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _CombatLogPanel(
                entries: widget.entries,
                scrollController: _scrollController,
              ),
            ),
            if (widget.mobile)
              AnimatedPositioned(
                left: toggleLeft,
                top: (constraints.maxHeight - 46) / 2,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _CombatLogToggle(
                  open: widget.open,
                  onPressed: widget.open ? widget.onClose : widget.onOpen,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: AppColors.deepEarth.withValues(alpha: 0.96),
                child: const Text(
                  'REGISTRO DE COMBATE',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
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
                            fontSize: 12,
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

class _CombatLogToggle extends StatelessWidget {
  const _CombatLogToggle({required this.open, required this.onPressed});

  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: open ? 'Cerrar registro de combate' : 'Abrir registro de combate',
      child: Material(
        color: AppColors.deepEarth.withValues(alpha: 0.97),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
          side: BorderSide(color: AppColors.amber, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(10),
          ),
          child: SizedBox(
            width: 38,
            height: 46,
            child: Center(
              child: Text(
                open ? '<' : '>',
                style: const TextStyle(
                  color: AppColors.amber,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
    required this.compact,
    required this.resolutionSequence,
    required this.damagedIndexes,
    required this.showChampion,
    required this.fightEnabled,
    required this.swapEnabled,
    required this.speciesCardSelectionEnabled,
    required this.onFight,
    required this.onSelectSpeciesCard,
    required this.onSwap,
    this.selectedSpeciesCardIndex,
    this.battleActionFocusNodes,
    this.canFocusBattleActions = false,
  }) : assert(isOpponent || battleActionFocusNodes?.length == 4);

  final BattleTeam team;
  final bool isOpponent;
  final bool compact;
  final int resolutionSequence;
  final List<int> damagedIndexes;
  final bool showChampion;
  final bool fightEnabled;
  final bool swapEnabled;
  final bool speciesCardSelectionEnabled;
  final VoidCallback onFight;
  final ValueChanged<int> onSelectSpeciesCard;
  final VoidCallback onSwap;
  final int? selectedSpeciesCardIndex;
  final List<FocusNode>? battleActionFocusNodes;
  final bool canFocusBattleActions;

  @override
  Widget build(BuildContext context) {
    final combatant = team.active;
    final activeDamageTrigger = damagedIndexes.contains(team.activeIndex)
        ? resolutionSequence
        : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final controlsInset = compact ? 52.0 : 78.0;
        final availableForCard =
            constraints.maxHeight -
            (isOpponent ? 0 : controlsInset) -
            (compact ? 26 : 42);
        final cardHeight = math
            .max(
              compact ? 68.0 : 100.0,
              math.min(compact ? 108.0 : 196.0, availableForCard),
            )
            .toDouble();
        final horizontalPadding = compact ? 12.0 : 32.0;
        final sidePanelWidth = math
            .min(
              compact ? 270.0 : 390.0,
              math.max(
                compact ? 210.0 : 300.0,
                constraints.maxWidth * (compact ? 0.43 : 0.39),
              ),
            )
            .toDouble();
        final cardGap = compact ? 4.0 : 7.0;
        final miniCardHeight = math
            .max(
              compact ? 30.0 : 48.0,
              math.min(
                cardHeight * (compact ? 0.36 : 0.34),
                compact ? 44.0 : 66.0,
              ),
            )
            .toDouble();
        final accent = isOpponent ? AppColors.danger : AppColors.teal;

        return Stack(
          children: [
            Positioned.fill(
              bottom: isOpponent ? 0 : controlsInset,
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
                          isOpponent
                              ? 'RIVAL ACTIVE CHAMPION'
                              : 'YOUR ACTIVE CHAMPION',
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            color: accent,
                            fontSize: compact ? 8 : 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: compact ? 0.8 : 1.15,
                          ),
                        ),
                        SizedBox(height: compact ? 3 : 6),
                        SpeciesCardBearer(
                          bearerHeight: cardHeight,
                          card: combatant.equippedSpeciesCard,
                          effectActive: true,
                          child: ChampionCard(
                            champion: combatant.champion,
                            height: cardHeight,
                            currentHealth: combatant.currentHealth,
                            maximumHealth: combatant.maxHealth,
                            defeated: combatant.isDefeated,
                            damageTrigger: activeDamageTrigger,
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        _StatusStrip(combatant: combatant, compact: compact),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: compact ? 6 : 14,
              right: horizontalPadding,
              bottom: (isOpponent ? 0 : controlsInset) + (compact ? 6 : 14),
              width: sidePanelWidth,
              child: _BattleSidePanel(
                team: team,
                compact: compact,
                cardGap: cardGap,
                miniCardHeight: miniCardHeight,
                selectedSpeciesCardIndex: selectedSpeciesCardIndex,
                speciesCardSelectionEnabled: speciesCardSelectionEnabled,
                resolutionSequence: resolutionSequence,
                damagedIndexes: damagedIndexes,
                onSelectSpeciesCard: onSelectSpeciesCard,
              ),
            ),
            if (!isOpponent)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: compact ? 100 : 180,
                    right: compact ? 100 : 180,
                    bottom: compact ? 7 : 14,
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

class _BattleSidePanel extends StatelessWidget {
  const _BattleSidePanel({
    required this.team,
    required this.compact,
    required this.cardGap,
    required this.miniCardHeight,
    required this.selectedSpeciesCardIndex,
    required this.speciesCardSelectionEnabled,
    required this.resolutionSequence,
    required this.damagedIndexes,
    required this.onSelectSpeciesCard,
  });

  final BattleTeam team;
  final bool compact;
  final double cardGap;
  final double miniCardHeight;
  final int? selectedSpeciesCardIndex;
  final bool speciesCardSelectionEnabled;
  final int resolutionSequence;
  final List<int> damagedIndexes;
  final ValueChanged<int> onSelectSpeciesCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _CompanionGroup(combatant: team.active, compact: compact),
          ),
        ),
        SizedBox(height: compact ? 6 : 12),
        _SpeciesCardGroup(
          team: team,
          compact: compact,
          cardGap: cardGap,
          selectedIndex: selectedSpeciesCardIndex,
          selectionEnabled: speciesCardSelectionEnabled,
          onSelected: onSelectSpeciesCard,
        ),
        SizedBox(height: compact ? 10 : 20),
        _ReserveCardGroup(
          compact: compact,
          cardHeight: miniCardHeight,
          cardGap: cardGap,
          team: team,
          resolutionSequence: resolutionSequence,
          damagedIndexes: damagedIndexes,
        ),
      ],
    );
  }
}

class _CompanionGroup extends StatelessWidget {
  const _CompanionGroup({required this.combatant, required this.compact});

  final Combatant combatant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final diameter = compact ? 28.0 : 42.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GroupLabel(label: 'COMPANIONS', compact: compact),
        SizedBox(height: compact ? 4 : 8),
        if (combatant.companions.isEmpty)
          Text(
            '—',
            style: TextStyle(
              color: AppColors.sand.withValues(alpha: 0.45),
              fontSize: compact ? 12 : 17,
              fontWeight: FontWeight.w800,
            ),
          )
        else
          SizedBox(
            height: diameter,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (
                    var index = 0;
                    index < combatant.companions.length;
                    index++
                  )
                    Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : (compact ? 4 : 7),
                      ),
                      child: CompanionOrb(
                        key: ValueKey(
                          '${combatant.champion.id}-$index-'
                          '${combatant.companions[index].name}',
                        ),
                        companion: combatant.companions[index],
                        diameter: diameter,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WildCompanionStack extends StatelessWidget {
  const _WildCompanionStack({required this.companions, required this.compact});

  final List<Companion> companions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final diameter = compact ? 62.0 : 92.0;
    final visibleCount = companions.length;
    final horizontalOffset = diameter * 0.14;
    final verticalOffset = diameter * 0.1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      child: SizedBox(
        key: ObjectKey(companions),
        width: diameter + horizontalOffset * (visibleCount - 1),
        height:
            diameter +
            verticalOffset * (visibleCount - 1) +
            (compact ? 22 : 30),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = visibleCount - 1; index >= 1; index--)
              Positioned(
                left: horizontalOffset * index,
                top: verticalOffset * (visibleCount - 1 - index),
                child: CompanionOrb(
                  companion: companions[index],
                  diameter: diameter * (1 - math.min(index, 3) * 0.1),
                  wild: true,
                  queued: true,
                ),
              ),
            Positioned(
              left: 0,
              top: verticalOffset * (visibleCount - 1),
              child: CompanionOrb(
                companion: companions.first,
                diameter: diameter,
                wild: true,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Text(
                companions.length == 1
                    ? 'WILD COMPANION'
                    : 'WILD COMPANION  ·  ${companions.length - 1} QUEUED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: compact ? 7 : 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 0.6 : 0.9,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesCardGroup extends StatelessWidget {
  const _SpeciesCardGroup({
    required this.team,
    required this.compact,
    required this.cardGap,
    required this.selectedIndex,
    required this.selectionEnabled,
    required this.onSelected,
  });

  final BattleTeam team;
  final bool compact;
  final double cardGap;
  final int? selectedIndex;
  final bool selectionEnabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GroupLabel(label: 'SPECIES CARDS', compact: compact),
        SizedBox(height: compact ? 4 : 8),
        Row(
          children: [
            for (var index = 0; index < team.speciesCardSlots.length; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : cardGap),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: SpeciesCardTile(
                      key: ValueKey('species-card-$index'),
                      card: team.speciesCardSlots[index].card,
                      selected: selectedIndex == index,
                      equipped: team.speciesCardSlots[index].consumed,
                      enabled:
                          selectionEnabled &&
                          !team.speciesCardSlots[index].consumed &&
                          team.active.equippedSpeciesCard == null &&
                          !team.active.isDefeated,
                      onPressed: () => onSelected(index),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReserveCardGroup extends StatelessWidget {
  const _ReserveCardGroup({
    required this.compact,
    required this.cardHeight,
    required this.cardGap,
    required this.team,
    this.resolutionSequence = 0,
    this.damagedIndexes = const [],
  });

  final bool compact;
  final double cardHeight;
  final double cardGap;
  final BattleTeam team;
  final int resolutionSequence;
  final List<int> damagedIndexes;

  @override
  Widget build(BuildContext context) {
    final reserveIndexes = [
      for (var index = 0; index < team.combatants.length; index++)
        if (index != team.activeIndex) index,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GroupLabel(label: 'RESERVE', compact: compact),
        SizedBox(height: compact ? 4 : 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var position = 0; position < reserveIndexes.length; position++)
              Padding(
                padding: EdgeInsets.only(left: position == 0 ? 0 : cardGap),
                child: SpeciesCardBearer(
                  bearerHeight: cardHeight,
                  card: team
                      .combatants[reserveIndexes[position]]
                      .equippedSpeciesCard,
                  effectActive: false,
                  mini: true,
                  child: MiniChampionCard.combatant(
                    key: ValueKey(
                      '${team.activeIndex}-${reserveIndexes[position]}',
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
                    currentHealth:
                        team.combatants[reserveIndexes[position]].currentHealth,
                    maximumHealth:
                        team.combatants[reserveIndexes[position]].maxHealth,
                    defeated:
                        team.combatants[reserveIndexes[position]].isDefeated,
                    obscured: false,
                    damageTrigger:
                        damagedIndexes.contains(reserveIndexes[position])
                        ? resolutionSequence
                        : 0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.bone.withValues(alpha: 0.86),
        fontSize: compact ? 7.5 : 10,
        fontWeight: FontWeight.w900,
        letterSpacing: compact ? 0.65 : 0.95,
        shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
      ),
    );
  }
}

class _MoveSelectionLayer extends StatelessWidget {
  const _MoveSelectionLayer({
    required this.controller,
    required this.compact,
    required this.moveFocusNodes,
    required this.mixedMoveOptionFocusNodes,
    required this.showdownFocusNode,
    required this.onShowdown,
  });

  final BattleController controller;
  final bool compact;
  final List<FocusNode> moveFocusNodes;
  final List<FocusNode> mixedMoveOptionFocusNodes;
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
                  currentHealth: combatant.currentHealth,
                  maximumHealth: combatant.maxHealth,
                  defeated: combatant.isDefeated,
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
    StatusType.secondaryImmunity => AppColors.teal,
    StatusType.totalCover => const Color(0xFFB8C6D9),
    StatusType.swapLocked => AppColors.danger,
    StatusType.spikeEnclosure => const Color(0xFFD99154),
    StatusType.groundedRegeneration => const Color(0xFF78A66A),
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

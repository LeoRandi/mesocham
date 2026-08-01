import '../../../champions/domain/entities/champion_move.dart';
import '../../../companions/domain/entities/companion.dart';
import 'battle_gesture.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_team.dart';
import 'battle_turn.dart';
import 'combatant.dart';

enum PendingBattleAction { showdown, swap }

class BattleState {
  BattleState({
    required this.playerTeam,
    required this.opponentTeam,
    this.phase = BattlePhase.command,
    this.playerGesture,
    this.playerMoveOption,
    this.opponentGesture,
    this.lastResolution,
    this.previousTurn,
    this.pendingAction,
    this.pendingPlayerSpeciesCardIndex,
    this.resolutionSequence = 0,
    List<Companion> wildCompanionStack = const [],
  }) : wildCompanionStack = List.unmodifiable(wildCompanionStack);

  final BattleTeam playerTeam;
  final BattleTeam opponentTeam;
  final BattlePhase phase;
  final BattleGesture? playerGesture;
  final int? playerMoveOption;
  final BattleGesture? opponentGesture;
  final BattleResolution? lastResolution;
  final BattleTurn? previousTurn;
  final PendingBattleAction? pendingAction;
  final int? pendingPlayerSpeciesCardIndex;
  final int resolutionSequence;
  final List<Companion> wildCompanionStack;

  Combatant get player => playerTeam.active;
  Combatant get opponent => opponentTeam.active;
  Companion? get wildCompanion =>
      wildCompanionStack.isEmpty ? null : wildCompanionStack.first;
  List<int> get playerSwapIndexes => playerTeam.swapIndexes;

  bool get isFightOverlayVisible =>
      phase == BattlePhase.choosingMove ||
      (phase == BattlePhase.resolving && lastResolution == null);
  bool get isSwapOverlayVisible => phase == BattlePhase.swapping;
  bool get canShowdown {
    if (phase != BattlePhase.choosingMove || playerGesture == null) {
      return false;
    }
    return selectedPlayerMove?.effect != MoveEffect.mixedChoice ||
        playerMoveOption != null;
  }

  bool get canSwap =>
      phase == BattlePhase.command &&
      playerSwapIndexes.isNotEmpty &&
      !player.hasStatus(StatusType.swapLocked);

  bool canSelectPlayerSpeciesCard(int index) {
    return phase == BattlePhase.command &&
        index >= 0 &&
        index < playerTeam.speciesCardSlots.length &&
        !playerTeam.speciesCardSlots[index].consumed &&
        !playerTeam.active.isDefeated &&
        playerTeam.active.equippedSpeciesCard == null;
  }

  ChampionMove? get selectedPlayerMove =>
      playerGesture == null ? null : player.champion.moveFor(playerGesture!);

  BattleState copyWith({
    BattleTeam? playerTeam,
    BattleTeam? opponentTeam,
    BattlePhase? phase,
    BattleGesture? playerGesture,
    bool clearPlayerGesture = false,
    int? playerMoveOption,
    bool clearPlayerMoveOption = false,
    BattleGesture? opponentGesture,
    bool clearOpponentGesture = false,
    BattleResolution? lastResolution,
    bool clearLastResolution = false,
    BattleTurn? previousTurn,
    bool clearPreviousTurn = false,
    PendingBattleAction? pendingAction,
    bool clearPendingAction = false,
    int? pendingPlayerSpeciesCardIndex,
    bool clearPendingPlayerSpeciesCard = false,
    int? resolutionSequence,
    List<Companion>? wildCompanionStack,
    bool clearWildCompanionStack = false,
  }) {
    return BattleState(
      playerTeam: playerTeam ?? this.playerTeam,
      opponentTeam: opponentTeam ?? this.opponentTeam,
      phase: phase ?? this.phase,
      playerGesture: clearPlayerGesture
          ? null
          : playerGesture ?? this.playerGesture,
      playerMoveOption: clearPlayerMoveOption
          ? null
          : playerMoveOption ?? this.playerMoveOption,
      opponentGesture: clearOpponentGesture
          ? null
          : opponentGesture ?? this.opponentGesture,
      lastResolution: clearLastResolution
          ? null
          : lastResolution ?? this.lastResolution,
      previousTurn: clearPreviousTurn
          ? null
          : previousTurn ?? this.previousTurn,
      pendingAction: clearPendingAction
          ? null
          : pendingAction ?? this.pendingAction,
      pendingPlayerSpeciesCardIndex: clearPendingPlayerSpeciesCard
          ? null
          : pendingPlayerSpeciesCardIndex ?? this.pendingPlayerSpeciesCardIndex,
      resolutionSequence: resolutionSequence ?? this.resolutionSequence,
      wildCompanionStack: clearWildCompanionStack
          ? const []
          : wildCompanionStack ?? this.wildCompanionStack,
    );
  }
}

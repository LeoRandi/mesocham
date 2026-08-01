import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_state.dart';
import '../../domain/entities/battle_status.dart';
import '../../domain/entities/battle_team.dart';
import '../../domain/entities/battle_turn.dart';
import '../../domain/services/ai_move_strategy.dart';
import '../../domain/services/battle_rules.dart';
import '../../domain/services/companion_randomizer.dart';
import '../../../champions/domain/entities/champion_move.dart';
import '../../../companions/domain/entities/companion.dart';
import '../../../species_cards/domain/entities/species_card.dart';

class BattleSession {
  BattleSession({
    required BattleRules rules,
    required AiMoveStrategy opponentStrategy,
    required CompanionRandomizer companionRandomizer,
  }) : _rules = rules,
       _opponentStrategy = opponentStrategy,
       _companionRandomizer = companionRandomizer;

  final BattleRules _rules;
  final AiMoveStrategy _opponentStrategy;
  final CompanionRandomizer _companionRandomizer;

  BattleState initialState({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
  }) {
    return BattleState(playerTeam: playerTeam, opponentTeam: opponentTeam);
  }

  BattleState startFight(BattleState state) {
    if (state.phase != BattlePhase.command) return state;

    return state.copyWith(
      phase: BattlePhase.choosingMove,
      clearLastResolution: true,
      clearPlayerGesture: true,
      clearPlayerMoveOption: true,
      opponentGesture: _chooseOpponentMove(state),
    );
  }

  BattleState startSwap(BattleState state) {
    if (!state.canSwap) return state;

    return state.copyWith(
      phase: BattlePhase.swapping,
      clearLastResolution: true,
      clearPlayerGesture: true,
      clearPendingPlayerSpeciesCard: true,
      opponentGesture: _chooseOpponentMove(state),
    );
  }

  BattleState cancelSwap(BattleState state) {
    if (state.phase != BattlePhase.swapping) return state;

    return state.copyWith(
      phase: BattlePhase.command,
      clearOpponentGesture: true,
    );
  }

  BattleState selectPlayerGesture(BattleState state, BattleGesture gesture) {
    if (state.phase != BattlePhase.choosingMove) return state;
    return state.copyWith(playerGesture: gesture, clearPlayerMoveOption: true);
  }

  BattleState selectPlayerMoveOption(BattleState state, int option) {
    if (state.phase != BattlePhase.choosingMove ||
        state.selectedPlayerMove?.effect != MoveEffect.mixedChoice ||
        option < 0 ||
        option > 2) {
      return state;
    }
    return state.copyWith(playerMoveOption: option);
  }

  BattleState selectPlayerSpeciesCard(BattleState state, int index) {
    if (!state.canSelectPlayerSpeciesCard(index)) return state;
    if (state.pendingPlayerSpeciesCardIndex == index) {
      return state.copyWith(clearPendingPlayerSpeciesCard: true);
    }
    return state.copyWith(pendingPlayerSpeciesCardIndex: index);
  }

  BattleState beginShowdown(BattleState state) {
    if (!state.canShowdown || state.opponentGesture == null) return state;

    return state.copyWith(
      phase: BattlePhase.resolving,
      pendingAction: PendingBattleAction.showdown,
    );
  }

  BattleState beginSwap(BattleState state, int index) {
    if (state.phase != BattlePhase.swapping ||
        !state.playerSwapIndexes.contains(index) ||
        state.opponentGesture == null) {
      return state;
    }

    return state.copyWith(
      playerTeam: state.playerTeam.swapTo(index),
      phase: BattlePhase.resolving,
      pendingAction: PendingBattleAction.swap,
    );
  }

  BattleState resolvePendingAction(BattleState state) {
    if (state.phase != BattlePhase.resolving ||
        state.pendingAction == null ||
        state.lastResolution != null ||
        state.opponentGesture == null) {
      return state;
    }

    return switch (state.pendingAction!) {
      PendingBattleAction.showdown => _resolveShowdown(state),
      PendingBattleAction.swap => _resolveSwap(state),
    };
  }

  BattleState completeResolution(BattleState state) {
    if (state.phase != BattlePhase.resolving || state.lastResolution == null) {
      return state;
    }

    final gameOver =
        state.playerTeam.isDefeated || state.opponentTeam.isDefeated;
    var nextState = state.copyWith(
      phase: gameOver ? BattlePhase.gameOver : BattlePhase.command,
      clearPlayerGesture: true,
      clearPlayerMoveOption: true,
      clearOpponentGesture: true,
      clearLastResolution: true,
      clearPendingAction: true,
      clearPendingPlayerSpeciesCard: true,
    );
    if (!gameOver && (state.resolutionSequence + 1).isEven) {
      nextState = _appendWildCompanion(nextState);
    }
    return nextState;
  }

  BattleGesture _chooseOpponentMove(BattleState state) {
    return _opponentStrategy.chooseMove(
      self: state.opponent,
      opponent: state.player,
      previousTurn: state.previousTurn,
    );
  }

  BattleState _resolveShowdown(BattleState state) {
    var resolution = _rules.resolve(
      playerTeam: state.playerTeam,
      opponentTeam: state.opponentTeam,
      playerGesture: state.playerGesture!,
      opponentGesture: state.opponentGesture!,
      playerMoveOption: state.playerMoveOption,
    );
    final selectedCardIndex = state.pendingPlayerSpeciesCardIndex;
    if (resolution.outcome == BattleOutcome.playerVictory &&
        selectedCardIndex != null) {
      final selectedCard =
          state.playerTeam.speciesCardSlots[selectedCardIndex].card;
      var equippedPlayerTeam = resolution.playerTeam.equipSpeciesCard(
        cardSlotIndex: selectedCardIndex,
        bearerIndex: state.playerTeam.activeIndex,
      );
      var opponentTeam = resolution.opponentTeam;
      final cardWasEquipped =
          equippedPlayerTeam
              .combatants[state.playerTeam.activeIndex]
              .equippedSpeciesCard ==
          selectedCard;
      if (cardWasEquipped && selectedCard == SpeciesCard.kingOfTheSkies) {
        final summonResult = _summonDistinctCompanions(
          bearerTeam: equippedPlayerTeam,
          rivalTeam: opponentTeam,
          bearerIndex: state.playerTeam.activeIndex,
          count: 3,
        );
        equippedPlayerTeam = summonResult.bearerTeam;
        opponentTeam = summonResult.rivalTeam;
      }
      resolution = resolution.copyWith(
        playerTeam: equippedPlayerTeam,
        opponentTeam: opponentTeam,
      );
    }

    var wildCompanionStack = state.wildCompanionStack;
    final wildCompanion = state.wildCompanion;
    if (wildCompanion != null && resolution.outcome != BattleOutcome.draw) {
      final companionResult = resolution.outcome == BattleOutcome.playerVictory
          ? _awardCompanion(
              winnerTeam: resolution.playerTeam,
              loserTeam: resolution.opponentTeam,
              bearerIndex: state.playerTeam.activeIndex,
              companion: wildCompanion,
            )
          : _awardCompanion(
              winnerTeam: resolution.opponentTeam,
              loserTeam: resolution.playerTeam,
              bearerIndex: state.opponentTeam.activeIndex,
              companion: wildCompanion,
            );
      if (companionResult.attached) {
        resolution = resolution.outcome == BattleOutcome.playerVictory
            ? resolution.copyWith(
                playerTeam: companionResult.winnerTeam,
                opponentTeam: companionResult.loserTeam,
              )
            : resolution.copyWith(
                playerTeam: companionResult.loserTeam,
                opponentTeam: companionResult.winnerTeam,
              );
        wildCompanionStack = wildCompanionStack.sublist(1);
      }
    }

    return state.copyWith(
      playerTeam: resolution.playerTeam,
      opponentTeam: resolution.opponentTeam,
      lastResolution: resolution,
      previousTurn: BattleTurn(
        playerGesture: state.playerGesture!,
        opponentGesture: state.opponentGesture!,
        outcome: resolution.outcome,
      ),
      clearPendingPlayerSpeciesCard: true,
      resolutionSequence: state.resolutionSequence + 1,
      wildCompanionStack: wildCompanionStack,
    );
  }

  BattleState _resolveSwap(BattleState state) {
    final resolution = _rules.resolveGuaranteedOpponentMove(
      playerTeam: state.playerTeam,
      opponentTeam: state.opponentTeam,
      opponentGesture: state.opponentGesture!,
    );

    return state.copyWith(
      playerTeam: resolution.playerTeam,
      opponentTeam: resolution.opponentTeam,
      lastResolution: resolution,
      clearPreviousTurn: true,
      resolutionSequence: state.resolutionSequence + 1,
    );
  }

  BattleState _appendWildCompanion(BattleState state) {
    final companion = _companionRandomizer.chooseAppearing(
      beetleBlocked:
          state.playerTeam.active.hasCompanion(Companion.beetle) ||
          state.opponentTeam.active.hasCompanion(Companion.beetle),
    );
    if (companion == null) return state;
    return state.copyWith(
      wildCompanionStack: [...state.wildCompanionStack, companion],
    );
  }

  ({BattleTeam winnerTeam, BattleTeam loserTeam, bool attached})
  _awardCompanion({
    required BattleTeam winnerTeam,
    required BattleTeam loserTeam,
    required int bearerIndex,
    required Companion companion,
  }) {
    final nextWinnerTeam = winnerTeam.addCompanion(
      bearerIndex: bearerIndex,
      companion: companion,
    );
    if (nextWinnerTeam.combatants[bearerIndex].companions.length ==
        winnerTeam.combatants[bearerIndex].companions.length) {
      return (winnerTeam: winnerTeam, loserTeam: loserTeam, attached: false);
    }
    final bearer = nextWinnerTeam.combatants[bearerIndex];
    final famineStacks = switch (companion) {
      Companion.weta || Companion.beetle =>
        (bearer.companionCount(Companion.weta) *
                bearer.companionEffectMultiplier)
            .toInt(),
      _ => 0,
    };
    if (famineStacks == 0) {
      return (winnerTeam: nextWinnerTeam, loserTeam: loserTeam, attached: true);
    }

    final nextLoserTeam = loserTeam.applyStatusToActive(
      StatusApplication(
        type: StatusType.famine,
        target: StatusTarget.opponent,
        stacks: famineStacks,
        permanent: true,
        delayFirstTick: false,
      ),
    );
    return (
      winnerTeam: nextWinnerTeam,
      loserTeam: nextLoserTeam,
      attached: true,
    );
  }

  ({BattleTeam bearerTeam, BattleTeam rivalTeam}) _summonDistinctCompanions({
    required BattleTeam bearerTeam,
    required BattleTeam rivalTeam,
    required int bearerIndex,
    required int count,
  }) {
    var nextBearerTeam = bearerTeam;
    var nextRivalTeam = rivalTeam;
    final summoned = <Companion>{};

    while (summoned.length < count) {
      final beetleBlocked =
          nextBearerTeam.active.hasCompanion(Companion.beetle) ||
          nextRivalTeam.active.hasCompanion(Companion.beetle);
      final companion = _companionRandomizer.chooseFrom(
        Companion.values.where(
          (candidate) =>
              !summoned.contains(candidate) &&
              (candidate != Companion.beetle || !beetleBlocked),
        ),
      );
      if (companion == null) break;

      final result = _awardCompanion(
        winnerTeam: nextBearerTeam,
        loserTeam: nextRivalTeam,
        bearerIndex: bearerIndex,
        companion: companion,
      );
      if (!result.attached) break;
      summoned.add(companion);
      nextBearerTeam = result.winnerTeam;
      nextRivalTeam = result.loserTeam;
    }

    return (bearerTeam: nextBearerTeam, rivalTeam: nextRivalTeam);
  }
}

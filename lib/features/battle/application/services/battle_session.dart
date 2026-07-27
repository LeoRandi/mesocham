import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_state.dart';
import '../../domain/entities/battle_team.dart';
import '../../domain/entities/battle_turn.dart';
import '../../domain/services/ai_move_strategy.dart';
import '../../domain/services/battle_rules.dart';

class BattleSession {
  const BattleSession({
    required BattleRules rules,
    required AiMoveStrategy opponentStrategy,
  }) : _rules = rules,
       _opponentStrategy = opponentStrategy;

  final BattleRules _rules;
  final AiMoveStrategy _opponentStrategy;

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
      opponentGesture: _chooseOpponentMove(state),
    );
  }

  BattleState startSwap(BattleState state) {
    if (!state.canSwap) return state;

    return state.copyWith(
      phase: BattlePhase.swapping,
      clearLastResolution: true,
      clearPlayerGesture: true,
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
    return state.copyWith(playerGesture: gesture);
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
    return state.copyWith(
      phase: gameOver ? BattlePhase.gameOver : BattlePhase.command,
      clearPlayerGesture: true,
      clearOpponentGesture: true,
      clearLastResolution: true,
      clearPendingAction: true,
    );
  }

  BattleGesture _chooseOpponentMove(BattleState state) {
    return _opponentStrategy.chooseMove(
      self: state.opponent,
      opponent: state.player,
      previousTurn: state.previousTurn,
    );
  }

  BattleState _resolveShowdown(BattleState state) {
    final resolution = _rules.resolve(
      playerTeam: state.playerTeam,
      opponentTeam: state.opponentTeam,
      playerGesture: state.playerGesture!,
      opponentGesture: state.opponentGesture!,
    );

    return state.copyWith(
      playerTeam: resolution.playerTeam,
      opponentTeam: resolution.opponentTeam,
      lastResolution: resolution,
      previousTurn: BattleTurn(
        playerGesture: state.playerGesture!,
        opponentGesture: state.opponentGesture!,
        outcome: resolution.outcome,
      ),
      resolutionSequence: state.resolutionSequence + 1,
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
}

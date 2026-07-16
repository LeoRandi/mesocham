import 'dart:math' as math;

import '../entities/battle_gesture.dart';
import '../entities/battle_resolution.dart';
import '../entities/combatant.dart';

abstract interface class BattleRules {
  BattleResolution resolve({
    required Combatant player,
    required Combatant opponent,
    required BattleGesture playerGesture,
    required BattleGesture opponentGesture,
  });
}

class StandardBattleRules implements BattleRules {
  const StandardBattleRules();

  @override
  BattleResolution resolve({
    required Combatant player,
    required Combatant opponent,
    required BattleGesture playerGesture,
    required BattleGesture opponentGesture,
  }) {
    if (playerGesture == opponentGesture) {
      final strongestAttack = math.max(
        player.champion.attack,
        opponent.champion.attack,
      );
      final drawDamage = (strongestAttack / 2).ceil();
      final playerMove = player.champion.moveFor(playerGesture);
      final opponentMove = opponent.champion.moveFor(opponentGesture);

      return BattleResolution(
        outcome: BattleOutcome.draw,
        damageToPlayer: opponentMove.dealsFullDamageOnDraw
            ? opponent.champion.attack
            : drawDamage,
        damageToOpponent: playerMove.dealsFullDamageOnDraw
            ? player.champion.attack
            : drawDamage,
      );
    }

    if (_beats(playerGesture, opponentGesture)) {
      return BattleResolution(
        outcome: BattleOutcome.playerVictory,
        damageToPlayer: 0,
        damageToOpponent: player.champion.attack,
      );
    }

    return BattleResolution(
      outcome: BattleOutcome.opponentVictory,
      damageToPlayer: opponent.champion.attack,
      damageToOpponent: 0,
    );
  }

  bool _beats(BattleGesture first, BattleGesture second) {
    return switch (first) {
      BattleGesture.rock => second == BattleGesture.scissors,
      BattleGesture.paper => second == BattleGesture.rock,
      BattleGesture.scissors => second == BattleGesture.paper,
    };
  }
}

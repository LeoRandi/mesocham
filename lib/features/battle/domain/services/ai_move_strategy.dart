import 'dart:math' as math;

import '../entities/battle_gesture.dart';
import '../entities/battle_turn.dart';
import '../entities/combatant.dart';

abstract interface class AiMoveStrategy {
  BattleGesture chooseMove({
    required Combatant self,
    required Combatant opponent,
    required BattleTurn? previousTurn,
  });
}

class FossilRaceAiStrategy implements AiMoveStrategy {
  FossilRaceAiStrategy({math.Random? random})
    : _random = random ?? math.Random();

  final math.Random _random;

  @override
  BattleGesture chooseMove({
    required Combatant self,
    required Combatant opponent,
    required BattleTurn? previousTurn,
  }) {
    if (previousTurn == null) {
      return _randomGesture(BattleGesture.values);
    }

    return switch (previousTurn.outcome) {
      BattleOutcome.draw => _randomGesture(
        BattleGesture.values.where(
          (gesture) => gesture != previousTurn.opponentGesture,
        ),
      ),
      BattleOutcome.opponentVictory => previousTurn.opponentGesture,
      BattleOutcome.playerVictory => previousTurn.playerGesture.counterGesture,
    };
  }

  BattleGesture _randomGesture(Iterable<BattleGesture> candidates) {
    final gestures = candidates.toList(growable: false);
    return gestures[_random.nextInt(gestures.length)];
  }
}

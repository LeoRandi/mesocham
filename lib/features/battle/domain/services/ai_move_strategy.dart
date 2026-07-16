import '../entities/battle_gesture.dart';
import '../entities/combatant.dart';

abstract interface class AiMoveStrategy {
  BattleGesture chooseMove({
    required Combatant self,
    required Combatant opponent,
  });
}

class AlwaysRockAiStrategy implements AiMoveStrategy {
  const AlwaysRockAiStrategy();

  @override
  BattleGesture chooseMove({
    required Combatant self,
    required Combatant opponent,
  }) {
    return BattleGesture.rock;
  }
}

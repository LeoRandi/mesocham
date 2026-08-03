export '../../../champions/domain/entities/battle_gesture.dart';

enum BattlePhase {
  command,
  choosingMove,
  choosingSpeciesCard,
  resolving,
  swapping,
  gameOver,
}

enum BattleOutcome { playerVictory, opponentVictory, draw }

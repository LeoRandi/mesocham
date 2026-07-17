enum BattleGesture { rock, paper, scissors }

extension BattleGestureRules on BattleGesture {
  bool beats(BattleGesture other) => switch (this) {
    BattleGesture.rock => other == BattleGesture.scissors,
    BattleGesture.paper => other == BattleGesture.rock,
    BattleGesture.scissors => other == BattleGesture.paper,
  };

  BattleGesture get counterGesture => switch (this) {
    BattleGesture.rock => BattleGesture.paper,
    BattleGesture.paper => BattleGesture.scissors,
    BattleGesture.scissors => BattleGesture.rock,
  };
}

enum BattlePhase { command, choosingMove, resolving, gameOver }

enum BattleOutcome { playerVictory, opponentVictory, draw }

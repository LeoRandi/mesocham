import 'battle_gesture.dart';

class BattleTurn {
  const BattleTurn({
    required this.playerGesture,
    required this.opponentGesture,
    required this.outcome,
  });

  final BattleGesture playerGesture;
  final BattleGesture opponentGesture;
  final BattleOutcome outcome;
}

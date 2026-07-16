import 'battle_gesture.dart';

class BattleResolution {
  const BattleResolution({
    required this.outcome,
    required this.damageToPlayer,
    required this.damageToOpponent,
  });

  final BattleOutcome outcome;
  final int damageToPlayer;
  final int damageToOpponent;
}

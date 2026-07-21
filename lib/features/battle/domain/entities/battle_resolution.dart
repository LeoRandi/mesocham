import 'battle_gesture.dart';
import 'battle_team.dart';

class BattleResolution {
  const BattleResolution({
    required this.outcome,
    required this.damageToPlayer,
    required this.damageToOpponent,
    required this.playerTeam,
    required this.opponentTeam,
    this.healingToPlayer = 0,
    this.healingToOpponent = 0,
    this.reserveDamageToPlayer = 0,
    this.reserveDamageToOpponent = 0,
    this.playerSwapped = false,
    this.opponentSwapped = false,
  });

  final BattleOutcome outcome;
  final double damageToPlayer;
  final double damageToOpponent;
  final BattleTeam playerTeam;
  final BattleTeam opponentTeam;
  final double healingToPlayer;
  final double healingToOpponent;
  final double reserveDamageToPlayer;
  final double reserveDamageToOpponent;
  final bool playerSwapped;
  final bool opponentSwapped;
}

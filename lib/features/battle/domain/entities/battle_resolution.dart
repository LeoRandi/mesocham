import 'battle_gesture.dart';
import 'battle_effect_event.dart';
import 'battle_team.dart';

class BattleResolution {
  BattleResolution({
    required this.outcome,
    required this.damageToPlayer,
    required this.damageToOpponent,
    required this.playerTeam,
    required this.opponentTeam,
    List<int> damagedPlayerIndexes = const [],
    List<int> damagedOpponentIndexes = const [],
    this.healingToPlayer = 0,
    this.healingToOpponent = 0,
    this.reserveDamageToPlayer = 0,
    this.reserveDamageToOpponent = 0,
    this.playerSwapped = false,
    this.opponentSwapped = false,
    List<BattleEffectEvent> effectEvents = const [],
  }) : damagedPlayerIndexes = List.unmodifiable(damagedPlayerIndexes),
       effectEvents = List.unmodifiable(effectEvents),
       damagedOpponentIndexes = List.unmodifiable(damagedOpponentIndexes);

  final BattleOutcome outcome;
  final double damageToPlayer;
  final double damageToOpponent;
  final BattleTeam playerTeam;
  final BattleTeam opponentTeam;
  final List<int> damagedPlayerIndexes;
  final List<int> damagedOpponentIndexes;
  final double healingToPlayer;
  final double healingToOpponent;
  final double reserveDamageToPlayer;
  final double reserveDamageToOpponent;
  final bool playerSwapped;
  final bool opponentSwapped;
  final List<BattleEffectEvent> effectEvents;

  BattleResolution copyWith({
    BattleTeam? playerTeam,
    BattleTeam? opponentTeam,
  }) {
    return BattleResolution(
      outcome: outcome,
      damageToPlayer: damageToPlayer,
      damageToOpponent: damageToOpponent,
      playerTeam: playerTeam ?? this.playerTeam,
      opponentTeam: opponentTeam ?? this.opponentTeam,
      damagedPlayerIndexes: damagedPlayerIndexes,
      damagedOpponentIndexes: damagedOpponentIndexes,
      healingToPlayer: healingToPlayer,
      healingToOpponent: healingToOpponent,
      reserveDamageToPlayer: reserveDamageToPlayer,
      reserveDamageToOpponent: reserveDamageToOpponent,
      playerSwapped: playerSwapped,
      opponentSwapped: opponentSwapped,
      effectEvents: effectEvents,
    );
  }
}

import 'battle_gesture.dart';
import 'status_effect.dart';

enum MoveEffect {
  none,
  damage,
  drainHealth,
  healSelf,
  healTeam,
  damageTeam,
  damageReserve,
  damageReserveAndPromote,
  forceOpponentSwap,
  swapSelf,
  recklessDamage,
}

enum CompanionMoveEffect { none, summonRandom, stealRandom, transferOnSwap }

class ChampionMove {
  ChampionMove({
    required this.name,
    required this.gesture,
    required this.potency,
    required this.effect,
    required this.description,
    List<StatusApplication> statusApplications = const [],
    this.effectTurns = 0,
    this.isCritical = false,
    this.dealsFullDamageOnDraw = false,
    this.selfHealing = 0,
    this.selfDamage = 0,
    this.bonusPotencyIfTargetSwapped = 0,
    this.cleansesHarmfulStatuses = false,
    this.companionEffect = CompanionMoveEffect.none,
  }) : statusApplications = List.unmodifiable(statusApplications);

  final String name;
  final BattleGesture gesture;
  final double potency;
  final MoveEffect effect;
  final String description;
  final List<StatusApplication> statusApplications;
  final int effectTurns;
  final bool isCritical;
  final bool dealsFullDamageOnDraw;
  final double selfHealing;
  final double selfDamage;
  final double bonusPotencyIfTargetSwapped;
  final bool cleansesHarmfulStatuses;
  final CompanionMoveEffect companionEffect;
}

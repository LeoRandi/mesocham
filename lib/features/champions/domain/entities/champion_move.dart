import 'battle_gesture.dart';
import 'status_effect.dart';

enum MoveEffect {
  none,
  damage,
  drainHealth,
  healSelf,
  healTeam,
  healTeamAndRedistributeHealth,
  damageTeam,
  damageActiveAndReserves,
  damageActiveAndRandomReserves,
  damageReserve,
  damageReserveAndPromote,
  damageSwapOpponentAndDamage,
  forceOpponentSwap,
  swapSelf,
  damageTeamAndSwapSelf,
  mixedChoice,
  recklessDamage,
}

enum MixedMoveChoice { falseEvolution, arborealVersatility }

enum CompanionMoveEffect {
  none,
  summonRandom,
  stealRandom,
  transferOnSwap,
  sacrificeRandom,
}

class ChampionMove {
  ChampionMove({
    required this.name,
    required this.gesture,
    required this.potency,
    required this.effect,
    required this.description,
    List<StatusApplication> statusApplications = const [],
    this.reservePotency = 0,
    this.followUpPotency = 0,
    this.effectTurns = 0,
    this.isCritical = false,
    this.dealsFullDamageOnDraw = false,
    this.selfHealing = 0,
    this.selfDamage = 0,
    this.bonusPotencyIfTargetSwapped = 0,
    this.bonusPotencyIfTargetBleeding = 0,
    this.bonusPotencyPerRoundWithoutWinning = 0,
    this.bonusPotencyIfAtOrBelowHalfHealth = 0,
    this.maxHealthGrowth = 0,
    this.cleansesHarmfulStatuses = false,
    this.transfersHarmfulStatusesToOpponent = false,
    this.companionEffect = CompanionMoveEffect.none,
    this.randomHarmfulStatusCount = 0,
    this.randomBeneficialStatusCount = 0,
    this.clearsOpponentCompanions = false,
    this.mixedMoveChoice = MixedMoveChoice.falseEvolution,
  }) : statusApplications = List.unmodifiable(statusApplications);

  final String name;
  final BattleGesture gesture;
  final double potency;
  final MoveEffect effect;
  final String description;
  final List<StatusApplication> statusApplications;
  final double reservePotency;
  final double followUpPotency;
  final int effectTurns;
  final bool isCritical;
  final bool dealsFullDamageOnDraw;
  final double selfHealing;
  final double selfDamage;
  final double bonusPotencyIfTargetSwapped;
  final double bonusPotencyIfTargetBleeding;
  final double bonusPotencyPerRoundWithoutWinning;
  final double bonusPotencyIfAtOrBelowHalfHealth;
  final double maxHealthGrowth;
  final bool cleansesHarmfulStatuses;
  final bool transfersHarmfulStatusesToOpponent;
  final CompanionMoveEffect companionEffect;
  final int randomHarmfulStatusCount;
  final int randomBeneficialStatusCount;
  final bool clearsOpponentCompanions;
  final MixedMoveChoice mixedMoveChoice;
}

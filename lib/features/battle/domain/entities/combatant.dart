import 'dart:math' as math;

import '../../../champions/domain/entities/champion.dart';
import '../../../companions/domain/entities/companion.dart';
import '../../../species_cards/domain/entities/species_card.dart';
import 'battle_status.dart';

class Combatant {
  Combatant({
    required this.champion,
    required this.currentHealth,
    this.maxHealthPenalty = 0,
    List<StatusCondition> statuses = const [],
    List<Companion> companions = const [],
    this.equippedSpeciesCard,
  }) : statuses = List.unmodifiable(statuses),
       companions = List.unmodifiable(companions);

  factory Combatant.fresh(Champion champion) {
    return Combatant(
      champion: champion,
      currentHealth: champion.maxHealth.toDouble(),
    );
  }

  final Champion champion;
  final double currentHealth;
  final double maxHealthPenalty;
  final List<StatusCondition> statuses;
  final List<Companion> companions;
  final SpeciesCard? equippedSpeciesCard;

  bool get isDefeated => currentHealth <= 0;
  int companionCount(Companion companion) =>
      companions.where((owned) => owned == companion).length;
  double get companionEffectMultiplier =>
      math.pow(2, companionCount(Companion.beetle)).toDouble();
  double get companionMaxHealthBonus =>
      companionValue(20.0 * companionCount(Companion.ammonoidea));
  double get baseMaxHealth => champion.maxHealth + companionMaxHealthBonus;
  double get maxHealth =>
      (baseMaxHealth - maxHealthPenalty).clamp(1, baseMaxHealth).toDouble();

  double companionValue(double baseValue) =>
      baseValue * companionEffectMultiplier;

  Combatant takeDamage(double damage) {
    final percentageMitigatedDamage =
        damage * (equippedSpeciesCard == SpeciesCard.armoredBeast ? 0.67 : 1);
    final flatReduction = companionValue(
      10.0 * companionCount(Companion.horseshoeCrab),
    );
    final mitigatedDamage = math.max(
      0,
      percentageMitigatedDamage - flatReduction,
    );
    final nextHealth = (currentHealth - mitigatedDamage)
        .clamp(0, maxHealth)
        .toDouble();

    return copyWith(
      currentHealth: nextHealth,
      companions: nextHealth <= 0 ? const [] : companions,
      clearEquippedSpeciesCard: nextHealth <= 0,
    );
  }

  Combatant heal(double amount) {
    return copyWith(
      currentHealth: (currentHealth + amount).clamp(0, maxHealth).toDouble(),
    );
  }

  Combatant reduceMaxHealth(double amount) {
    final nextPenalty = (maxHealthPenalty + amount)
        .clamp(0, baseMaxHealth - 1)
        .toDouble();
    final nextMaxHealth = (baseMaxHealth - nextPenalty)
        .clamp(1, baseMaxHealth)
        .toDouble();
    return copyWith(
      currentHealth: currentHealth.clamp(0, nextMaxHealth).toDouble(),
      maxHealthPenalty: nextPenalty,
    );
  }

  Combatant applyStatus(
    StatusApplication application, {
    bool fromEnemyChampion = false,
  }) {
    if (application.type.isHarmful &&
        (hasStatus(StatusType.secondaryImmunity) ||
            (fromEnemyChampion && hasCompanion(Companion.simosuchus)))) {
      return this;
    }

    final nextStatuses = [...statuses];
    final existingIndex = nextStatuses.indexWhere(
      (status) => status.type == application.type,
    );
    if (existingIndex == -1) {
      nextStatuses.add(
        StatusCondition(
          type: application.type,
          stacks: application.stacks,
          remainingTurns: application.resolvedDurationTurns,
          justApplied: application.delayFirstTick,
        ),
      );
    } else {
      nextStatuses[existingIndex] = nextStatuses[existingIndex].apply(
        application,
      );
    }
    return copyWith(statuses: nextStatuses);
  }

  Combatant removeStatus(StatusType type) {
    return copyWith(
      statuses: [
        for (final status in statuses)
          if (status.type != type) status,
      ],
    );
  }

  Combatant clearStatuses() => copyWith(statuses: const []);

  Combatant clearHarmfulStatuses() {
    return copyWith(
      statuses: [
        for (final status in statuses)
          if (!status.type.isHarmful) status,
      ],
    );
  }

  Combatant equipSpeciesCard(SpeciesCard card) {
    if (isDefeated || equippedSpeciesCard != null) return this;
    return copyWith(equippedSpeciesCard: card);
  }

  Combatant addCompanion(
    Companion companion, {
    bool activateEffectsImmediately = true,
  }) {
    var nextCombatant = copyWith(companions: [...companions, companion]);
    final gainedMaxHealth = math.max(0.0, nextCombatant.maxHealth - maxHealth);
    if (!isDefeated && gainedMaxHealth > 0) {
      nextCombatant = nextCombatant.heal(gainedMaxHealth);
    }
    if (companion == Companion.henodus && activateEffectsImmediately) {
      nextCombatant = nextCombatant.applyStatus(
        const StatusApplication(
          type: StatusType.jaggedScales,
          target: StatusTarget.self,
        ),
      );
    }
    return nextCombatant;
  }

  Combatant removeCompanion(Companion companion) {
    final companionIndex = companions.indexOf(companion);
    if (companionIndex == -1) return this;
    final nextCompanions = [...companions]..removeAt(companionIndex);
    final nextBaseMaxHealth =
        champion.maxHealth +
        (_companionBonus(nextCompanions, Companion.ammonoidea, 20));
    final nextPenalty = maxHealthPenalty
        .clamp(0, nextBaseMaxHealth - 1)
        .toDouble();
    final nextMaxHealth = (nextBaseMaxHealth - nextPenalty)
        .clamp(1, nextBaseMaxHealth)
        .toDouble();
    final lostMaxHealth = math.max(0.0, maxHealth - nextMaxHealth);
    return copyWith(
      companions: nextCompanions,
      maxHealthPenalty: nextPenalty,
      currentHealth: (currentHealth - lostMaxHealth)
          .clamp(0, nextMaxHealth)
          .toDouble(),
    );
  }

  Combatant removeAllCompanions() {
    var nextCombatant = this;
    for (final companion in companions) {
      nextCombatant = nextCombatant.removeCompanion(companion);
    }
    return nextCombatant;
  }

  Combatant tickStatuses() {
    var nextCombatant = this;
    final nextStatuses = <StatusCondition>[];

    for (final status in statuses) {
      if (status.justApplied) {
        final tickedStatus = status.tick();
        if (!tickedStatus.isExpired) nextStatuses.add(tickedStatus);
        continue;
      }

      if (status.type == StatusType.bleeding) {
        nextCombatant = nextCombatant.takeDamage(
          nextCombatant.maxHealth * 0.05 * status.stacks,
        );
      } else if (status.type == StatusType.famine) {
        nextCombatant = nextCombatant.reduceMaxHealth(10.0 * status.stacks);
      }

      final tickedStatus = status.tick();
      if (!tickedStatus.isExpired) nextStatuses.add(tickedStatus);
    }

    if (hasCompanion(Companion.henodus)) {
      final jaggedIndex = nextStatuses.indexWhere(
        (status) => status.type == StatusType.jaggedScales,
      );
      const reappliedJaggedScales = StatusCondition(
        type: StatusType.jaggedScales,
        remainingTurns: 3,
      );
      if (jaggedIndex == -1) {
        nextStatuses.add(reappliedJaggedScales);
      } else {
        nextStatuses[jaggedIndex] = reappliedJaggedScales;
      }
    }

    return nextCombatant.copyWith(statuses: nextStatuses);
  }

  bool hasCompanion(Companion companion) => companions.contains(companion);

  bool hasStatus(StatusType type) {
    return statuses.any((status) => status.type == type);
  }

  StatusCondition? statusOf(StatusType type) {
    for (final status in statuses) {
      if (status.type == type) return status;
    }
    return null;
  }

  Combatant copyWith({
    double? currentHealth,
    double? maxHealthPenalty,
    List<StatusCondition>? statuses,
    List<Companion>? companions,
    SpeciesCard? equippedSpeciesCard,
    bool clearEquippedSpeciesCard = false,
  }) {
    return Combatant(
      champion: champion,
      currentHealth: currentHealth ?? this.currentHealth,
      maxHealthPenalty: maxHealthPenalty ?? this.maxHealthPenalty,
      statuses: statuses ?? this.statuses,
      companions: companions ?? this.companions,
      equippedSpeciesCard: clearEquippedSpeciesCard
          ? null
          : equippedSpeciesCard ?? this.equippedSpeciesCard,
    );
  }

  static double _companionBonus(
    List<Companion> companions,
    Companion companion,
    double baseValue,
  ) {
    final count = companions.where((owned) => owned == companion).length;
    final beetleCount = companions
        .where((owned) => owned == Companion.beetle)
        .length;
    return baseValue * count * math.pow(2, beetleCount);
  }
}

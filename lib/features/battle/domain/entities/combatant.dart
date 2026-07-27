import '../../../champions/domain/entities/champion.dart';
import '../../../species_cards/domain/entities/species_card.dart';
import 'battle_status.dart';

class Combatant {
  Combatant({
    required this.champion,
    required this.currentHealth,
    this.maxHealthPenalty = 0,
    List<StatusCondition> statuses = const [],
    this.equippedSpeciesCard,
  }) : statuses = List.unmodifiable(statuses);

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
  final SpeciesCard? equippedSpeciesCard;

  bool get isDefeated => currentHealth <= 0;
  double get maxHealth => (champion.maxHealth - maxHealthPenalty)
      .clamp(1, champion.maxHealth)
      .toDouble();

  Combatant takeDamage(double damage) {
    final mitigatedDamage =
        damage * (equippedSpeciesCard == SpeciesCard.armoredBeast ? 0.67 : 1);
    final nextHealth = (currentHealth - mitigatedDamage)
        .clamp(0, maxHealth)
        .toDouble();

    return Combatant(
      champion: champion,
      currentHealth: nextHealth,
      maxHealthPenalty: maxHealthPenalty,
      statuses: statuses,
      equippedSpeciesCard: nextHealth <= 0 ? null : equippedSpeciesCard,
    );
  }

  Combatant heal(double amount) {
    return Combatant(
      champion: champion,
      currentHealth: (currentHealth + amount).clamp(0, maxHealth).toDouble(),
      maxHealthPenalty: maxHealthPenalty,
      statuses: statuses,
      equippedSpeciesCard: equippedSpeciesCard,
    );
  }

  Combatant reduceMaxHealth(double amount) {
    final nextPenalty = (maxHealthPenalty + amount)
        .clamp(0, champion.maxHealth - 1)
        .toDouble();
    final nextMaxHealth = (champion.maxHealth - nextPenalty)
        .clamp(1, champion.maxHealth)
        .toDouble();

    return Combatant(
      champion: champion,
      currentHealth: currentHealth.clamp(0, nextMaxHealth).toDouble(),
      maxHealthPenalty: nextPenalty,
      statuses: statuses,
      equippedSpeciesCard: equippedSpeciesCard,
    );
  }

  Combatant applyStatus(StatusApplication application) {
    if (application.type.isHarmful && hasStatus(StatusType.secondaryImmunity)) {
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
          justApplied: true,
        ),
      );
    } else {
      nextStatuses[existingIndex] = nextStatuses[existingIndex].apply(
        application,
      );
    }

    return Combatant(
      champion: champion,
      currentHealth: currentHealth,
      maxHealthPenalty: maxHealthPenalty,
      statuses: nextStatuses,
      equippedSpeciesCard: equippedSpeciesCard,
    );
  }

  Combatant removeStatus(StatusType type) {
    return Combatant(
      champion: champion,
      currentHealth: currentHealth,
      maxHealthPenalty: maxHealthPenalty,
      statuses: [
        for (final status in statuses)
          if (status.type != type) status,
      ],
      equippedSpeciesCard: equippedSpeciesCard,
    );
  }

  Combatant clearStatuses() {
    return Combatant(
      champion: champion,
      currentHealth: currentHealth,
      maxHealthPenalty: maxHealthPenalty,
      equippedSpeciesCard: equippedSpeciesCard,
    );
  }

  Combatant clearHarmfulStatuses() {
    return Combatant(
      champion: champion,
      currentHealth: currentHealth,
      maxHealthPenalty: maxHealthPenalty,
      statuses: [
        for (final status in statuses)
          if (!status.type.isHarmful) status,
      ],
      equippedSpeciesCard: equippedSpeciesCard,
    );
  }

  Combatant equipSpeciesCard(SpeciesCard card) {
    if (isDefeated || equippedSpeciesCard != null) {
      return this;
    }

    return Combatant(
      champion: champion,
      currentHealth: currentHealth,
      maxHealthPenalty: maxHealthPenalty,
      statuses: statuses,
      equippedSpeciesCard: card,
    );
  }

  Combatant tickStatuses() {
    var nextCombatant = this;
    final nextStatuses = <StatusCondition>[];

    for (final status in statuses) {
      if (status.justApplied) {
        final tickedStatus = status.tick();
        if (!tickedStatus.isExpired) {
          nextStatuses.add(tickedStatus);
        }
        continue;
      }

      if (status.type == StatusType.bleeding) {
        nextCombatant = nextCombatant.takeDamage(
          nextCombatant.maxHealth * 0.05 * status.stacks,
        );
      } else if (status.type == StatusType.famine) {
        nextCombatant = nextCombatant.reduceMaxHealth(10);
      }

      final tickedStatus = status.tick();
      if (!tickedStatus.isExpired) {
        nextStatuses.add(tickedStatus);
      }
    }

    return Combatant(
      champion: champion,
      currentHealth: nextCombatant.currentHealth,
      maxHealthPenalty: nextCombatant.maxHealthPenalty,
      statuses: nextStatuses,
      equippedSpeciesCard: nextCombatant.equippedSpeciesCard,
    );
  }

  bool hasStatus(StatusType type) {
    return statuses.any((status) => status.type == type);
  }

  StatusCondition? statusOf(StatusType type) {
    for (final status in statuses) {
      if (status.type == type) return status;
    }
    return null;
  }
}

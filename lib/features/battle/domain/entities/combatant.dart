import 'battle_status.dart';
import 'champion.dart';

class Combatant {
  const Combatant({
    required this.champion,
    required this.currentHealth,
    this.maxHealthPenalty = 0,
    this.statuses = const [],
  });

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

  bool get isDefeated => currentHealth <= 0;
  double get maxHealth => (champion.maxHealth - maxHealthPenalty)
      .clamp(1, champion.maxHealth)
      .toDouble();

  Combatant takeDamage(double damage) {
    return Combatant(
      champion: champion,
      currentHealth: (currentHealth - damage).clamp(0, maxHealth).toDouble(),
      maxHealthPenalty: maxHealthPenalty,
      statuses: statuses,
    );
  }

  Combatant heal(double amount) {
    return Combatant(
      champion: champion,
      currentHealth: (currentHealth + amount).clamp(0, maxHealth).toDouble(),
      maxHealthPenalty: maxHealthPenalty,
      statuses: statuses,
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
    );
  }

  Combatant applyStatus(StatusApplication application) {
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
    );
  }

  Combatant clearStatuses() {
    return Combatant(
      champion: champion,
      currentHealth: currentHealth,
      maxHealthPenalty: maxHealthPenalty,
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

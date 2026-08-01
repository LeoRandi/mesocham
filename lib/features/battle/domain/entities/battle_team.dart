import '../../../champions/domain/entities/champion.dart';
import '../../../companions/domain/entities/companion.dart';
import '../../../species_cards/domain/entities/species_card.dart';
import 'battle_species_card_slot.dart';
import 'battle_status.dart';
import 'combatant.dart';

class BattleTeam {
  BattleTeam({
    required List<Combatant> combatants,
    this.activeIndex = 0,
    List<BattleSpeciesCardSlot>? speciesCardSlots,
  }) : combatants = List.unmodifiable(combatants),
       speciesCardSlots = List.unmodifiable(
         speciesCardSlots ??
             [
               for (final combatant in combatants)
                 BattleSpeciesCardSlot(
                   card: SpeciesCard.forChampionType(combatant.champion.type),
                 ),
             ],
       ) {
    if (combatants.length != 3) {
      throw ArgumentError.value(
        combatants.length,
        'combatants',
        'Each team needs exactly 3 champions.',
      );
    }
    if (activeIndex < 0 || activeIndex >= combatants.length) {
      throw RangeError.range(
        activeIndex,
        0,
        combatants.length - 1,
        'activeIndex',
      );
    }
    if (this.speciesCardSlots.length != combatants.length) {
      throw ArgumentError.value(
        this.speciesCardSlots.length,
        'speciesCardSlots',
        'Each champion must contribute exactly one species card.',
      );
    }

    final bearerIndexes = <int>{};
    for (final slot in this.speciesCardSlots) {
      final bearerIndex = slot.bearerIndex;
      if ((!slot.consumed && bearerIndex != null) ||
          (bearerIndex != null &&
              (bearerIndex < 0 || bearerIndex >= combatants.length)) ||
          (bearerIndex != null && !bearerIndexes.add(bearerIndex)) ||
          (bearerIndex != null &&
              combatants[bearerIndex].equippedSpeciesCard != slot.card)) {
        throw ArgumentError.value(
          this.speciesCardSlots,
          'speciesCardSlots',
          'Species-card consumption and bearer assignments are invalid.',
        );
      }
    }
    for (var index = 0; index < combatants.length; index++) {
      if (combatants[index].equippedSpeciesCard != null &&
          !this.speciesCardSlots.any(
            (slot) =>
                slot.bearerIndex == index &&
                slot.card == combatants[index].equippedSpeciesCard,
          )) {
        throw ArgumentError.value(
          combatants,
          'combatants',
          'Every equipped species card must belong to a consumed team slot.',
        );
      }
    }
  }

  factory BattleTeam.fresh(List<Champion> champions) {
    return BattleTeam(
      combatants: [for (final champion in champions) Combatant.fresh(champion)],
    );
  }

  final List<Combatant> combatants;
  final List<BattleSpeciesCardSlot> speciesCardSlots;
  final int activeIndex;

  Combatant get active => combatants[activeIndex];
  bool get isDefeated => combatants.every((combatant) => combatant.isDefeated);

  List<int> get swapIndexes {
    if (!active.isDefeated &&
        active.hasStatus(StatusType.groundedRegeneration)) {
      return const [];
    }
    return [
      for (var index = 0; index < combatants.length; index++)
        if (index != activeIndex && !combatants[index].isDefeated) index,
    ];
  }

  int? get firstReserveIndex {
    for (final index in swapIndexes) {
      return index;
    }
    return null;
  }

  BattleTeam replaceCombatant(int index, Combatant combatant) {
    final nextCombatants = [...combatants];
    nextCombatants[index] = combatant;
    return BattleTeam(
      combatants: nextCombatants,
      activeIndex: activeIndex,
      speciesCardSlots: _slotsAfterCombatantChanges(nextCombatants),
    );
  }

  BattleTeam replaceActive(Combatant combatant) {
    return replaceCombatant(activeIndex, combatant);
  }

  BattleTeam damageActive(double amount) {
    return replaceActive(active.takeDamage(amount));
  }

  BattleTeam healActive(double amount) {
    return replaceActive(active.heal(amount));
  }

  BattleTeam growActiveMaxHealthOnce(double amount) {
    return replaceActive(active.growMaxHealthOnce(amount));
  }

  BattleTeam healCombatant(int index, double amount) {
    if (index < 0 ||
        index >= combatants.length ||
        combatants[index].isDefeated) {
      return this;
    }
    return replaceCombatant(index, combatants[index].heal(amount));
  }

  BattleTeam damageAll(double amount) {
    final nextCombatants = [
      for (final combatant in combatants) combatant.takeDamage(amount),
    ];
    return BattleTeam(
      combatants: nextCombatants,
      activeIndex: activeIndex,
      speciesCardSlots: _slotsAfterCombatantChanges(nextCombatants),
    );
  }

  BattleTeam healAll(double amount) {
    return BattleTeam(
      combatants: [for (final combatant in combatants) combatant.heal(amount)],
      activeIndex: activeIndex,
      speciesCardSlots: speciesCardSlots,
    );
  }

  BattleTeam redistributeCurrentHealthEvenly() {
    final survivingIndexes = [
      for (var index = 0; index < combatants.length; index++)
        if (!combatants[index].isDefeated) index,
    ];
    if (survivingIndexes.length < 2) return this;

    var remainingHealth = survivingIndexes.fold<double>(
      0,
      (total, index) => total + combatants[index].currentHealth,
    );
    final pendingIndexes = [...survivingIndexes];
    final allocations = <int, double>{};

    while (pendingIndexes.isNotEmpty) {
      final evenShare = remainingHealth / pendingIndexes.length;
      final cappedIndexes = [
        for (final index in pendingIndexes)
          if (combatants[index].maxHealth <= evenShare) index,
      ];
      if (cappedIndexes.isEmpty) {
        for (final index in pendingIndexes) {
          allocations[index] = evenShare;
        }
        break;
      }
      for (final index in cappedIndexes) {
        final allocation = combatants[index].maxHealth;
        allocations[index] = allocation;
        remainingHealth -= allocation;
        pendingIndexes.remove(index);
      }
    }

    final nextCombatants = [...combatants];
    for (final entry in allocations.entries) {
      nextCombatants[entry.key] = nextCombatants[entry.key].copyWith(
        currentHealth: entry.value,
      );
    }
    return BattleTeam(
      combatants: nextCombatants,
      activeIndex: activeIndex,
      speciesCardSlots: speciesCardSlots,
    );
  }

  BattleTeam damageFirstReserve(double amount) {
    final targetIndex = firstReserveIndex;
    return targetIndex == null
        ? damageActive(amount)
        : replaceCombatant(
            targetIndex,
            combatants[targetIndex].takeDamage(amount),
          );
  }

  BattleTeam applyStatusToActive(StatusApplication application) {
    return replaceActive(active.applyStatus(application));
  }

  BattleTeam applyStatusToIndex(int index, StatusApplication application) {
    return replaceCombatant(index, combatants[index].applyStatus(application));
  }

  BattleTeam applyStatusToAll(StatusApplication application) {
    return BattleTeam(
      combatants: [
        for (final combatant in combatants)
          combatant.isDefeated ? combatant : combatant.applyStatus(application),
      ],
      activeIndex: activeIndex,
      speciesCardSlots: speciesCardSlots,
    );
  }

  BattleTeam applyEnemyStatusToActive(StatusApplication application) {
    return replaceActive(
      active.applyStatus(application, fromEnemyChampion: true),
    );
  }

  BattleTeam applyEnemyStatusToIndex(int index, StatusApplication application) {
    return replaceCombatant(
      index,
      combatants[index].applyStatus(application, fromEnemyChampion: true),
    );
  }

  BattleTeam applyEnemyStatusToAll(StatusApplication application) {
    return BattleTeam(
      combatants: [
        for (final combatant in combatants)
          combatant.isDefeated
              ? combatant
              : combatant.applyStatus(application, fromEnemyChampion: true),
      ],
      activeIndex: activeIndex,
      speciesCardSlots: speciesCardSlots,
    );
  }

  BattleTeam removeStatusFromActive(StatusType type) {
    return replaceActive(active.removeStatus(type));
  }

  BattleTeam removeStatusFromIndex(int index, StatusType type) {
    return replaceCombatant(index, combatants[index].removeStatus(type));
  }

  BattleTeam clearHarmfulStatusesFromActive() {
    return replaceActive(active.clearHarmfulStatuses());
  }

  BattleTeam equipSpeciesCard({
    required int cardSlotIndex,
    required int bearerIndex,
  }) {
    if (cardSlotIndex < 0 ||
        cardSlotIndex >= speciesCardSlots.length ||
        bearerIndex < 0 ||
        bearerIndex >= combatants.length ||
        speciesCardSlots[cardSlotIndex].consumed ||
        combatants[bearerIndex].isDefeated ||
        combatants[bearerIndex].equippedSpeciesCard != null) {
      return this;
    }

    final nextCombatants = [...combatants];
    nextCombatants[bearerIndex] = nextCombatants[bearerIndex].equipSpeciesCard(
      speciesCardSlots[cardSlotIndex].card,
    );
    final nextSlots = [...speciesCardSlots];
    nextSlots[cardSlotIndex] = nextSlots[cardSlotIndex].equipTo(bearerIndex);
    return BattleTeam(
      combatants: nextCombatants,
      activeIndex: activeIndex,
      speciesCardSlots: nextSlots,
    );
  }

  BattleTeam addCompanion({
    required int bearerIndex,
    required Companion companion,
    bool activateEffectsImmediately = true,
  }) {
    if (bearerIndex < 0 ||
        bearerIndex >= combatants.length ||
        combatants[bearerIndex].isDefeated) {
      return this;
    }
    return replaceCombatant(
      bearerIndex,
      combatants[bearerIndex].addCompanion(
        companion,
        activateEffectsImmediately: activateEffectsImmediately,
      ),
    );
  }

  BattleTeam removeCompanion({
    required int bearerIndex,
    required Companion companion,
  }) {
    if (bearerIndex < 0 || bearerIndex >= combatants.length) return this;
    return replaceCombatant(
      bearerIndex,
      combatants[bearerIndex].removeCompanion(companion),
    );
  }

  BattleTeam removeAllCompanionsFromActive() {
    return replaceActive(active.removeAllCompanions());
  }

  BattleTeam transferCompanions({
    required int fromIndex,
    required int toIndex,
    bool activateEffectsImmediately = true,
  }) {
    if (fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= combatants.length ||
        toIndex < 0 ||
        toIndex >= combatants.length) {
      return this;
    }

    final transferredCompanions = combatants[fromIndex].companions;
    if (transferredCompanions.isEmpty) return this;

    final nextCombatants = [...combatants];
    nextCombatants[fromIndex] = nextCombatants[fromIndex].removeAllCompanions();
    for (final companion in transferredCompanions) {
      nextCombatants[toIndex] = nextCombatants[toIndex].addCompanion(
        companion,
        activateEffectsImmediately: activateEffectsImmediately,
      );
    }
    return BattleTeam(
      combatants: nextCombatants,
      activeIndex: activeIndex,
      speciesCardSlots: _slotsAfterCombatantChanges(nextCombatants),
    );
  }

  BattleTeam tickStatuses() {
    final nextCombatants = [
      for (final combatant in combatants) combatant.tickStatuses(),
    ];
    return BattleTeam(
      combatants: nextCombatants,
      activeIndex: activeIndex,
      speciesCardSlots: _slotsAfterCombatantChanges(nextCombatants),
    );
  }

  BattleTeam recordRoundForCombatant(int index, {required bool won}) {
    if (index < 0 || index >= combatants.length) return this;
    final combatant = combatants[index];
    final roundsWithoutWinning = index == activeIndex && !combatant.isDefeated
        ? (won ? 0 : combatant.roundsWithoutWinning + 1)
        : 0;
    return replaceCombatant(
      index,
      combatant.copyWith(roundsWithoutWinning: roundsWithoutWinning),
    );
  }

  BattleTeam swapTo(int index) {
    if (!swapIndexes.contains(index)) return this;
    final spikeEnclosureActive = active.hasStatus(StatusType.spikeEnclosure);
    final nextCombatants = [...combatants];
    nextCombatants[activeIndex] = active.clearStatuses().copyWith(
      roundsWithoutWinning: 0,
    );
    nextCombatants[index] = nextCombatants[index].copyWith(
      roundsWithoutWinning: 0,
    );
    if (spikeEnclosureActive) {
      nextCombatants[index] = nextCombatants[index].takeDamage(20);
    }
    final swappedTeam = BattleTeam(
      combatants: nextCombatants,
      activeIndex: index,
      speciesCardSlots: speciesCardSlots,
    );
    return swappedTeam.active.isDefeated
        ? swappedTeam.promoteIfActiveDefeated()
        : swappedTeam;
  }

  BattleTeam swapToFirstReserve() {
    final targetIndex = firstReserveIndex;
    return targetIndex == null ? this : swapTo(targetIndex);
  }

  BattleTeam promoteIfActiveDefeated() {
    if (!active.isDefeated) return this;
    return swapToFirstReserve();
  }

  List<BattleSpeciesCardSlot> _slotsAfterCombatantChanges(
    List<Combatant> nextCombatants,
  ) {
    return [
      for (final slot in speciesCardSlots)
        if (slot.bearerIndex != null &&
            nextCombatants[slot.bearerIndex!].equippedSpeciesCard == null)
          slot.clearBearer()
        else
          slot,
    ];
  }
}

import '../../../champions/domain/entities/champion.dart';
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

  List<int> get swapIndexes => [
    for (var index = 0; index < combatants.length; index++)
      if (index != activeIndex && !combatants[index].isDefeated) index,
  ];

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

  BattleTeam removeStatusFromActive(StatusType type) {
    return replaceActive(active.removeStatus(type));
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

  BattleTeam swapTo(int index) {
    if (!swapIndexes.contains(index)) return this;
    final nextCombatants = [...combatants];
    nextCombatants[activeIndex] = active.clearStatuses();
    return BattleTeam(
      combatants: nextCombatants,
      activeIndex: index,
      speciesCardSlots: speciesCardSlots,
    );
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

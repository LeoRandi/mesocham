import 'champion.dart';
import 'combatant.dart';
import 'battle_status.dart';

class BattleTeam {
  const BattleTeam({required this.combatants, this.activeIndex = 0})
    : assert(combatants.length == 3, 'Each team needs exactly 3 champions.'),
      assert(activeIndex >= 0 && activeIndex < 3);

  factory BattleTeam.fresh(List<Champion> champions) {
    return BattleTeam(
      combatants: [for (final champion in champions) Combatant.fresh(champion)],
    );
  }

  final List<Combatant> combatants;
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
    return BattleTeam(combatants: nextCombatants, activeIndex: activeIndex);
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
    return BattleTeam(
      combatants: [
        for (final combatant in combatants) combatant.takeDamage(amount),
      ],
      activeIndex: activeIndex,
    );
  }

  BattleTeam healAll(double amount) {
    return BattleTeam(
      combatants: [for (final combatant in combatants) combatant.heal(amount)],
      activeIndex: activeIndex,
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

  BattleTeam tickStatuses() {
    return BattleTeam(
      combatants: [
        for (final combatant in combatants) combatant.tickStatuses(),
      ],
      activeIndex: activeIndex,
    );
  }

  BattleTeam swapTo(int index) {
    if (!swapIndexes.contains(index)) return this;
    final nextCombatants = [...combatants];
    nextCombatants[activeIndex] = active.clearStatuses();
    return BattleTeam(combatants: nextCombatants, activeIndex: index);
  }

  BattleTeam swapToFirstReserve() {
    final targetIndex = firstReserveIndex;
    return targetIndex == null ? this : swapTo(targetIndex);
  }

  BattleTeam promoteIfActiveDefeated() {
    if (!active.isDefeated) return this;
    return swapToFirstReserve();
  }
}

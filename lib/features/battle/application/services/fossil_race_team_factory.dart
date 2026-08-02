import 'dart:math' as math;

import '../../../champions/domain/entities/champion.dart';
import '../../../champions/domain/repositories/champion_catalog.dart';
import '../../domain/entities/battle_team.dart';

class FossilRaceTeams {
  const FossilRaceTeams({required this.playerTeam, required this.opponentTeam});

  final BattleTeam playerTeam;
  final BattleTeam opponentTeam;
}

class FossilRaceTeamFactory {
  FossilRaceTeamFactory({required ChampionCatalog catalog, math.Random? random})
    : _catalog = catalog,
      _random = random ?? math.Random();

  static const teamSize = 3;

  final ChampionCatalog _catalog;
  final math.Random _random;

  FossilRaceTeams create(
    Map<String, int> ownedChampionCounts, {
    List<String>? playerChampionIds,
  }) {
    final ownedChampions = <Champion, int>{
      for (final entry in ownedChampionCounts.entries)
        if (entry.value > 0)
          if (_catalog.championById(entry.key) case final champion?)
            champion: entry.value,
    };
    if (ownedChampions.isEmpty) {
      throw StateError(
        'A Fossil Race team requires at least one unlocked champion.',
      );
    }
    if (_catalog.champions.isEmpty) {
      throw StateError('The champion catalog cannot be empty.');
    }

    final playerChampions = playerChampionIds == null
        ? _createRandomPlayerTeam(ownedChampions)
        : _createSavedPlayerTeam(playerChampionIds, ownedChampionCounts);

    // CPU slots are independent uniform selections from the entire catalog.
    final opponentChampions = List.generate(
      teamSize,
      (_) => _catalog.champions[_random.nextInt(_catalog.champions.length)],
      growable: false,
    );

    return FossilRaceTeams(
      playerTeam: BattleTeam.fresh(playerChampions),
      opponentTeam: BattleTeam.fresh(opponentChampions),
    );
  }

  List<Champion> _createSavedPlayerTeam(
    List<String> championIds,
    Map<String, int> ownedChampionCounts,
  ) {
    if (championIds.length != teamSize) {
      throw StateError('A saved Fossil Race deck requires 3 champions.');
    }

    final usedCopies = <String, int>{};
    final champions = <Champion>[];
    for (final championId in championIds) {
      final champion = _catalog.championById(championId);
      if (champion == null) {
        throw StateError('Saved deck champion "$championId" does not exist.');
      }
      final nextUsedCount = (usedCopies[championId] ?? 0) + 1;
      if (nextUsedCount > (ownedChampionCounts[championId] ?? 0)) {
        throw StateError(
          'The saved deck uses unavailable copies of ${champion.name}.',
        );
      }
      usedCopies[championId] = nextUsedCount;
      champions.add(champion);
    }
    return champions;
  }

  List<Champion> _createRandomPlayerTeam(Map<Champion, int> ownedChampions) {
    final remainingCopies = Map<Champion, int>.of(ownedChampions);
    final playerChampions = <Champion>[];
    while (playerChampions.length < teamSize && remainingCopies.isNotEmpty) {
      final totalCopies = remainingCopies.values.fold<int>(
        0,
        (total, count) => total + count,
      );
      var selectedCopy = _random.nextInt(totalCopies);
      Champion? selectedChampion;

      for (final entry in remainingCopies.entries) {
        if (selectedCopy < entry.value) {
          selectedChampion = entry.key;
          break;
        }
        selectedCopy -= entry.value;
      }

      final champion = selectedChampion!;
      playerChampions.add(champion);
      final copiesLeft = remainingCopies[champion]! - 1;
      if (copiesLeft == 0) {
        remainingCopies.remove(champion);
      } else {
        remainingCopies[champion] = copiesLeft;
      }
    }

    // Profiles created before three-copy starters may have fewer than three
    // saved cards. Keep those saves playable while respecting unlocked IDs.
    final unlockedChampions = ownedChampions.keys.toList(growable: false);
    while (playerChampions.length < teamSize) {
      playerChampions.add(
        unlockedChampions[_random.nextInt(unlockedChampions.length)],
      );
    }
    return playerChampions;
  }
}

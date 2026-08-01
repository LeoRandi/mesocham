import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/champion.dart';
import '../../domain/entities/champion_definition.dart';
import '../../domain/entities/champion_move.dart';
import '../../domain/repositories/champion_catalog.dart';
import 'champion_critical_move_definitions.dart';
import 'champion_definitions.dart';
import 'champion_type_presets.dart';

class LocalChampionCatalog implements ChampionCatalog {
  LocalChampionCatalog() {
    definitions = List.unmodifiable(ChampionDefinitions.all);
    _definitionsById = Map.unmodifiable({
      for (final definition in definitions) definition.id: definition,
    });
    _championsById = Map.unmodifiable({
      for (final definition in definitions)
        definition.id: _buildChampion(definition),
    });
    champions = List.unmodifiable([
      for (final definition in definitions) _championsById[definition.id]!,
    ]);
  }

  @override
  late final List<ChampionDefinition> definitions;

  @override
  late final List<Champion> champions;

  late final Map<String, ChampionDefinition> _definitionsById;
  late final Map<String, Champion> _championsById;

  @override
  ChampionDefinition? definitionById(String id) => _definitionsById[id];

  @override
  Champion? championById(String id) => _championsById[id];

  Champion _buildChampion(ChampionDefinition definition) {
    final typeMoves = ChampionTypeMoveDefinitions.forType(definition.type);
    final criticalMoves = ChampionCriticalMoveDefinitions.forChampion(
      definition.id,
    );
    final moves = [
      for (final gesture in BattleGesture.values)
        _buildMove(gesture, criticalMoves[gesture] ?? typeMoves[gesture]!),
    ];

    return Champion(
      id: definition.id,
      name: definition.name,
      period: definition.period,
      type: definition.type,
      maxHealth: ChampionTypeHealthDefinitions.forType(definition.type),
      imageAssetPath:
          definition.imageAssetPath ?? _defaultArtworkPath(definition.id),
      closeUpAssetPath: definition.closeUpAssetPath,
      moves: moves,
    );
  }

  ChampionMove _buildMove(
    BattleGesture gesture,
    ChampionMoveDefinition definition,
  ) {
    return ChampionMove(
      name: definition.name,
      gesture: gesture,
      potency: definition.potency,
      effect: definition.effect,
      description:
          definition.effectDescription ??
          (definition.isCritical
              ? 'Ataque crítico de especie.'
              : 'Ataque básico de tipo.'),
      statusApplications: definition.statusApplications,
      reservePotency: definition.reservePotency,
      followUpPotency: definition.followUpPotency,
      effectTurns: definition.effectTurns,
      isCritical: definition.isCritical,
      dealsFullDamageOnDraw: definition.dealsFullDamageOnDraw,
      selfHealing: definition.selfHealing,
      selfDamage: definition.selfDamage,
      bonusPotencyIfTargetSwapped: definition.bonusPotencyIfTargetSwapped,
      bonusPotencyIfTargetBleeding: definition.bonusPotencyIfTargetBleeding,
      bonusPotencyPerRoundWithoutWinning:
          definition.bonusPotencyPerRoundWithoutWinning,
      bonusPotencyIfAtOrBelowHalfHealth:
          definition.bonusPotencyIfAtOrBelowHalfHealth,
      maxHealthGrowth: definition.maxHealthGrowth,
      cleansesHarmfulStatuses: definition.cleansesHarmfulStatuses,
      transfersHarmfulStatusesToOpponent:
          definition.transfersHarmfulStatusesToOpponent,
      companionEffect: definition.companionEffect,
      randomHarmfulStatusCount: definition.randomHarmfulStatusCount,
      randomBeneficialStatusCount: definition.randomBeneficialStatusCount,
      clearsOpponentCompanions: definition.clearsOpponentCompanions,
      mixedMoveChoice: definition.mixedMoveChoice,
    );
  }

  String _defaultArtworkPath(String championId) {
    return switch (championId) {
      'ornithosuchus' => 'assets/dinos/ornitosuchus.png',
      _ => 'assets/dinos/$championId.jpg',
    };
  }
}

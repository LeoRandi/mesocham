import '../entities/champion.dart';
import '../entities/champion_definition.dart';

abstract interface class ChampionCatalog {
  List<ChampionDefinition> get definitions;

  List<Champion> get champions;

  ChampionDefinition? definitionById(String id);

  Champion? championById(String id);
}

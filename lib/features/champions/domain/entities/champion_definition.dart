import 'champion.dart';
import 'champion_move.dart';
import 'status_effect.dart';

class ChampionMoveDefinition {
  const ChampionMoveDefinition({
    required this.name,
    this.potency = 0,
    this.effectDescription,
    this.effect = MoveEffect.damage,
    this.statusApplications = const [],
    this.effectTurns = 0,
    this.isCritical = false,
    this.dealsFullDamageOnDraw = false,
    this.selfHealing = 0,
    this.selfDamage = 0,
    this.bonusPotencyIfTargetSwapped = 0,
    this.cleansesHarmfulStatuses = false,
  });

  final String name;
  final double potency;
  final String? effectDescription;
  final MoveEffect effect;
  final List<StatusApplication> statusApplications;
  final int effectTurns;
  final bool isCritical;
  final bool dealsFullDamageOnDraw;
  final double selfHealing;
  final double selfDamage;
  final double bonusPotencyIfTargetSwapped;
  final bool cleansesHarmfulStatuses;
}

class ChampionDefinition {
  const ChampionDefinition({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.type,
    required this.period,
    required this.estimatedSizeAndWeight,
    required this.discovery,
    required this.curiosity,
    this.imageAssetPath,
    this.closeUpAssetPath,
    this.family,
  });

  final String id;
  final String name;
  final String scientificName;
  final ChampionType type;
  final MesozoicPeriod period;
  final String estimatedSizeAndWeight;
  final String discovery;
  final String curiosity;
  final String? imageAssetPath;
  final String? closeUpAssetPath;
  final String? family;
}

typedef ChampionMovePreset = ChampionMoveDefinition;
typedef ChampionPreset = ChampionDefinition;

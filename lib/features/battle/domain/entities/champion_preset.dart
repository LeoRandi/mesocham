import 'battle_gesture.dart';
import 'battle_status.dart';
import 'champion.dart';
import 'champion_move.dart';

class ChampionMovePreset {
  const ChampionMovePreset({
    required this.name,
    this.potency = 0,
    this.effectDescription,
    this.effect = MoveEffect.damage,
    this.statusApplications = const [],
    this.effectTurns = 0,
    this.isCritical = false,
    this.dealsFullDamageOnDraw = false,
  });

  final String name;
  final double potency;
  final String? effectDescription;
  final MoveEffect effect;
  final List<StatusApplication> statusApplications;
  final int effectTurns;
  final bool isCritical;
  final bool dealsFullDamageOnDraw;
}

class ChampionPreset {
  const ChampionPreset({
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
    this.moveOverrides = const {},
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

  /// Gesture-specific loadout supplied by the champion row, when present.
  final Map<BattleGesture, ChampionMovePreset> moveOverrides;
}

import 'battle_gesture.dart';
import 'champion.dart';

class ChampionMovePreset {
  const ChampionMovePreset({
    required this.name,
    this.effectDescription,
    this.isCritical = false,
  });

  final String name;
  final String? effectDescription;
  final bool isCritical;
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
  final String? family;

  /// Gesture-specific loadout supplied by the champion row, when present.
  final Map<BattleGesture, ChampionMovePreset> moveOverrides;
}

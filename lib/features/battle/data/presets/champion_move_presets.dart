import '../../domain/entities/champion.dart';
import '../../domain/entities/champion_preset.dart';

abstract final class ChampionTypeMovePresets {
  /// The worksheet does not assign gestures, so its row order is preserved.
  static const Map<ChampionType, List<ChampionMovePreset>> byType = {
    ChampionType.jaw: [
      ChampionMovePreset(name: 'Rugido de caza'),
      ChampionMovePreset(name: 'Mandíbula letal'),
      ChampionMovePreset(name: 'Emboscada'),
    ],
    ChampionType.nest: [
      ChampionMovePreset(name: 'Nueva vida'),
      ChampionMovePreset(name: 'Puesto de vigía'),
      ChampionMovePreset(name: 'Embestida'),
    ],
    ChampionType.water: [
      ChampionMovePreset(name: 'Pesca'),
      ChampionMovePreset(name: 'Banco de peces'),
      ChampionMovePreset(name: 'Aguas profundas'),
    ],
    ChampionType.crown: [
      ChampionMovePreset(name: 'Escudo corona'),
      ChampionMovePreset(name: 'Carga'),
      ChampionMovePreset(name: 'Pico quebrador'),
    ],
    ChampionType.wings: [
      ChampionMovePreset(name: 'Caída en picado'),
      ChampionMovePreset(name: 'Gran pico'),
      ChampionMovePreset(name: 'Alzar vuelo'),
    ],
    ChampionType.titan: [
      ChampionMovePreset(name: 'Cabezazo saurópodo'),
      ChampionMovePreset(name: 'Huella de gigante'),
      ChampionMovePreset(name: 'Látigo titánico'),
    ],
    ChampionType.claws: [
      ChampionMovePreset(name: 'Presión múltiple'),
      ChampionMovePreset(name: 'Robo'),
      ChampionMovePreset(name: 'Garra asesina'),
    ],
    ChampionType.plates: [
      ChampionMovePreset(name: 'Lanza ósea'),
      ChampionMovePreset(name: 'Escamas dentadas'),
      ChampionMovePreset(name: 'Posición defensiva'),
    ],
  };

  static List<ChampionMovePreset> forType(ChampionType type) => byType[type]!;
}

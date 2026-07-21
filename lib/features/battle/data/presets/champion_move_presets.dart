import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_status.dart';
import '../../domain/entities/champion.dart';
import '../../domain/entities/champion_move.dart';
import '../../domain/entities/champion_preset.dart';

abstract final class ChampionTypeMovePresets {
  static const Map<ChampionType, Map<BattleGesture, ChampionMovePreset>>
  byType = {
    ChampionType.jaw: {
      BattleGesture.rock: ChampionMovePreset(
        name: 'Emboscada',
        potency: 20,
        effectDescription: 'Potencia se añade incluso en el empate.',
        dealsFullDamageOnDraw: true,
      ),
      BattleGesture.paper: ChampionMovePreset(
        name: 'Rugido de caza',
        effect: MoveEffect.none,
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
        ],
        effectDescription: 'Gana Ímpetu de Alfa.',
      ),
      BattleGesture.scissors: ChampionMovePreset(
        name: 'Mandíbula letal',
        potency: 50,
      ),
    },
    ChampionType.nest: {
      BattleGesture.rock: ChampionMovePreset(
        name: 'Nueva vida',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Cura al usuario en vez de hacer daño, usando su potencia.',
      ),
      BattleGesture.paper: ChampionMovePreset(name: 'Embestida', potency: 30),
      BattleGesture.scissors: ChampionMovePreset(
        name: 'Puesto de vigía',
        effect: MoveEffect.none,
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
            durationTurns: 3,
          ),
        ],
        effectDescription:
            'Baja la potencia del enemigo a la mitad durante 3 turnos.',
      ),
    },
    ChampionType.water: {
      BattleGesture.rock: ChampionMovePreset(
        name: 'Aguas profundas',
        potency: 10,
        effect: MoveEffect.damageTeam,
        effectDescription: 'Hace daño a todo el equipo rival.',
      ),
      BattleGesture.paper: ChampionMovePreset(
        name: 'Banco de peces',
        potency: 10,
        effect: MoveEffect.healTeam,
        effectDescription: 'Cura en base a la potencia, a todo el equipo.',
      ),
      BattleGesture.scissors: ChampionMovePreset(name: 'Pesca', potency: 30),
    },
    ChampionType.crown: {
      BattleGesture.rock: ChampionMovePreset(
        name: 'Escudo corona',
        effect: MoveEffect.none,
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
            durationTurns: 3,
          ),
        ],
        effectDescription:
            'Baja la potencia del enemigo a la mitad durante 3 turnos.',
      ),
      BattleGesture.paper: ChampionMovePreset(
        name: 'Pico quebrador',
        potency: 30,
      ),
      BattleGesture.scissors: ChampionMovePreset(
        name: 'Carga',
        potency: 60,
        effect: MoveEffect.recklessDamage,
        effectDescription:
            'Recibe daño de vuelta una tercera parte del daño hecho.',
      ),
    },
    ChampionType.wings: {
      BattleGesture.rock: ChampionMovePreset(
        name: 'Caída en picado',
        potency: 30,
      ),
      BattleGesture.paper: ChampionMovePreset(
        name: 'Llamada de ayuda',
        effect: MoveEffect.none,
        effectDescription: 'Llama a un compañero durante 3 turnos.',
      ),
      BattleGesture.scissors: ChampionMovePreset(
        name: 'Alzar el vuelo',
        potency: 20,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '20 potencia, cambia a tu campeón por otro de tu equipo.',
      ),
    },
    ChampionType.titan: {
      BattleGesture.rock: ChampionMovePreset(
        name: 'Alcance superior',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Cura al usuario en vez de hacer daño, usando su potencia.',
      ),
      BattleGesture.paper: ChampionMovePreset(
        name: 'Huella de gigante',
        potency: 20,
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        effectDescription: 'Mete Intimidación al campeón rival.',
      ),
      BattleGesture.scissors: ChampionMovePreset(
        name: 'Látigo titánico',
        potency: 30,
        effect: MoveEffect.damageReserve,
        effectDescription:
            'Hace daño al campeón rival o a un campeón rival en la reserva.',
      ),
    },
    ChampionType.claws: {
      BattleGesture.rock: ChampionMovePreset(
        name: 'Presión múltiple',
        potency: 20,
        effect: MoveEffect.damageTeam,
        effectDescription: 'Hace daño a todo el equipo rival.',
      ),
      BattleGesture.paper: ChampionMovePreset(
        name: 'Robo',
        potency: 20,
        effectDescription:
            'Roba un compañero al equipo rival durante 3 turnos.',
      ),
      BattleGesture.scissors: ChampionMovePreset(
        name: 'Garra asesina',
        potency: 50,
        statusApplications: [
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
            durationTurns: 5,
          ),
        ],
        effectDescription: 'Mete Sangrado al campeón rival.',
      ),
    },
    ChampionType.plates: {
      BattleGesture.rock: ChampionMovePreset(name: 'Lanza ósea', potency: 30),
      BattleGesture.paper: ChampionMovePreset(
        name: 'Escamas dentadas',
        effect: MoveEffect.none,
        statusApplications: [
          StatusApplication(
            type: StatusType.jaggedScales,
            target: StatusTarget.self,
            durationTurns: 3,
          ),
        ],
        effectDescription: 'Gana el estado Escamas dentadas durante 3 turnos.',
      ),
      BattleGesture.scissors: ChampionMovePreset(
        name: 'Posición defensiva',
        effect: MoveEffect.none,
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
            durationTurns: 3,
          ),
        ],
        effectDescription:
            'Baja la potencia del enemigo a la mitad durante 3 turnos.',
      ),
    },
  };

  static Map<BattleGesture, ChampionMovePreset> forType(ChampionType type) =>
      byType[type]!;
}

abstract final class ChampionTypeHealthPresets {
  static const Map<ChampionType, int> byType = {
    ChampionType.jaw: 140,
    ChampionType.nest: 160,
    ChampionType.water: 150,
    ChampionType.crown: 150,
    ChampionType.wings: 125,
    ChampionType.titan: 200,
    ChampionType.claws: 100,
    ChampionType.plates: 175,
  };

  static int forType(ChampionType type) => byType[type]!;
}

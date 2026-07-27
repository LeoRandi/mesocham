import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/champion_definition.dart';
import '../../domain/entities/champion_move.dart';
import '../../domain/entities/status_effect.dart';

abstract final class ChampionCriticalMoveDefinitions {
  static const Map<String, Map<BattleGesture, ChampionMoveDefinition>>
  byChampionId = {
    'ornithosuchus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Sorpresa sangrienta',
        potency: 30,
        effectDescription:
            '30 de daño, se aplica en empates y provoca Sangrado.',
        statusApplications: [
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
        dealsFullDamageOnDraw: true,
      ),
    },
    'allosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Competencia dañina',
        potency: 60,
        effectDescription:
            '60 de daño. El usuario recibe 20 de daño de vuelta.',
        selfDamage: 20,
        isCritical: true,
      ),
    },
    'dilophosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Rey del pantano',
        potency: 30,
        effectDescription:
            '30 de daño, se aplica en empates y gana Ímpetu de alfa.',
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
        ],
        isCritical: true,
        dealsFullDamageOnDraw: true,
      ),
    },
    'tyrannosaurus-rex': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Mordisco mortal',
        potency: 60,
        effectDescription: '60 de daño y provoca Hueso roto.',
        statusApplications: [
          StatusApplication(
            type: StatusType.brokenBone,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'giganotosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Rugido del gigante',
        effect: MoveEffect.none,
        effectDescription: 'Gana Ímpetu de alfa y provoca Intimidación.',
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'carnotaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Persecución',
        potency: 20,
        effectDescription:
            '20 de daño, más 40 si el rival cambió de campeón este turno.',
        bonusPotencyIfTargetSwapped: 40,
        isCritical: true,
      ),
    },
    'majungasaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Canibalismo',
        potency: 50,
        effectDescription: '50 de daño y recupera 10 PS.',
        selfHealing: 10,
        isCritical: true,
      ),
    },
    'placeria': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Colmillos',
        potency: 30,
        effectDescription: '30 de daño y provoca Sangrado.',
        statusApplications: [
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'shirngasaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Figura imponente',
        effect: MoveEffect.forceOpponentSwap,
        effectDescription:
            'Fuerza el cambio del rival y provoca Intimidación al relevo.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'iguanodon': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Pulgar afilado',
        potency: 40,
        effectDescription: '40 de daño y gana Ímpetu de alfa.',
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
        ],
        isCritical: true,
      ),
    },
    'parasaurolophus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Ataque sonoro',
        potency: 30,
        effectDescription: '30 de daño y provoca Intimidación.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'maiasaura': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Instinto maternal',
        potency: 30,
        effectDescription: '30 de daño y recupera 20 PS.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'therizinosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Cuchillada',
        potency: 60,
        effectDescription: '60 de daño.',
        isCritical: true,
      ),
    },
    'gallimimus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Huida',
        potency: 50,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '50 de daño y cambia al usuario por una reserva disponible.',
        isCritical: true,
      ),
    },
    'oviraptor': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Robo falso',
        potency: 20,
        effectDescription: '20 de daño y recupera 20 PS.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'pachycephalosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cabezazo',
        potency: 70,
        effectDescription:
            '70 de daño. El usuario recibe 20 de daño de vuelta.',
        selfDamage: 20,
        isCritical: true,
      ),
    },
    'deinocheirus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Mano terrible',
        potency: 40,
        effectDescription: '40 de daño y provoca Intimidación.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'placodus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Natación torpe',
        potency: 40,
        effect: MoveEffect.damageReserve,
        effectDescription: '40 de daño a una reserva enemiga disponible.',
        isCritical: true,
      ),
    },
    'ichthyosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Pescador veloz',
        potency: 40,
        effectDescription: '40 de daño y provoca Hambruna.',
        statusApplications: [
          StatusApplication(
            type: StatusType.famine,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'plesiosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Busca rocas',
        potency: 30,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Recupera 30 PS y se vuelve inmune a efectos dañinos.',
        statusApplications: [
          StatusApplication(
            type: StatusType.secondaryImmunity,
            target: StatusTarget.self,
          ),
        ],
        isCritical: true,
      ),
    },
    'mosasaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Bestia del mar',
        potency: 60,
        effectDescription: '60 de daño.',
        isCritical: true,
      ),
    },
    'deinosuchus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Arrastre',
        potency: 40,
        effect: MoveEffect.damageReserveAndPromote,
        effectDescription:
            '40 de daño a una reserva enemiga y la fuerza al campo.',
        isCritical: true,
      ),
    },
    'koolasuchus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Laguna helada',
        potency: 20,
        effect: MoveEffect.healTeam,
        effectDescription:
            'Recupera 20 PS de todo el equipo y limpia los efectos dañinos '
            'del usuario.',
        cleansesHarmfulStatuses: true,
        isCritical: true,
      ),
    },
    'triceratops': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Embestida de las 3 puntas',
        potency: 60,
        effectDescription: '60 de daño y conserva toda la potencia en empates.',
        isCritical: true,
        dealsFullDamageOnDraw: true,
      ),
    },
    'protoceratops': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Rompe muñecas',
        potency: 30,
        effectDescription: '30 de daño y provoca Hueso roto.',
        statusApplications: [
          StatusApplication(
            type: StatusType.brokenBone,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'torosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Corona viva',
        effect: MoveEffect.none,
        effectDescription: 'Provoca Intimidación.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'tanystropheus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cuello pescador',
        potency: 20,
        effect: MoveEffect.healTeam,
        effectDescription: 'Recupera 20 PS de todo el equipo.',
        isCritical: true,
      ),
    },
    'diplodocus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cuerpo ecosistema',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Recupera 20 PS. La llamada de compañero queda pendiente del '
            'sistema de compañeros.',
        isCritical: true,
      ),
    },
    'amargasaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Columna espinosa',
        potency: 40,
        effectDescription: '40 de daño y gana Escamas dentadas.',
        statusApplications: [
          StatusApplication(
            type: StatusType.jaggedScales,
            target: StatusTarget.self,
          ),
        ],
        isCritical: true,
      ),
    },
    'argentinosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Látigo colosal',
        potency: 40,
        effect: MoveEffect.damageReserveAndPromote,
        effectDescription:
            '40 de daño a una reserva enemiga y la fuerza al campo.',
        isCritical: true,
      ),
    },
    'quetzalcoatlus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Caza terrestre',
        potency: 40,
        effectDescription:
            '40 de daño. El robo queda pendiente del sistema de compañeros.',
        isCritical: true,
      ),
    },
    'tupandactylus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Llamada de apareamiento',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Recupera 20 PS. La llamada queda pendiente del sistema de '
            'compañeros.',
        isCritical: true,
      ),
    },
    'tropeognathus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Migración',
        potency: 30,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '30 de daño y cambia al usuario por una reserva disponible.',
        isCritical: true,
      ),
    },
    'coelophysis': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Adaptación',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Recupera 20 PS y gana Escamas protectoras durante 3 turnos.',
        statusApplications: [
          StatusApplication(
            type: StatusType.protectiveScales,
            target: StatusTarget.self,
            durationTurns: 3,
          ),
        ],
        isCritical: true,
      ),
    },
    'velociraptor': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Emboscada letal',
        potency: 40,
        effect: MoveEffect.damageTeam,
        effectDescription: '40 de daño a todo el equipo enemigo.',
        isCritical: true,
      ),
    },
    'utahraptor': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Garra fulminante',
        potency: 70,
        effectDescription: '70 de daño y provoca Sangrado.',
        statusApplications: [
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'troodon': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Planificación',
        potency: 20,
        effect: MoveEffect.damageTeam,
        effectDescription:
            '20 de daño a todo el equipo enemigo y bloquea el siguiente '
            'cambio del campeón activo.',
        statusApplications: [
          StatusApplication(
            type: StatusType.swapLocked,
            target: StatusTarget.opponent,
            durationTurns: 1,
          ),
        ],
        isCritical: true,
      ),
    },
    'austroraptor': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Ladrón de presa',
        potency: 20,
        effectDescription:
            '20 de daño y recupera 20 PS. El robo queda pendiente del sistema '
            'de compañeros.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'stegosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Placas de sangre',
        effect: MoveEffect.none,
        effectDescription: 'Gana Escamas dentadas y provoca Intimidación.',
        statusApplications: [
          StatusApplication(
            type: StatusType.jaggedScales,
            target: StatusTarget.self,
          ),
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'kentrosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Hombreras espinosas',
        potency: 30,
        effectDescription:
            '30 de daño y gana Escamas protectoras durante 3 turnos.',
        statusApplications: [
          StatusApplication(
            type: StatusType.protectiveScales,
            target: StatusTarget.self,
            durationTurns: 3,
          ),
        ],
        isCritical: true,
      ),
    },
    'gigantspinosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cola dentada',
        potency: 40,
        effectDescription: '40 de daño y provoca Sangrado.',
        statusApplications: [
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'spicomellus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Cuerpo de espinas',
        effect: MoveEffect.none,
        effectDescription:
            'Gana Escamas dentadas durante 3 turnos y provoca Sangrado.',
        statusApplications: [
          StatusApplication(
            type: StatusType.jaggedScales,
            target: StatusTarget.self,
            durationTurns: 3,
          ),
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'ankylosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Martillazo',
        potency: 50,
        effectDescription: '50 de daño y provoca Hueso roto.',
        statusApplications: [
          StatusApplication(
            type: StatusType.brokenBone,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
  };

  static Map<BattleGesture, ChampionMoveDefinition> forChampion(
    String championId,
  ) {
    return byChampionId[championId] ?? const {};
  }
}

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
    'ctenosauriscus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Vela dorsal',
        potency: 20,
        effectDescription: '20 de daño y provoca Intimidación.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
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
    'ceratosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Mordisco debilitante',
        potency: 50,
        effectDescription: '50 de daño y provoca Sangrado.',
        statusApplications: [
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
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
    'albertosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Caza de riesgo',
        potency: 40,
        effectDescription: '40 de daño, también en empates.',
        isCritical: true,
        dealsFullDamageOnDraw: true,
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
    'carcharadontosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Depredador dominante',
        effect: MoveEffect.none,
        effectDescription: 'Gana Ímpetu de alfa y provoca Hambruna.',
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
          StatusApplication(
            type: StatusType.famine,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'nanotyrannus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Pequeño rey',
        potency: 50,
        reservePotency: 10,
        effect: MoveEffect.damageActiveAndReserves,
        effectDescription:
            '50 de daño y 10 de daño a cada campeón enemigo en la reserva.',
        isCritical: true,
      ),
    },
    'saurophaganax': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Mandíbula mixta',
        potency: 50,
        effectDescription:
            '50 de daño y provoca Sangrado, Intimidación, Hueso roto o '
            'Hambruna al azar.',
        randomHarmfulStatusCount: 1,
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
    'dryosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Nidada forestal',
        potency: 40,
        effect: MoveEffect.healSelf,
        effectDescription: 'Recupera 40 PS.',
        isCritical: true,
      ),
    },
    'camptosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Alerta grupal',
        potency: 20,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '20 de daño, cambia a una reserva y le otorga Escamas '
            'protectoras durante 3 turnos.',
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
        effectDescription:
            '20 de daño, recupera 20 PS y roba un compañero del rival.',
        selfHealing: 20,
        companionEffect: CompanionMoveEffect.stealRandom,
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
    'iguanodon-m': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Sanación mixta',
        potency: 25,
        effect: MoveEffect.healTeam,
        effectDescription: 'Recupera 25 PS de todo el equipo.',
        isCritical: true,
      ),
    },
    'nothosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Adaptación vertiginosa',
        potency: 10,
        effect: MoveEffect.healTeam,
        effectDescription:
            'Recupera 10 PS de todo el equipo y provoca Hambruna.',
        statusApplications: [
          StatusApplication(
            type: StatusType.famine,
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
    'liopleurodon': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Emboscada acuática',
        potency: 40,
        bonusPotencyPerRoundWithoutWinning: 20,
        effectDescription:
            '40 de daño, más 20 por cada ronda activa anterior sin ganar.',
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
    'spinosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Pesca paciente',
        potency: 40,
        effectDescription: '40 de daño y llama a un compañero aleatorio.',
        companionEffect: CompanionMoveEffect.summonRandom,
        isCritical: true,
      ),
    },
    'baryonyx': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Pesca de agarre',
        potency: 40,
        effectDescription:
            '40 de daño y bloquea el siguiente cambio del campeón rival.',
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
    'suchomimus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Superioridad descomunal',
        potency: 10,
        effect: MoveEffect.damageTeam,
        effectDescription:
            '10 de daño a todo el equipo enemigo, gana Ímpetu de alfa y '
            'provoca Intimidación.',
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
    'spinofaarus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Evolución falsa',
        potency: 20,
        effect: MoveEffect.mixedChoice,
        effectDescription:
            'Activa una opción: recupera 10 PS de todo el equipo; inflige '
            '20 de daño y cambia al usuario; o cambia al rival y le provoca '
            'Hambruna.',
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
    'yinlong': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Sanación tardía',
        potency: 10,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '10 de daño, cambia a una reserva y esta recupera 20 PS.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'torosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Corona viva',
        effect: MoveEffect.none,
        effectDescription: 'Recupera 20 PS y provoca Intimidación.',
        selfHealing: 20,
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'pachyrhinosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Gran lomo',
        effect: MoveEffect.none,
        effectDescription:
            'Provoca Intimidación y llama a un compañero aleatorio.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        companionEffect: CompanionMoveEffect.summonRandom,
        isCritical: true,
      ),
    },
    'styracosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Púa frontal',
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
    'diabloceratops': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Pentaimpacto',
        potency: 20,
        followUpPotency: 30,
        effect: MoveEffect.damageSwapOpponentAndDamage,
        effectDescription:
            '20 de daño, cambia al campeón rival e inflige 30 de daño al '
            'relevo.',
        isCritical: true,
      ),
    },
    'einiosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Cuerno curvado',
        potency: 50,
        effectDescription: '50 de daño, provoca Sangrado y recupera 10 PS.',
        selfHealing: 10,
        statusApplications: [
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'regaliceratops': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Marca del rey',
        effect: MoveEffect.none,
        effectDescription:
            'Todo el equipo gana Escamas protectoras durante 3 turnos y el '
            'usuario gana Ímpetu de alfa.',
        statusApplications: [
          StatusApplication(
            type: StatusType.protectiveScales,
            target: StatusTarget.selfTeam,
            durationTurns: 3,
          ),
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
        ],
        isCritical: true,
      ),
    },
    'nasutoceratops': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Morro abultado',
        potency: 30,
        effectDescription: '30 de daño y recupera 20 PS.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'monoclonius': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Edad mixta',
        effect: MoveEffect.none,
        effectDescription:
            'Provoca dos estados dañinos aleatorios y recupera 30 PS.',
        selfHealing: 30,
        randomHarmfulStatusCount: 2,
        isCritical: true,
      ),
    },
    'chaoyangsaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Huida cobarde',
        potency: 10,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '10 de daño, cambia a una reserva y le otorga Escamas '
            'protectoras.',
        statusApplications: [
          StatusApplication(
            type: StatusType.protectiveScales,
            target: StatusTarget.self,
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
    'plateosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Primer gigante',
        potency: 20,
        effectDescription: '20 de daño, recupera 10 PS y provoca Intimidación.',
        selfHealing: 10,
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'camelotia': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Gran garra',
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
    'diplodocus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cuerpo ecosistema',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription: 'Recupera 20 PS y llama a un compañero aleatorio.',
        companionEffect: CompanionMoveEffect.summonRandom,
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
    'mamenchisaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Vigía titánico',
        potency: 30,
        effect: MoveEffect.damageReserve,
        effectDescription:
            '30 de daño a un campeón enemigo disponible y gana Escamas '
            'protectoras durante 3 turnos.',
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
    'brachiosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Dominio vertical',
        potency: 20,
        effect: MoveEffect.damageTeam,
        effectDescription:
            '20 de daño a todo el equipo enemigo y provoca Intimidación al '
            'campeón activo.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'turiasaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cauce del Turia',
        potency: 40,
        effectDescription:
            '40 de daño y transfiere todos los estados dañinos del usuario '
            'al campeón rival.',
        transfersHarmfulStatusesToOpponent: true,
        isCritical: true,
      ),
    },
    'brontosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Regreso atronador',
        potency: 40,
        bonusPotencyIfAtOrBelowHalfHealth: 30,
        effectDescription:
            '40 de daño, o 70 si el usuario comienza el ataque con la mitad '
            'o menos de sus PS.',
        isCritical: true,
      ),
    },
    'alamosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Madurez tardía',
        potency: 30,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Recupera 30 PS. La primera vez que se usa, aumenta los PS '
            'máximos y actuales del usuario en 20 durante la batalla.',
        maxHealthGrowth: 20,
        isCritical: true,
      ),
    },
    'ultrasaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Quimera colosal',
        potency: 30,
        reservePotency: 20,
        followUpPotency: 10,
        effect: MoveEffect.damageActiveAndRandomReserves,
        effectDescription:
            '30 de daño al campeón activo, 20 a una reserva aleatoria y 10 '
            'a otra reserva aleatoria.',
        isCritical: true,
      ),
    },
    'anurognathus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cazador nocturno',
        potency: 30,
        reservePotency: 10,
        effect: MoveEffect.damageActiveAndReserves,
        effectDescription:
            '30 de daño al campeón activo y 10 a cada campeón enemigo en '
            'la reserva.',
        isCritical: true,
      ),
    },
    'pterodactylus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Sustento traicionero',
        potency: 30,
        effectDescription:
            '30 de daño, sacrifica un compañero y, a cambio, gana Ímpetu '
            'de alfa y Escamas protectoras durante 3 turnos.',
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
          StatusApplication(
            type: StatusType.protectiveScales,
            target: StatusTarget.self,
            durationTurns: 3,
          ),
        ],
        companionEffect: CompanionMoveEffect.sacrificeRandom,
        isCritical: true,
      ),
    },
    'archaeopteryx': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Plumaje ágil',
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
    'quetzalcoatlus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Caza terrestre',
        potency: 40,
        effectDescription: '40 de daño y roba un compañero del campeón rival.',
        companionEffect: CompanionMoveEffect.stealRandom,
        isCritical: true,
      ),
    },
    'tupandactylus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Llamada de apareamiento',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription: 'Recupera 20 PS y llama a un compañero aleatorio.',
        companionEffect: CompanionMoveEffect.summonRandom,
        isCritical: true,
      ),
    },
    'tropeognathus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Migración',
        potency: 30,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '30 de daño, cambia a una reserva y le traspasa sus compañeros.',
        companionEffect: CompanionMoveEffect.transferOnSwap,
        isCritical: true,
      ),
    },
    'hatzegopteryx': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Coloso del aire',
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
    'pteranodon': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Pesca al vuelo',
        potency: 30,
        effectDescription: '30 de daño y recupera 20 PS.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'eudimorphodon': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Viraje de diamante',
        potency: 30,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '30 de daño, cambia a una reserva y el campeón entrante gana '
            'Ímpetu de alfa.',
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
        ],
        isCritical: true,
      ),
    },
    'peteinosaurus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Vuelo entre ramas',
        potency: 30,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '30 de daño, cambia a una reserva y el campeón entrante recupera '
            '20 PS.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'dimorphodon': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Dentición doble',
        potency: 30,
        effectDescription: '30 de daño y provoca Intimidación y Hueso roto.',
        statusApplications: [
          StatusApplication(
            type: StatusType.intimidation,
            target: StatusTarget.opponent,
          ),
          StatusApplication(
            type: StatusType.brokenBone,
            target: StatusTarget.opponent,
          ),
        ],
        isCritical: true,
      ),
    },
    'protoavis': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Recomposición Mezclada',
        potency: 10,
        effect: MoveEffect.healTeamAndRedistributeHealth,
        effectDescription:
            'Recupera 10 PS de todo el equipo y redistribuye sus PS actuales '
            'de forma equilibrada sin superar sus máximos.',
        isCritical: true,
      ),
    },
    'archaeoraptor': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Versatilidad arborícola',
        potency: 40,
        followUpPotency: 20,
        effect: MoveEffect.mixedChoice,
        mixedMoveChoice: MixedMoveChoice.arborealVersatility,
        effectDescription:
            'Elige entre 40 de daño; recuperar 20 PS y limpiar estados '
            'dañinos; o hacer 20 de daño, cambiar y dar Ímpetu de alfa al '
            'relevo.',
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
    'procompsognathus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Ataque cobarde',
        potency: 25,
        effect: MoveEffect.damageTeamAndSwapSelf,
        effectDescription:
            '25 de daño a todo el equipo enemigo y cambia al usuario por '
            'una reserva disponible.',
        isCritical: true,
      ),
    },
    'herrerasaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Sed de sangre',
        potency: 30,
        bonusPotencyIfTargetBleeding: 30,
        effectDescription:
            '30 de daño, o 60 si el campeón rival tiene Sangrado.',
        isCritical: true,
      ),
    },
    'ornitholestes': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Busca nidos',
        potency: 50,
        effectDescription: '50 de daño y roba un compañero del campeón rival.',
        companionEffect: CompanionMoveEffect.stealRandom,
        isCritical: true,
      ),
    },
    'guanlong': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Cresta de exhibición',
        effect: MoveEffect.none,
        effectDescription: 'Roba un compañero rival y gana Ímpetu de alfa.',
        statusApplications: [
          StatusApplication(
            type: StatusType.alphaMomentum,
            target: StatusTarget.self,
          ),
        ],
        companionEffect: CompanionMoveEffect.stealRandom,
        isCritical: true,
      ),
    },
    'marshosaurus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Cazador solitario',
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
    'compsognathus': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Caza insectos',
        potency: 50,
        effectDescription:
            '50 de daño y elimina los compañeros equipados del rival.',
        clearsOpponentCompanions: true,
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
            '20 de daño, roba un compañero rival y recupera 20 PS.',
        selfHealing: 20,
        companionEffect: CompanionMoveEffect.stealRandom,
        isCritical: true,
      ),
    },
    'pelecanimimus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Dieta plena',
        potency: 30,
        effectDescription: '30 de daño y llama a un compañero aleatorio.',
        companionEffect: CompanionMoveEffect.summonRandom,
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
    'proganochelys': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Agua dulce',
        potency: 30,
        effectDescription: '30 de daño y recupera 20 PS.',
        selfHealing: 20,
        isCritical: true,
      ),
    },
    'desmatosuchus': {
      BattleGesture.rock: ChampionMoveDefinition(
        name: 'Carga acorazada',
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
    'scutellosaurus': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Armadura ligera',
        potency: 10,
        effect: MoveEffect.swapSelf,
        effectDescription:
            '10 de daño, cambia a una reserva y le otorga Escamas dentadas '
            'durante 3 turnos.',
        statusApplications: [
          StatusApplication(
            type: StatusType.jaggedScales,
            target: StatusTarget.self,
            durationTurns: 3,
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
    'saichania': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Cubierta total',
        effect: MoveEffect.none,
        effectDescription:
            'El próximo movimiento dañino recibido inflige la mitad de daño '
            'y no aplica efectos secundarios.',
        statusApplications: [
          StatusApplication(
            type: StatusType.totalCover,
            target: StatusTarget.self,
            permanent: true,
          ),
        ],
        isCritical: true,
      ),
    },
    'dracopelta': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Coraza ancestral',
        potency: 20,
        effect: MoveEffect.healSelf,
        effectDescription:
            'Recupera 20 PS, limpia todos los estados dañinos y gana '
            'Inmunidad secundaria durante 3 turnos.',
        cleansesHarmfulStatuses: true,
        statusApplications: [
          StatusApplication(
            type: StatusType.secondaryImmunity,
            target: StatusTarget.self,
            durationTurns: 3,
          ),
        ],
        isCritical: true,
      ),
    },
    'gastonia': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Cerco de púas',
        potency: 30,
        effectDescription:
            '30 de daño. Durante 3 turnos, cada cambio rival inflige 20 de '
            'daño al campeón entrante.',
        statusApplications: [
          StatusApplication(
            type: StatusType.spikeEnclosure,
            target: StatusTarget.opponentTeam,
            durationTurns: 3,
          ),
        ],
        isCritical: true,
      ),
    },
    'sauropelta': {
      BattleGesture.scissors: ChampionMoveDefinition(
        name: 'Vientre a tierra',
        effect: MoveEffect.none,
        effectDescription:
            'Durante 3 turnos recibe la mitad de daño, no puede cambiar y '
            'recupera 30 PS al final de cada turno.',
        statusApplications: [
          StatusApplication(
            type: StatusType.groundedRegeneration,
            target: StatusTarget.self,
            durationTurns: 3,
            delayFirstTick: false,
          ),
        ],
        isCritical: true,
      ),
    },
    'polacanthoides': {
      BattleGesture.paper: ChampionMoveDefinition(
        name: 'Armadura discutida',
        effect: MoveEffect.none,
        effectDescription:
            'Obtiene dos estados beneficiosos distintos al azar entre '
            'Ímpetu de alfa, Escamas protectoras, Escamas dentadas e '
            'Inmunidad secundaria.',
        randomBeneficialStatusCount: 2,
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

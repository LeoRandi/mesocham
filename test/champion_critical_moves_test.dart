import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/features/battle/domain/entities/battle_gesture.dart';
import 'package:mesocham/features/battle/domain/entities/battle_team.dart';
import 'package:mesocham/features/battle/domain/entities/battle_state.dart';
import 'package:mesocham/features/battle/domain/services/battle_rules.dart';
import 'package:mesocham/features/battle/domain/services/companion_randomizer.dart';
import 'package:mesocham/features/champions/data/local/local_champion_catalog.dart';
import 'package:mesocham/features/champions/domain/entities/champion.dart';
import 'package:mesocham/features/champions/domain/entities/status_effect.dart';
import 'package:mesocham/features/companions/domain/entities/companion.dart';

void main() {
  final catalog = LocalChampionCatalog();

  Champion champion(String id) => catalog.championById(id)!;

  BattleTeam team(String activeId) => BattleTeam.fresh([
    champion(activeId),
    champion('allosaurus'),
    champion('triceratops'),
  ]);

  StandardBattleRules rules({int seed = 1}) => StandardBattleRules(
    companionRandomizer: CompanionRandomizer(random: math.Random(seed)),
    random: math.Random(seed),
  );

  group('critical move workbook additions', () {
    const expectedMoves = <String, (BattleGesture, String)>{
      'ctenosauriscus': (BattleGesture.rock, 'Vela dorsal'),
      'ceratosaurus': (BattleGesture.scissors, 'Mordisco debilitante'),
      'albertosaurus': (BattleGesture.rock, 'Caza de riesgo'),
      'carcharadontosaurus': (BattleGesture.paper, 'Depredador dominante'),
      'nanotyrannus': (BattleGesture.scissors, 'Pequeño rey'),
      'saurophaganax': (BattleGesture.scissors, 'Mandíbula mixta'),
      'dryosaurus': (BattleGesture.rock, 'Nidada forestal'),
      'camptosaurus': (BattleGesture.scissors, 'Alerta grupal'),
      'iguanodon-m': (BattleGesture.rock, 'Sanación mixta'),
      'nothosaurus': (BattleGesture.paper, 'Adaptación vertiginosa'),
      'liopleurodon': (BattleGesture.scissors, 'Emboscada acuática'),
      'spinosaurus': (BattleGesture.scissors, 'Pesca paciente'),
      'baryonyx': (BattleGesture.scissors, 'Pesca de agarre'),
      'suchomimus': (BattleGesture.rock, 'Superioridad descomunal'),
      'spinofaarus': (BattleGesture.paper, 'Evolución falsa'),
      'yinlong': (BattleGesture.rock, 'Sanación tardía'),
      'pachyrhinosaurus': (BattleGesture.rock, 'Gran lomo'),
      'styracosaurus': (BattleGesture.paper, 'Púa frontal'),
      'diabloceratops': (BattleGesture.scissors, 'Pentaimpacto'),
      'einiosaurus': (BattleGesture.scissors, 'Cuerno curvado'),
      'regaliceratops': (BattleGesture.rock, 'Marca del rey'),
      'nasutoceratops': (BattleGesture.paper, 'Morro abultado'),
      'monoclonius': (BattleGesture.scissors, 'Edad mixta'),
      'chaoyangsaurus': (BattleGesture.rock, 'Huida cobarde'),
      'plateosaurus': (BattleGesture.paper, 'Primer gigante'),
      'camelotia': (BattleGesture.paper, 'Gran garra'),
      'mamenchisaurus': (BattleGesture.scissors, 'Vigía titánico'),
      'anurognathus': (BattleGesture.rock, 'Cazador nocturno'),
      'pterodactylus': (BattleGesture.scissors, 'Sustento traicionero'),
      'archaeopteryx': (BattleGesture.rock, 'Plumaje ágil'),
      'hatzegopteryx': (BattleGesture.rock, 'Coloso del aire'),
      'pteranodon': (BattleGesture.scissors, 'Pesca al vuelo'),
      'procompsognathus': (BattleGesture.rock, 'Ataque cobarde'),
      'herrerasaurus': (BattleGesture.rock, 'Sed de sangre'),
      'ornitholestes': (BattleGesture.paper, 'Busca nidos'),
      'guanlong': (BattleGesture.paper, 'Cresta de exhibición'),
      'marshosaurus': (BattleGesture.rock, 'Cazador solitario'),
      'compsognathus': (BattleGesture.scissors, 'Caza insectos'),
      'pelecanimimus': (BattleGesture.paper, 'Dieta plena'),
      'proganochelys': (BattleGesture.rock, 'Agua dulce'),
      'desmatosuchus': (BattleGesture.rock, 'Carga acorazada'),
      'scutellosaurus': (BattleGesture.paper, 'Armadura ligera'),
      'saichania': (BattleGesture.scissors, 'Cubierta total'),
      'brachiosaurus': (BattleGesture.paper, 'Dominio vertical'),
      'turiasaurus': (BattleGesture.rock, 'Cauce del Turia'),
      'brontosaurus': (BattleGesture.scissors, 'Regreso atronador'),
      'alamosaurus': (BattleGesture.rock, 'Madurez tardía'),
      'ultrasaurus': (BattleGesture.scissors, 'Quimera colosal'),
      'eudimorphodon': (BattleGesture.scissors, 'Viraje de diamante'),
      'peteinosaurus': (BattleGesture.scissors, 'Vuelo entre ramas'),
      'dimorphodon': (BattleGesture.rock, 'Dentición doble'),
      'protoavis': (BattleGesture.paper, 'Recomposición Mezclada'),
      'archaeoraptor': (BattleGesture.scissors, 'Versatilidad arborícola'),
      'dracopelta': (BattleGesture.scissors, 'Coraza ancestral'),
      'gastonia': (BattleGesture.paper, 'Cerco de púas'),
      'sauropelta': (BattleGesture.scissors, 'Vientre a tierra'),
      'polacanthoides': (BattleGesture.paper, 'Armadura discutida'),
    };

    test('all 57 added moves override the matching champion gesture', () {
      for (final entry in expectedMoves.entries) {
        final (gesture, name) = entry.value;
        final move = champion(entry.key).moveFor(gesture);

        expect(move.name, name, reason: entry.key);
        expect(move.isCritical, isTrue, reason: entry.key);
      }
    });

    test('all 100 champions have exactly one critical move', () {
      expect(catalog.champions, hasLength(100));
      for (final entry in catalog.champions) {
        expect(
          entry.moves.where((move) => move.isCritical),
          hasLength(1),
          reason: entry.id,
        );
      }
    });

    test('Pequeño rey damages the active champion and both reserves', () {
      final opponents = team('triceratops');
      final resolution = rules().resolve(
        playerTeam: team('nanotyrannus'),
        opponentTeam: opponents,
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(resolution.damageToOpponent, 50);
      expect(resolution.reserveDamageToOpponent, 20);
      expect(
        resolution.opponentTeam.combatants[0].currentHealth,
        opponents.combatants[0].currentHealth - 50,
      );
      expect(
        resolution.opponentTeam.combatants[1].currentHealth,
        opponents.combatants[1].currentHealth - 10,
      );
      expect(
        resolution.opponentTeam.combatants[2].currentHealth,
        opponents.combatants[2].currentHealth - 10,
      );
    });

    test('Cazador nocturno deals 30 active and 10 to each reserve', () {
      final opponents = team('triceratops');
      final resolution = rules().resolve(
        playerTeam: team('anurognathus'),
        opponentTeam: opponents,
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );

      expect(resolution.damageToOpponent, 30);
      expect(resolution.reserveDamageToOpponent, 20);
      expect(
        resolution.opponentTeam.combatants[0].currentHealth,
        opponents.combatants[0].currentHealth - 30,
      );
      expect(
        resolution.opponentTeam.combatants[1].currentHealth,
        opponents.combatants[1].currentHealth - 10,
      );
      expect(
        resolution.opponentTeam.combatants[2].currentHealth,
        opponents.combatants[2].currentHealth - 10,
      );
    });

    test('new horned and flying criticals apply damage and healing', () {
      final cases = <(String, BattleGesture, BattleGesture, double, double)>[
        ('einiosaurus', BattleGesture.scissors, BattleGesture.paper, 50, 10),
        ('nasutoceratops', BattleGesture.paper, BattleGesture.rock, 30, 20),
        ('pteranodon', BattleGesture.scissors, BattleGesture.paper, 30, 20),
      ];

      for (final (id, playerGesture, opponentGesture, damage, healing)
          in cases) {
        final resolution = rules().resolve(
          playerTeam: team(id).damageActive(40),
          opponentTeam: team('triceratops'),
          playerGesture: playerGesture,
          opponentGesture: opponentGesture,
        );

        expect(resolution.damageToOpponent, damage, reason: id);
        expect(resolution.healingToPlayer, healing, reason: id);
      }
    });

    test('Cuerno curvado also inflicts Bleeding', () {
      final resolution = rules().resolve(
        playerTeam: team('einiosaurus'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(
        resolution.opponentTeam.active.hasStatus(StatusType.bleeding),
        isTrue,
      );
    });

    test('Sustento traicionero sacrifices a companion for both buffs', () {
      final players = team(
        'pterodactylus',
      ).addCompanion(bearerIndex: 0, companion: Companion.horseshoeCrab);
      final resolution = rules().resolve(
        playerTeam: players,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(resolution.damageToOpponent, 30);
      expect(resolution.playerTeam.active.companions, isEmpty);
      expect(
        resolution.playerTeam.active.hasStatus(StatusType.alphaMomentum),
        isTrue,
      );
      expect(
        resolution.playerTeam.active.hasStatus(StatusType.protectiveScales),
        isTrue,
      );
    });

    test('Sustento traicionero cannot grant buffs without a companion', () {
      final resolution = rules().resolve(
        playerTeam: team('pterodactylus'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(resolution.damageToOpponent, 30);
      expect(
        resolution.playerTeam.active.hasStatus(StatusType.alphaMomentum),
        isFalse,
      );
      expect(
        resolution.playerTeam.active.hasStatus(StatusType.protectiveScales),
        isFalse,
      );
    });

    test('Sed de sangre doubles its base damage against Bleeding', () {
      final opponents = team('triceratops').applyStatusToActive(
        const StatusApplication(
          type: StatusType.bleeding,
          target: StatusTarget.self,
        ),
      );
      final resolution = rules().resolve(
        playerTeam: team('herrerasaurus'),
        opponentTeam: opponents,
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );

      expect(resolution.damageToOpponent, 60);
    });

    test(
      'swap criticals apply their defensive status to the incoming reserve',
      () {
        final resolution = rules().resolve(
          playerTeam: team('camptosaurus'),
          opponentTeam: team('triceratops'),
          playerGesture: BattleGesture.scissors,
          opponentGesture: BattleGesture.paper,
        );

        expect(resolution.playerTeam.activeIndex, 1);
        expect(
          resolution.playerTeam.active.hasStatus(StatusType.protectiveScales),
          isTrue,
        );
        expect(
          resolution.playerTeam.combatants[0].hasStatus(
            StatusType.protectiveScales,
          ),
          isFalse,
        );
      },
    );

    test('Ataque cobarde damages the full enemy team before swapping', () {
      final opponents = team('triceratops');
      final resolution = rules().resolve(
        playerTeam: team('procompsognathus'),
        opponentTeam: opponents,
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );

      expect(resolution.playerTeam.activeIndex, 1);
      expect(resolution.damageToOpponent, 25);
      expect(resolution.reserveDamageToOpponent, 50);
      for (var index = 0; index < opponents.combatants.length; index++) {
        expect(
          resolution.opponentTeam.combatants[index].currentHealth,
          opponents.combatants[index].currentHealth - 25,
        );
      }
    });

    test('Mandíbula mixta applies one of its four random debuffs', () {
      final resolution = rules().resolve(
        playerTeam: team('saurophaganax'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      const possibleStatuses = {
        StatusType.bleeding,
        StatusType.intimidation,
        StatusType.brokenBone,
        StatusType.famine,
      };
      expect(
        resolution.opponentTeam.active.statuses
            .where((status) => possibleStatuses.contains(status.type))
            .length,
        1,
      );
    });

    test('Caza insectos clears every companion from the rival', () {
      var opponents = team('triceratops');
      opponents = opponents.addCompanion(
        bearerIndex: 0,
        companion: Companion.dragonfly,
      );
      opponents = opponents.addCompanion(
        bearerIndex: 0,
        companion: Companion.horseshoeCrab,
      );

      final resolution = rules().resolve(
        playerTeam: team('compsognathus'),
        opponentTeam: opponents,
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(resolution.opponentTeam.combatants[0].companions, isEmpty);
    });

    test('Pesca de agarre blocks the rival next swap', () {
      final resolution = rules().resolve(
        playerTeam: team('baryonyx'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(resolution.damageToOpponent, 40);
      expect(
        resolution.opponentTeam.active.hasStatus(StatusType.swapLocked),
        isTrue,
      );
    });

    test('Pentaimpacto hits, swaps the rival, and hits the replacement', () {
      final opponents = team('triceratops');
      final resolution = rules().resolve(
        playerTeam: team('diabloceratops'),
        opponentTeam: opponents,
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(resolution.opponentTeam.activeIndex, 1);
      expect(resolution.damageToOpponent, 50);
      expect(
        resolution.opponentTeam.combatants[0].currentHealth,
        opponents.combatants[0].currentHealth - 20,
      );
      expect(
        resolution.opponentTeam.combatants[1].currentHealth,
        opponents.combatants[1].currentHealth - 30,
      );
    });

    test('Emboscada acuática deals 40 plus 20 per winless active round', () {
      final move = champion('liopleurodon').moveFor(BattleGesture.scissors);
      expect(move.potency, 40);
      expect(move.bonusPotencyPerRoundWithoutWinning, 20);

      final loss = rules().resolve(
        playerTeam: team('liopleurodon'),
        opponentTeam: team('allosaurus'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.rock,
      );
      expect(loss.playerTeam.active.roundsWithoutWinning, 1);

      final win = rules().resolve(
        playerTeam: loss.playerTeam,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );
      expect(win.damageToOpponent, 60);
      expect(win.playerTeam.active.roundsWithoutWinning, 0);
    });

    test('Marca del rey protects the full team and grants alpha momentum', () {
      final resolution = rules().resolve(
        playerTeam: team('regaliceratops'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );

      for (final combatant in resolution.playerTeam.combatants) {
        expect(combatant.hasStatus(StatusType.protectiveScales), isTrue);
      }
      expect(
        resolution.playerTeam.active.hasStatus(StatusType.alphaMomentum),
        isTrue,
      );
    });

    test('Edad mixta heals and applies two different random debuffs', () {
      final resolution = rules().resolve(
        playerTeam: team('monoclonius').damageActive(50),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      const possibleStatuses = {
        StatusType.bleeding,
        StatusType.intimidation,
        StatusType.brokenBone,
        StatusType.famine,
      };
      final appliedStatuses = resolution.opponentTeam.active.statuses
          .where((status) => possibleStatuses.contains(status.type))
          .map((status) => status.type)
          .toSet();
      expect(resolution.healingToPlayer, 30);
      expect(appliedStatuses, hasLength(2));
    });

    test('Evolución falsa honors each of its three selected options', () {
      var sawTeamHealing = false;
      var sawDamageAndSelfSwap = false;
      var sawOpponentSwapAndFamine = false;

      for (var option = 0; option < 3; option++) {
        final resolution = rules().resolve(
          playerTeam: team('spinofaarus').damageAll(20),
          opponentTeam: team('triceratops'),
          playerGesture: BattleGesture.paper,
          opponentGesture: BattleGesture.rock,
          playerMoveOption: option,
        );
        sawTeamHealing |= resolution.healingToPlayer == 30;
        sawDamageAndSelfSwap |=
            resolution.damageToOpponent == 20 && resolution.playerSwapped;
        sawOpponentSwapAndFamine |=
            resolution.opponentSwapped &&
            resolution.opponentTeam.active.hasStatus(StatusType.famine);
      }

      expect(sawTeamHealing, isTrue);
      expect(sawDamageAndSelfSwap, isTrue);
      expect(sawOpponentSwapAndFamine, isTrue);
    });

    test('Evolución falsa requires an option before showdown', () {
      final choosingMove = BattleState(
        playerTeam: team('spinofaarus'),
        opponentTeam: team('triceratops'),
        phase: BattlePhase.choosingMove,
        playerGesture: BattleGesture.paper,
        opponentGesture: BattleGesture.rock,
      );

      expect(choosingMove.canShowdown, isFalse);
      expect(choosingMove.copyWith(playerMoveOption: 1).canShowdown, isTrue);
    });

    test('balance updates add companion theft and healing', () {
      var opponents = team('triceratops');
      opponents = opponents.addCompanion(
        bearerIndex: 0,
        companion: Companion.dragonfly,
      );
      final oviraptorResolution = rules().resolve(
        playerTeam: team('oviraptor').damageActive(40),
        opponentTeam: opponents,
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );
      expect(
        oviraptorResolution.playerTeam.active.hasCompanion(Companion.dragonfly),
        isTrue,
      );
      expect(oviraptorResolution.healingToPlayer, 20);

      final torosaurusResolution = rules().resolve(
        playerTeam: team('torosaurus').damageActive(40),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );
      expect(torosaurusResolution.healingToPlayer, 20);
      expect(
        torosaurusResolution.opponentTeam.active.hasStatus(
          StatusType.intimidation,
        ),
        isTrue,
      );
    });

    test('Cubierta total halves and cleans one damaging move', () {
      final coverResolution = rules().resolve(
        playerTeam: team('saichania'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );
      expect(
        coverResolution.playerTeam.active.hasStatus(StatusType.totalCover),
        isTrue,
      );

      final nonDamagingDebuff = rules().resolve(
        playerTeam: team('carcharadontosaurus'),
        opponentTeam: coverResolution.playerTeam,
        playerGesture: BattleGesture.paper,
        opponentGesture: BattleGesture.rock,
      );
      expect(
        nonDamagingDebuff.opponentTeam.active.hasStatus(StatusType.famine),
        isTrue,
      );
      expect(
        nonDamagingDebuff.opponentTeam.active.hasStatus(StatusType.totalCover),
        isTrue,
      );

      final firstHit = rules().resolve(
        playerTeam: team('ctenosauriscus'),
        opponentTeam: nonDamagingDebuff.opponentTeam,
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );
      expect(firstHit.damageToOpponent, 10);
      expect(
        firstHit.opponentTeam.active.hasStatus(StatusType.intimidation),
        isFalse,
      );
      expect(
        firstHit.opponentTeam.active.hasStatus(StatusType.totalCover),
        isFalse,
      );

      final secondHit = rules().resolve(
        playerTeam: team('ctenosauriscus'),
        opponentTeam: firstHit.opponentTeam,
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );
      expect(secondHit.damageToOpponent, 20);
      expect(
        secondHit.opponentTeam.active.hasStatus(StatusType.intimidation),
        isTrue,
      );
    });

    test(
      'Dominio vertical damages the full team and intimidates the active',
      () {
        final resolution = rules().resolve(
          playerTeam: team('brachiosaurus'),
          opponentTeam: team('triceratops'),
          playerGesture: BattleGesture.paper,
          opponentGesture: BattleGesture.rock,
        );

        expect(resolution.damageToOpponent, 20);
        expect(resolution.reserveDamageToOpponent, 40);
        expect(
          resolution.opponentTeam.active.hasStatus(StatusType.intimidation),
          isTrue,
        );
      },
    );

    test(
      'Cauce del Turia transfers every harmful status after dealing damage',
      () {
        final players = team('turiasaurus')
            .applyStatusToActive(
              const StatusApplication(
                type: StatusType.bleeding,
                target: StatusTarget.self,
              ),
            )
            .applyStatusToActive(
              const StatusApplication(
                type: StatusType.brokenBone,
                target: StatusTarget.self,
              ),
            );
        final resolution = rules().resolve(
          playerTeam: players,
          opponentTeam: team('triceratops'),
          playerGesture: BattleGesture.rock,
          opponentGesture: BattleGesture.scissors,
        );

        expect(resolution.damageToOpponent, 40);
        expect(
          resolution.playerTeam.active.statuses.where(
            (status) => status.type.isHarmful,
          ),
          isEmpty,
        );
        expect(
          resolution.opponentTeam.active.hasStatus(StatusType.bleeding),
          isTrue,
        );
        expect(
          resolution.opponentTeam.active.hasStatus(StatusType.brokenBone),
          isTrue,
        );
      },
    );

    test('Regreso atronador rises from 40 to 70 damage at half health', () {
      final healthy = team('brontosaurus');
      final normalResolution = rules().resolve(
        playerTeam: healthy,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );
      expect(normalResolution.damageToOpponent, 40);

      final weakened = healthy.damageActive(healthy.active.maxHealth / 2);
      final comebackResolution = rules().resolve(
        playerTeam: weakened,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );
      expect(comebackResolution.damageToOpponent, 70);
    });

    test('Madurez tardía grows maximum health only on its first use', () {
      final initial = team('alamosaurus').damageActive(60);
      final originalMaximum = initial.active.maxHealth;
      final firstUse = rules().resolve(
        playerTeam: initial,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );

      expect(firstUse.healingToPlayer, 50);
      expect(firstUse.playerTeam.active.maxHealth, originalMaximum + 20);
      expect(firstUse.playerTeam.active.battleMaxHealthBonus, 20);

      final secondUse = rules().resolve(
        playerTeam: firstUse.playerTeam.damageActive(30),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );
      expect(secondUse.healingToPlayer, 30);
      expect(secondUse.playerTeam.active.maxHealth, originalMaximum + 20);
      expect(secondUse.playerTeam.active.battleMaxHealthBonus, 20);
    });

    test('Quimera colosal deals 30, 20 and 10 to three distinct targets', () {
      final opponents = team('triceratops');
      final resolution = rules(seed: 4).resolve(
        playerTeam: team('ultrasaurus'),
        opponentTeam: opponents,
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      final reserveDamage = <double>[
        for (var index = 1; index < 3; index++)
          opponents.combatants[index].currentHealth -
              resolution.opponentTeam.combatants[index].currentHealth,
      ]..sort();
      expect(resolution.damageToOpponent, 30);
      expect(resolution.reserveDamageToOpponent, 30);
      expect(reserveDamage, [10, 20]);
    });

    test('the two flying swap criticals empower the incoming reserve', () {
      final alphaResolution = rules().resolve(
        playerTeam: team('eudimorphodon'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );
      expect(alphaResolution.damageToOpponent, 30);
      expect(alphaResolution.playerTeam.activeIndex, 1);
      expect(
        alphaResolution.playerTeam.active.hasStatus(StatusType.alphaMomentum),
        isTrue,
      );

      final damagedTeam = team('peteinosaurus').damageAll(40);
      final healingResolution = rules().resolve(
        playerTeam: damagedTeam,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );
      expect(healingResolution.damageToOpponent, 30);
      expect(healingResolution.playerTeam.activeIndex, 1);
      expect(healingResolution.healingToPlayer, 20);
      expect(
        healingResolution.playerTeam.active.currentHealth,
        damagedTeam.combatants[1].currentHealth + 20,
      );
    });

    test('Dentición doble applies both of its harmful statuses', () {
      final resolution = rules().resolve(
        playerTeam: team('dimorphodon'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.rock,
        opponentGesture: BattleGesture.scissors,
      );

      expect(resolution.damageToOpponent, 30);
      expect(
        resolution.opponentTeam.active.hasStatus(StatusType.brokenBone),
        isTrue,
      );
      expect(
        resolution.opponentTeam.active.hasStatus(StatusType.brokenBone),
        isTrue,
      );
    });

    test(
      'Recomposición Mezclada heals then evenly redistributes team health',
      () {
        final players = team('protoavis').damageAll(50);
        final healthBefore = players.combatants.fold<double>(
          0,
          (total, combatant) => total + combatant.currentHealth,
        );
        final resolution = rules().resolve(
          playerTeam: players,
          opponentTeam: team('triceratops'),
          playerGesture: BattleGesture.paper,
          opponentGesture: BattleGesture.rock,
        );
        final resultingHealth = [
          for (final combatant in resolution.playerTeam.combatants)
            combatant.currentHealth,
        ];

        expect(resolution.healingToPlayer, 30);
        expect(
          resultingHealth.reduce((first, second) => first + second),
          closeTo(healthBefore + 30, 0.001),
        );
        expect(
          resultingHealth.reduce(math.max) - resultingHealth.reduce(math.min),
          closeTo(0, 0.001),
        );
      },
    );

    test('Versatilidad arborícola supports all three tactical options', () {
      final damageChoice = rules().resolve(
        playerTeam: team('archaeoraptor'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
        playerMoveOption: 0,
      );
      expect(damageChoice.damageToOpponent, 40);
      expect(damageChoice.playerSwapped, isFalse);

      final damagedPlayers = team('archaeoraptor')
          .damageActive(40)
          .applyStatusToActive(
            const StatusApplication(
              type: StatusType.bleeding,
              target: StatusTarget.self,
            ),
          );
      final recoveryChoice = rules().resolve(
        playerTeam: damagedPlayers,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
        playerMoveOption: 1,
      );
      expect(recoveryChoice.damageToOpponent, 0);
      expect(recoveryChoice.healingToPlayer, 20);
      expect(
        recoveryChoice.playerTeam.active.hasStatus(StatusType.bleeding),
        isFalse,
      );

      final relayChoice = rules().resolve(
        playerTeam: team('archaeoraptor'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
        playerMoveOption: 2,
      );
      expect(relayChoice.damageToOpponent, 20);
      expect(relayChoice.playerSwapped, isTrue);
      expect(
        relayChoice.playerTeam.active.hasStatus(StatusType.alphaMomentum),
        isTrue,
      );
    });

    test('Coraza ancestral heals, cleanses and grants secondary immunity', () {
      final players = team('dracopelta')
          .damageActive(40)
          .applyStatusToActive(
            const StatusApplication(
              type: StatusType.brokenBone,
              target: StatusTarget.self,
            ),
          );
      final resolution = rules().resolve(
        playerTeam: players,
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.scissors,
        opponentGesture: BattleGesture.paper,
      );

      expect(resolution.healingToPlayer, 20);
      expect(
        resolution.playerTeam.active.hasStatus(StatusType.brokenBone),
        isFalse,
      );
      expect(
        resolution.playerTeam.active.hasStatus(StatusType.secondaryImmunity),
        isTrue,
      );
    });

    test('Cerco de púas damages every champion entering through a swap', () {
      final resolution = rules().resolve(
        playerTeam: team('gastonia'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.paper,
        opponentGesture: BattleGesture.rock,
      );
      expect(resolution.damageToOpponent, 30);
      expect(
        resolution.opponentTeam.combatants.every(
          (combatant) => combatant.hasStatus(StatusType.spikeEnclosure),
        ),
        isTrue,
      );

      final incomingHealth =
          resolution.opponentTeam.combatants[1].currentHealth;
      final swappedTeam = resolution.opponentTeam.swapTo(1);
      expect(swappedTeam.active.currentHealth, incomingHealth - 20);
    });

    test('Armadura discutida grants two distinct allowed benefits', () {
      const allowedStatuses = {
        StatusType.alphaMomentum,
        StatusType.protectiveScales,
        StatusType.jaggedScales,
        StatusType.secondaryImmunity,
      };
      final resolution = rules(seed: 8).resolve(
        playerTeam: team('polacanthoides'),
        opponentTeam: team('triceratops'),
        playerGesture: BattleGesture.paper,
        opponentGesture: BattleGesture.rock,
      );
      final grantedStatuses = resolution.playerTeam.active.statuses
          .map((status) => status.type)
          .where(allowedStatuses.contains)
          .toSet();

      expect(grantedStatuses, hasLength(2));
    });

    test(
      'Vientre a tierra heals, blocks swapping and halves incoming damage',
      () {
        final defensiveResolution = rules().resolve(
          playerTeam: team('sauropelta').damageActive(60),
          opponentTeam: team('triceratops'),
          playerGesture: BattleGesture.scissors,
          opponentGesture: BattleGesture.paper,
        );
        expect(defensiveResolution.healingToPlayer, 30);
        expect(
          defensiveResolution.playerTeam.active.hasStatus(
            StatusType.groundedRegeneration,
          ),
          isTrue,
        );
        expect(defensiveResolution.playerTeam.swapIndexes, isEmpty);

        final incomingHit = rules().resolve(
          playerTeam: team('ctenosauriscus'),
          opponentTeam: defensiveResolution.playerTeam,
          playerGesture: BattleGesture.rock,
          opponentGesture: BattleGesture.scissors,
        );
        expect(incomingHit.damageToOpponent, 10);
      },
    );
  });
}

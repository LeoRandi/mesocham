import 'dart:math' as math;

import '../../../champions/domain/entities/champion_move.dart';
import '../../../companions/domain/entities/companion.dart';
import '../../../species_cards/domain/entities/species_card.dart';
import '../entities/battle_effect_event.dart';
import '../entities/battle_gesture.dart';
import '../entities/battle_resolution.dart';
import '../entities/battle_status.dart';
import '../entities/battle_team.dart';
import '../entities/combatant.dart';
import 'companion_randomizer.dart';

abstract interface class BattleRules {
  BattleResolution resolve({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleGesture playerGesture,
    required BattleGesture opponentGesture,
    int? playerMoveOption,
  });

  BattleResolution resolveGuaranteedOpponentMove({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleGesture opponentGesture,
  });
}

class StandardBattleRules implements BattleRules {
  StandardBattleRules({
    required CompanionRandomizer companionRandomizer,
    math.Random? random,
  }) : _companionRandomizer = companionRandomizer,
       _random = random ?? math.Random();

  final CompanionRandomizer _companionRandomizer;
  final math.Random _random;

  static const _randomHarmfulStatuses = [
    StatusType.bleeding,
    StatusType.intimidation,
    StatusType.brokenBone,
    StatusType.famine,
  ];

  static const _randomBeneficialStatuses = [
    StatusType.alphaMomentum,
    StatusType.protectiveScales,
    StatusType.jaggedScales,
    StatusType.secondaryImmunity,
  ];

  @override
  BattleResolution resolve({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleGesture playerGesture,
    required BattleGesture opponentGesture,
    int? playerMoveOption,
  }) {
    final playerMove = playerTeam.active.champion.moveFor(playerGesture);
    final opponentMove = opponentTeam.active.champion.moveFor(opponentGesture);

    if (playerGesture == opponentGesture) {
      final drawPotency =
          math.max(playerMove.potency, opponentMove.potency) / 2;
      final playerPotency = playerMove.dealsFullDamageOnDraw
          ? playerMove.potency
          : drawPotency;
      final opponentPotency = opponentMove.dealsFullDamageOnDraw
          ? opponentMove.potency
          : drawPotency;

      final playerApplication = _applyMove(
        userTeam: playerTeam,
        targetTeam: opponentTeam,
        move: playerMove,
        potency: playerPotency,
        applySecondaryEffects:
            playerTeam.active.equippedSpeciesCard ==
            SpeciesCard.unstoppableClash,
        mixedChoiceOverride: playerMoveOption,
      );
      final opponentApplication = _applyMove(
        userTeam: playerApplication.targetTeam,
        targetTeam: playerApplication.userTeam,
        move: opponentMove,
        potency: opponentPotency,
        applySecondaryEffects:
            opponentTeam.active.equippedSpeciesCard ==
            SpeciesCard.unstoppableClash,
      );

      return _buildResolution(
        outcome: BattleOutcome.draw,
        originalPlayerTeam: playerTeam,
        originalOpponentTeam: opponentTeam,
        playerApplication: playerApplication.mergeUserTeam(
          opponentApplication.targetTeam,
        ),
        opponentApplication: opponentApplication,
      );
    }

    if (playerGesture.beats(opponentGesture)) {
      final companionHealing = _victoryCompanionHealing(playerTeam.active);
      final playerApplication = _applyVictoryHealing(
        _applyMove(
          userTeam: playerTeam,
          targetTeam: opponentTeam,
          move: playerMove,
          potency: playerMove.potency,
          mixedChoiceOverride: playerMoveOption,
        ),
        bearerIndex: playerTeam.activeIndex,
        amount: companionHealing,
      );

      return _buildResolution(
        outcome: BattleOutcome.playerVictory,
        originalPlayerTeam: playerTeam,
        originalOpponentTeam: opponentTeam,
        playerApplication: playerApplication,
        opponentApplication: _MoveApplication.noop(
          userTeam: playerApplication.targetTeam,
          targetTeam: playerApplication.userTeam,
        ),
      );
    }

    final opponentApplication = _applyVictoryHealing(
      _applyMove(
        userTeam: opponentTeam,
        targetTeam: playerTeam,
        move: opponentMove,
        potency: opponentMove.potency,
      ),
      bearerIndex: opponentTeam.activeIndex,
      amount: _victoryCompanionHealing(opponentTeam.active),
    );

    return _buildResolution(
      outcome: BattleOutcome.opponentVictory,
      originalPlayerTeam: playerTeam,
      originalOpponentTeam: opponentTeam,
      playerApplication: _MoveApplication.noop(
        userTeam: opponentApplication.targetTeam,
        targetTeam: opponentApplication.userTeam,
      ),
      opponentApplication: opponentApplication,
    );
  }

  @override
  BattleResolution resolveGuaranteedOpponentMove({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleGesture opponentGesture,
  }) {
    final opponentMove = opponentTeam.active.champion.moveFor(opponentGesture);
    final opponentApplication = _applyMove(
      userTeam: opponentTeam,
      targetTeam: playerTeam,
      move: opponentMove,
      potency: opponentMove.potency,
      targetSwappedThisTurn: true,
    );

    return _buildResolution(
      outcome: BattleOutcome.opponentVictory,
      originalPlayerTeam: playerTeam,
      originalOpponentTeam: opponentTeam,
      playerApplication: _MoveApplication.noop(
        userTeam: opponentApplication.targetTeam,
        targetTeam: opponentApplication.userTeam,
      ),
      opponentApplication: opponentApplication,
    );
  }

  BattleResolution _buildResolution({
    required BattleOutcome outcome,
    required BattleTeam originalPlayerTeam,
    required BattleTeam originalOpponentTeam,
    required _MoveApplication playerApplication,
    required _MoveApplication opponentApplication,
  }) {
    final trackedPlayerTeam = playerApplication.userTeam
        .recordRoundForCombatant(
          originalPlayerTeam.activeIndex,
          won: outcome == BattleOutcome.playerVictory,
        );
    final trackedOpponentTeam = opponentApplication.userTeam
        .recordRoundForCombatant(
          originalOpponentTeam.activeIndex,
          won: outcome == BattleOutcome.opponentVictory,
        );
    final playerEndTurn = _finishTurn(trackedPlayerTeam);
    final opponentEndTurn = _finishTurn(trackedOpponentTeam);
    final nextPlayerTeam = playerEndTurn.team;
    final nextOpponentTeam = opponentEndTurn.team;

    return BattleResolution(
      outcome: outcome,
      damageToPlayer: opponentApplication.activeDamage,
      damageToOpponent: playerApplication.activeDamage,
      playerTeam: nextPlayerTeam,
      opponentTeam: nextOpponentTeam,
      damagedPlayerIndexes: _damagedIndexes(
        before: originalPlayerTeam,
        after: nextPlayerTeam,
      ),
      damagedOpponentIndexes: _damagedIndexes(
        before: originalOpponentTeam,
        after: nextOpponentTeam,
      ),
      healingToPlayer: playerApplication.healing + playerEndTurn.healing,
      healingToOpponent: opponentApplication.healing + opponentEndTurn.healing,
      reserveDamageToPlayer: opponentApplication.reserveDamage,
      reserveDamageToOpponent: playerApplication.reserveDamage,
      playerSwapped:
          playerApplication.swapped ||
          opponentApplication.targetSwapped ||
          nextPlayerTeam.activeIndex != originalPlayerTeam.activeIndex,
      opponentSwapped:
          opponentApplication.swapped ||
          playerApplication.targetSwapped ||
          nextOpponentTeam.activeIndex != originalOpponentTeam.activeIndex,
      effectEvents: [
        ..._resolvedEffectEvents(
          playerApplication.effectEvents,
          userSide: BattleSide.player,
        ),
        ..._resolvedEffectEvents(
          opponentApplication.effectEvents,
          userSide: BattleSide.opponent,
        ),
        for (final event in playerEndTurn.effectEvents)
          BattleEffectEvent(
            side: BattleSide.player,
            combatantIndex: event.combatantIndex,
            type: event.type,
            amount: event.amount,
          ),
        for (final event in opponentEndTurn.effectEvents)
          BattleEffectEvent(
            side: BattleSide.opponent,
            combatantIndex: event.combatantIndex,
            type: event.type,
            amount: event.amount,
          ),
      ],
    );
  }

  List<BattleEffectEvent> _resolvedEffectEvents(
    List<_ApplicationEffectEvent> events, {
    required BattleSide userSide,
  }) {
    final targetSide = userSide == BattleSide.player
        ? BattleSide.opponent
        : BattleSide.player;
    return [
      for (final event in events)
        BattleEffectEvent(
          side: event.targetsUser ? userSide : targetSide,
          combatantIndex: event.combatantIndex,
          type: event.type,
          amount: event.amount,
        ),
    ];
  }

  ({BattleTeam team, double healing, List<_EndTurnEffectEvent> effectEvents})
  _finishTurn(BattleTeam team) {
    final effectEvents = <_EndTurnEffectEvent>[];
    var healing = 0.0;
    for (var index = 0; index < team.combatants.length; index++) {
      var combatant = team.combatants[index];
      for (final status in combatant.statuses) {
        if (status.justApplied) continue;
        if (status.type == StatusType.bleeding) {
          final damaged = combatant.takeDamage(
            combatant.maxHealth * 0.05 * status.stacks,
          );
          final damage = combatant.currentHealth - damaged.currentHealth;
          if (damage > 0) {
            effectEvents.add(
              _EndTurnEffectEvent(
                combatantIndex: index,
                type: BattleEffectType.bleedingDamage,
                amount: damage,
              ),
            );
          }
          combatant = damaged;
        } else if (status.type == StatusType.famine) {
          final reduced = combatant.reduceMaxHealth(10.0 * status.stacks);
          final lostMaxHealth = combatant.maxHealth - reduced.maxHealth;
          if (lostMaxHealth > 0) {
            effectEvents.add(
              _EndTurnEffectEvent(
                combatantIndex: index,
                type: BattleEffectType.famineMaxHealthLoss,
                amount: lostMaxHealth,
              ),
            );
          }
          combatant = reduced;
        } else if (status.type == StatusType.groundedRegeneration) {
          final healed = combatant.heal(30);
          final actualHealing = healed.currentHealth - combatant.currentHealth;
          if (actualHealing > 0) {
            healing += actualHealing;
            effectEvents.add(
              _EndTurnEffectEvent(
                combatantIndex: index,
                type: BattleEffectType.healing,
                amount: actualHealing,
              ),
            );
          }
          combatant = healed;
        }
      }
    }

    var nextTeam = team.tickStatuses();
    final active = nextTeam.active;

    if (!active.isDefeated &&
        active.equippedSpeciesCard == SpeciesCard.colossusAmongGiants) {
      final healthBeforeRegeneration = active.currentHealth;
      nextTeam = nextTeam.healActive(active.maxHealth * 0.08);
      final speciesHealing =
          nextTeam.active.currentHealth - healthBeforeRegeneration;
      healing += speciesHealing;
      if (speciesHealing > 0) {
        effectEvents.add(
          _EndTurnEffectEvent(
            combatantIndex: nextTeam.activeIndex,
            type: BattleEffectType.healing,
            amount: speciesHealing,
          ),
        );
      }
    }

    return (
      team: nextTeam.promoteIfActiveDefeated(),
      healing: healing,
      effectEvents: effectEvents,
    );
  }

  List<int> _damagedIndexes({
    required BattleTeam before,
    required BattleTeam after,
  }) {
    return [
      for (var index = 0; index < before.combatants.length; index++)
        if (after.combatants[index].currentHealth <
            before.combatants[index].currentHealth)
          index,
    ];
  }

  _MoveApplication _applyMove({
    required BattleTeam userTeam,
    required BattleTeam targetTeam,
    required ChampionMove move,
    required double potency,
    bool applySecondaryEffects = true,
    bool targetSwappedThisTurn = false,
    int? mixedChoiceOverride,
  }) {
    if (mixedChoiceOverride != null &&
        (mixedChoiceOverride < 0 || mixedChoiceOverride > 2)) {
      throw RangeError.range(mixedChoiceOverride, 0, 2, 'mixedChoiceOverride');
    }
    final resolutions =
        userTeam.active.equippedSpeciesCard == SpeciesCard.packPower ? 2 : 1;
    final mixedChoice = move.effect == MoveEffect.mixedChoice
        ? mixedChoiceOverride ?? _random.nextInt(3)
        : null;
    final mixedChoiceDamagesActive =
        applySecondaryEffects &&
        mixedChoice != null &&
        _mixedChoiceDamagesActive(move.mixedMoveChoice, mixedChoice);
    final coveredTargetIndex = targetTeam.activeIndex;
    final consumesTotalCover =
        targetTeam.active.hasStatus(StatusType.totalCover) &&
        (mixedChoiceDamagesActive ||
            _moveDamagesActive(move.effect, targetTeam));
    var aggregate = _MoveApplication.noop(
      userTeam: userTeam,
      targetTeam: targetTeam,
    );

    for (var resolution = 0; resolution < resolutions; resolution++) {
      final application = _applyMoveOnce(
        userTeam: aggregate.userTeam,
        targetTeam: aggregate.targetTeam,
        move: move,
        potency: potency,
        applySecondaryEffects: applySecondaryEffects,
        performSwap: resolution == resolutions - 1,
        targetSwappedThisTurn: targetSwappedThisTurn,
        mixedChoice: mixedChoice,
      );
      aggregate = application.copyWith(
        activeDamage: aggregate.activeDamage + application.activeDamage,
        reserveDamage: aggregate.reserveDamage + application.reserveDamage,
        healing: aggregate.healing + application.healing,
        swapped: aggregate.swapped || application.swapped,
        targetSwapped: aggregate.targetSwapped || application.targetSwapped,
        effectEvents: [...aggregate.effectEvents, ...application.effectEvents],
      );
    }

    if (consumesTotalCover) {
      aggregate = aggregate.copyWith(
        targetTeam: aggregate.targetTeam.removeStatusFromIndex(
          coveredTargetIndex,
          StatusType.totalCover,
        ),
      );
    }

    return aggregate;
  }

  _MoveApplication _applyMoveOnce({
    required BattleTeam userTeam,
    required BattleTeam targetTeam,
    required ChampionMove move,
    required double potency,
    required bool applySecondaryEffects,
    required bool performSwap,
    required bool targetSwappedThisTurn,
    required int? mixedChoice,
  }) {
    final mixedChoiceDamagesActive =
        applySecondaryEffects &&
        mixedChoice != null &&
        _mixedChoiceDamagesActive(move.mixedMoveChoice, mixedChoice);
    final blocksTargetSecondaryEffects =
        targetTeam.active.hasStatus(StatusType.totalCover) &&
        (mixedChoiceDamagesActive ||
            _moveDamagesActive(move.effect, targetTeam));
    final damagePotency = _speciesModifiedDamagePotency(
      attacker: userTeam.active,
      target: targetTeam.active,
      move: move,
      potency: potency,
      targetSwappedThisTurn: targetSwappedThisTurn,
    );
    final reservePotencyScale = move.potency == 0
        ? 1.0
        : potency / move.potency;
    final reserveDamagePotency = _speciesModifiedDamagePotency(
      attacker: userTeam.active,
      target: targetTeam.active,
      move: move,
      potency: move.reservePotency * reservePotencyScale,
      targetSwappedThisTurn: targetSwappedThisTurn,
    );
    final followUpPotencyScale = move.potency == 0
        ? 1.0
        : potency / move.potency;
    final followUpDamagePotency = _speciesModifiedDamagePotency(
      attacker: userTeam.active,
      target: targetTeam.active,
      move: move,
      potency: move.followUpPotency * followUpPotencyScale,
      targetSwappedThisTurn: targetSwappedThisTurn,
    );
    var application = switch (move.effect) {
      MoveEffect.none => _MoveApplication.noop(
        userTeam: userTeam,
        targetTeam: targetTeam,
      ),
      MoveEffect.damage => _damageActive(
        userTeam,
        targetTeam,
        damagePotency,
        move.isCritical,
      ),
      MoveEffect.drainHealth =>
        applySecondaryEffects
            ? _drainHealth(userTeam, targetTeam, damagePotency, move.isCritical)
            : _damageActive(
                userTeam,
                targetTeam,
                damagePotency,
                move.isCritical,
              ),
      MoveEffect.healSelf =>
        applySecondaryEffects
            ? _healSelf(userTeam, targetTeam, potency)
            : _MoveApplication.noop(userTeam: userTeam, targetTeam: targetTeam),
      MoveEffect.healTeam =>
        applySecondaryEffects
            ? _healTeam(userTeam, targetTeam, potency)
            : _MoveApplication.noop(userTeam: userTeam, targetTeam: targetTeam),
      MoveEffect.healTeamAndRedistributeHealth =>
        applySecondaryEffects
            ? _healTeamAndRedistributeHealth(userTeam, targetTeam, potency)
            : _MoveApplication.noop(userTeam: userTeam, targetTeam: targetTeam),
      MoveEffect.damageTeam => _damageTeam(
        userTeam,
        targetTeam,
        damagePotency,
        move.isCritical,
      ),
      MoveEffect.damageActiveAndReserves => _damageActiveAndReserves(
        userTeam,
        targetTeam,
        damagePotency,
        reserveDamagePotency,
        move.isCritical,
      ),
      MoveEffect.damageActiveAndRandomReserves =>
        _damageActiveAndRandomReserves(
          userTeam,
          targetTeam,
          damagePotency,
          reserveDamagePotency,
          followUpDamagePotency,
          move.isCritical,
        ),
      MoveEffect.damageReserve => _damageReserve(
        userTeam,
        targetTeam,
        damagePotency,
        move.isCritical,
      ),
      MoveEffect.damageReserveAndPromote => _damageReserveAndPromote(
        userTeam,
        targetTeam,
        damagePotency,
        move.isCritical,
      ),
      MoveEffect.damageSwapOpponentAndDamage =>
        applySecondaryEffects && !blocksTargetSecondaryEffects
            ? _damageSwapOpponentAndDamage(
                userTeam,
                targetTeam,
                damagePotency,
                followUpDamagePotency,
                move.isCritical,
              )
            : _damageActive(
                userTeam,
                targetTeam,
                damagePotency,
                move.isCritical,
              ),
      MoveEffect.forceOpponentSwap =>
        applySecondaryEffects
            ? _forceOpponentSwap(userTeam, targetTeam)
            : _MoveApplication.noop(userTeam: userTeam, targetTeam: targetTeam),
      MoveEffect.swapSelf =>
        applySecondaryEffects && performSwap
            ? _swapSelfAfterDamage(
                userTeam,
                targetTeam,
                damagePotency,
                move.isCritical,
              )
            : _damageActive(
                userTeam,
                targetTeam,
                damagePotency,
                move.isCritical,
              ),
      MoveEffect.damageTeamAndSwapSelf =>
        applySecondaryEffects && performSwap
            ? _swapSelfAfterTeamDamage(
                userTeam,
                targetTeam,
                damagePotency,
                move.isCritical,
              )
            : _damageTeam(userTeam, targetTeam, damagePotency, move.isCritical),
      MoveEffect.mixedChoice =>
        applySecondaryEffects
            ? _applyMixedChoice(
                userTeam,
                targetTeam,
                choice: mixedChoice!,
                choiceType: move.mixedMoveChoice,
                damagePotency: damagePotency,
                followUpDamagePotency: followUpDamagePotency,
                isCritical: move.isCritical,
                performSwap: performSwap,
              )
            : _MoveApplication.noop(userTeam: userTeam, targetTeam: targetTeam),
      MoveEffect.recklessDamage =>
        applySecondaryEffects
            ? _recklessDamage(
                userTeam,
                targetTeam,
                damagePotency,
                move.isCritical,
              )
            : _damageActive(
                userTeam,
                targetTeam,
                damagePotency,
                move.isCritical,
              ),
    };

    final shouldConsumeAlpha =
        userTeam.active.hasStatus(StatusType.alphaMomentum) &&
        (application.activeDamage > 0 || application.reserveDamage > 0);
    if (shouldConsumeAlpha) {
      application = application.copyWith(
        userTeam: application.userTeam.removeStatusFromActive(
          StatusType.alphaMomentum,
        ),
      );
    }

    if (applySecondaryEffects) {
      if (move.maxHealthGrowth > 0) {
        final healthBeforeGrowth = application.userTeam.active.currentHealth;
        final grownTeam = application.userTeam.growActiveMaxHealthOnce(
          move.maxHealthGrowth,
        );
        final actualGrowthHealing =
            grownTeam.active.currentHealth - healthBeforeGrowth;
        application = application.copyWith(
          userTeam: grownTeam,
          healing: application.healing + actualGrowthHealing,
          effectEvents: [
            ...application.effectEvents,
            if (actualGrowthHealing > 0)
              _ApplicationEffectEvent(
                targetsUser: true,
                combatantIndex: application.userTeam.activeIndex,
                type: BattleEffectType.healing,
                amount: actualGrowthHealing,
              ),
          ],
        );
      }
      if (move.selfHealing > 0) {
        final healthBeforeHealing = application.userTeam.active.currentHealth;
        final healedTeam = application.userTeam.healActive(move.selfHealing);
        final actualHealing =
            healedTeam.active.currentHealth - healthBeforeHealing;
        application = application.copyWith(
          userTeam: healedTeam,
          healing: application.healing + actualHealing,
          effectEvents: [
            ...application.effectEvents,
            if (actualHealing > 0)
              _ApplicationEffectEvent(
                targetsUser: true,
                combatantIndex: application.userTeam.activeIndex,
                type: BattleEffectType.healing,
                amount: actualHealing,
              ),
          ],
        );
      }
      if (move.cleansesHarmfulStatuses) {
        application = application.copyWith(
          userTeam: application.userTeam.clearHarmfulStatusesFromActive(),
        );
      }
      if (move.selfDamage > 0) {
        final healthBeforeDamage = application.userTeam.active.currentHealth;
        final damagedTeam = application.userTeam.damageActive(move.selfDamage);
        final actualDamage =
            healthBeforeDamage - damagedTeam.active.currentHealth;
        application = application.copyWith(
          userTeam: damagedTeam,
          effectEvents: [
            ...application.effectEvents,
            if (actualDamage > 0)
              _ApplicationEffectEvent(
                targetsUser: true,
                combatantIndex: application.userTeam.activeIndex,
                type: BattleEffectType.selfDamage,
                amount: actualDamage,
              ),
          ],
        );
      }
    }

    if (applySecondaryEffects) {
      if (move.transfersHarmfulStatusesToOpponent) {
        application = _transferHarmfulStatuses(
          application,
          blockTargetEffects: blocksTargetSecondaryEffects,
        );
      }
      final canApplyMoveStatuses =
          move.companionEffect != CompanionMoveEffect.sacrificeRandom ||
          application.userTeam.active.companions.isNotEmpty;
      if (canApplyMoveStatuses) {
        application = _applyStatuses(
          application,
          move.statusApplications,
          isCritical: move.isCritical,
          attackerSpeciesCard: userTeam.active.equippedSpeciesCard,
          blockOpponentEffects: blocksTargetSecondaryEffects,
        );
      }
      if (move.randomHarmfulStatusCount > 0) {
        final availableStatuses = [..._randomHarmfulStatuses];
        final randomStatuses = <StatusApplication>[];
        for (
          var index = 0;
          index < move.randomHarmfulStatusCount && availableStatuses.isNotEmpty;
          index++
        ) {
          randomStatuses.add(
            StatusApplication(
              type: availableStatuses.removeAt(
                _random.nextInt(availableStatuses.length),
              ),
              target: StatusTarget.opponent,
            ),
          );
        }
        application = _applyStatuses(
          application,
          randomStatuses,
          isCritical: move.isCritical,
          attackerSpeciesCard: userTeam.active.equippedSpeciesCard,
          blockOpponentEffects: blocksTargetSecondaryEffects,
        );
      }
      if (move.randomBeneficialStatusCount > 0) {
        final availableStatuses = [..._randomBeneficialStatuses];
        final randomStatuses = <StatusApplication>[];
        for (
          var index = 0;
          index < move.randomBeneficialStatusCount &&
              availableStatuses.isNotEmpty;
          index++
        ) {
          randomStatuses.add(
            StatusApplication(
              type: availableStatuses.removeAt(
                _random.nextInt(availableStatuses.length),
              ),
              target: StatusTarget.self,
            ),
          );
        }
        application = _applyStatuses(
          application,
          randomStatuses,
          isCritical: move.isCritical,
          attackerSpeciesCard: userTeam.active.equippedSpeciesCard,
          blockOpponentEffects: false,
        );
      }
      application = _applyCompanionMoveEffect(
        application,
        move.companionEffect,
        originalBearerIndex: userTeam.activeIndex,
        blockTargetEffects: blocksTargetSecondaryEffects,
      );
      if (move.clearsOpponentCompanions && !blocksTargetSecondaryEffects) {
        application = application.copyWith(
          targetTeam: application.targetTeam.removeAllCompanionsFromActive(),
        );
      }
    }

    final bleedingStacks =
        userTeam.active.companionCount(Companion.didelphodon) *
        userTeam.active.companionEffectMultiplier.round();
    if (applySecondaryEffects &&
        !blocksTargetSecondaryEffects &&
        (_dealsDamage(move.effect) ||
            application.activeDamage > 0 ||
            application.reserveDamage > 0) &&
        bleedingStacks > 0) {
      application = application.copyWith(
        targetTeam: application.targetTeam.applyEnemyStatusToActive(
          StatusApplication(
            type: StatusType.bleeding,
            target: StatusTarget.opponent,
            stacks: bleedingStacks,
          ),
        ),
      );
    }
    return application;
  }

  _MoveApplication _damageActive(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    return _damageTarget(
      userTeam,
      targetTeam,
      targetTeam.activeIndex,
      potency,
      isCritical,
    );
  }

  _MoveApplication _drainHealth(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    final damageApplication = _damageActive(
      userTeam,
      targetTeam,
      potency,
      isCritical,
    );
    final requestedHealing = damageApplication.activeDamage / 2;
    final healthBeforeHealing = damageApplication.userTeam.active.currentHealth;
    final healedTeam = damageApplication.userTeam.healActive(requestedHealing);
    final healing = healedTeam.active.currentHealth - healthBeforeHealing;
    return damageApplication.copyWith(
      userTeam: healedTeam,
      healing: healing,
      effectEvents: [
        ...damageApplication.effectEvents,
        if (healing > 0)
          _ApplicationEffectEvent(
            targetsUser: true,
            combatantIndex: damageApplication.userTeam.activeIndex,
            type: BattleEffectType.healing,
            amount: healing,
          ),
      ],
    );
  }

  _MoveApplication _healSelf(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    final healthBeforeHealing = userTeam.active.currentHealth;
    final healedTeam = userTeam.healActive(potency);
    final healing = healedTeam.active.currentHealth - healthBeforeHealing;
    return _MoveApplication(
      userTeam: healedTeam,
      targetTeam: targetTeam,
      healing: healing,
      effectEvents: [
        if (healing > 0)
          _ApplicationEffectEvent(
            targetsUser: true,
            combatantIndex: userTeam.activeIndex,
            type: BattleEffectType.healing,
            amount: healing,
          ),
      ],
    );
  }

  _MoveApplication _healTeam(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    var healedTeam = userTeam;
    var healing = 0.0;
    final effectEvents = <_ApplicationEffectEvent>[];
    for (var index = 0; index < userTeam.combatants.length; index++) {
      final healthBeforeHealing = healedTeam.combatants[index].currentHealth;
      healedTeam = healedTeam.healCombatant(index, potency);
      final actualHealing =
          healedTeam.combatants[index].currentHealth - healthBeforeHealing;
      healing += actualHealing;
      if (actualHealing > 0) {
        effectEvents.add(
          _ApplicationEffectEvent(
            targetsUser: true,
            combatantIndex: index,
            type: BattleEffectType.healing,
            amount: actualHealing,
          ),
        );
      }
    }
    return _MoveApplication(
      userTeam: healedTeam,
      targetTeam: targetTeam,
      healing: healing,
      effectEvents: effectEvents,
    );
  }

  _MoveApplication _healTeamAndRedistributeHealth(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    final healingApplication = _healTeam(userTeam, targetTeam, potency);
    return healingApplication.copyWith(
      userTeam: healingApplication.userTeam.redistributeCurrentHealthEvenly(),
    );
  }

  _MoveApplication _damageTeam(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    var nextUserTeam = userTeam;
    var nextTargetTeam = targetTeam;
    var activeDamage = 0.0;
    var reserveDamage = 0.0;
    final effectEvents = <_ApplicationEffectEvent>[];

    for (var index = 0; index < targetTeam.combatants.length; index++) {
      final application = _damageTarget(
        nextUserTeam,
        nextTargetTeam,
        index,
        potency,
        isCritical,
      );
      nextUserTeam = application.userTeam;
      nextTargetTeam = application.targetTeam;
      activeDamage += application.activeDamage;
      reserveDamage += application.reserveDamage;
      effectEvents.addAll(application.effectEvents);
    }

    return _MoveApplication(
      userTeam: nextUserTeam,
      targetTeam: nextTargetTeam,
      activeDamage: activeDamage,
      reserveDamage: reserveDamage,
      effectEvents: effectEvents,
    );
  }

  _MoveApplication _damageActiveAndReserves(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double activePotency,
    double reservePotency,
    bool isCritical,
  ) {
    var nextUserTeam = userTeam;
    var nextTargetTeam = targetTeam;
    var activeDamage = 0.0;
    var reserveDamage = 0.0;
    final effectEvents = <_ApplicationEffectEvent>[];

    for (var index = 0; index < targetTeam.combatants.length; index++) {
      final application = _damageTarget(
        nextUserTeam,
        nextTargetTeam,
        index,
        index == targetTeam.activeIndex ? activePotency : reservePotency,
        isCritical,
      );
      nextUserTeam = application.userTeam;
      nextTargetTeam = application.targetTeam;
      activeDamage += application.activeDamage;
      reserveDamage += application.reserveDamage;
      effectEvents.addAll(application.effectEvents);
    }

    return _MoveApplication(
      userTeam: nextUserTeam,
      targetTeam: nextTargetTeam,
      activeDamage: activeDamage,
      reserveDamage: reserveDamage,
      effectEvents: effectEvents,
    );
  }

  _MoveApplication _damageActiveAndRandomReserves(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double activePotency,
    double firstReservePotency,
    double secondReservePotency,
    bool isCritical,
  ) {
    var application = _damageActive(
      userTeam,
      targetTeam,
      activePotency,
      isCritical,
    );
    final activeDamage = application.activeDamage;
    final reserveIndexes = [...targetTeam.swapIndexes];
    var reserveDamage = 0.0;
    final effectEvents = [...application.effectEvents];

    for (final potency in [firstReservePotency, secondReservePotency]) {
      if (reserveIndexes.isEmpty || potency <= 0) break;
      final targetIndex = reserveIndexes.removeAt(
        _random.nextInt(reserveIndexes.length),
      );
      final reserveApplication = _damageTarget(
        application.userTeam,
        application.targetTeam,
        targetIndex,
        potency,
        isCritical,
      );
      application = reserveApplication;
      reserveDamage += reserveApplication.reserveDamage;
      effectEvents.addAll(reserveApplication.effectEvents);
    }

    return application.copyWith(
      activeDamage: activeDamage,
      reserveDamage: reserveDamage,
      effectEvents: effectEvents,
    );
  }

  _MoveApplication _damageReserve(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    return _damageTarget(
      userTeam,
      targetTeam,
      targetTeam.firstReserveIndex ?? targetTeam.activeIndex,
      potency,
      isCritical,
    );
  }

  _MoveApplication _damageReserveAndPromote(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    final targetIndex = targetTeam.firstReserveIndex ?? targetTeam.activeIndex;
    final damageApplication = _damageTarget(
      userTeam,
      targetTeam,
      targetIndex,
      potency,
      isCritical,
    );
    final canPromoteTarget =
        targetIndex != targetTeam.activeIndex &&
        !damageApplication.targetTeam.combatants[targetIndex].isDefeated;
    return damageApplication.copyWith(
      targetTeam: canPromoteTarget
          ? damageApplication.targetTeam.swapTo(targetIndex)
          : damageApplication.targetTeam,
      targetSwapped: canPromoteTarget,
    );
  }

  _MoveApplication _damageSwapOpponentAndDamage(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double initialPotency,
    double followUpPotency,
    bool isCritical,
  ) {
    final initialApplication = _damageActive(
      userTeam,
      targetTeam,
      initialPotency,
      isCritical,
    );
    final swapApplication = _forceOpponentSwap(
      initialApplication.userTeam,
      initialApplication.targetTeam,
    );
    final followUpApplication = _damageActive(
      swapApplication.userTeam,
      swapApplication.targetTeam,
      followUpPotency,
      isCritical,
    );
    return followUpApplication.copyWith(
      activeDamage:
          initialApplication.activeDamage + followUpApplication.activeDamage,
      reserveDamage:
          initialApplication.reserveDamage + followUpApplication.reserveDamage,
      targetSwapped: swapApplication.targetSwapped,
      effectEvents: [
        ...initialApplication.effectEvents,
        ...followUpApplication.effectEvents,
      ],
    );
  }

  _MoveApplication _forceOpponentSwap(
    BattleTeam userTeam,
    BattleTeam targetTeam,
  ) {
    final canSwap = targetTeam.swapIndexes.isNotEmpty;
    return _MoveApplication(
      userTeam: userTeam,
      targetTeam: canSwap ? targetTeam.swapToFirstReserve() : targetTeam,
      targetSwapped: canSwap,
    );
  }

  _MoveApplication _forceOpponentRandomSwap(
    BattleTeam userTeam,
    BattleTeam targetTeam,
  ) {
    final candidates = targetTeam.swapIndexes;
    if (candidates.isEmpty) {
      return _MoveApplication.noop(userTeam: userTeam, targetTeam: targetTeam);
    }
    return _MoveApplication(
      userTeam: userTeam,
      targetTeam: targetTeam.swapTo(
        candidates[_random.nextInt(candidates.length)],
      ),
      targetSwapped: true,
    );
  }

  _MoveApplication _applyMixedChoice(
    BattleTeam userTeam,
    BattleTeam targetTeam, {
    required int choice,
    required MixedMoveChoice choiceType,
    required double damagePotency,
    required double followUpDamagePotency,
    required bool isCritical,
    required bool performSwap,
  }) {
    if (choiceType == MixedMoveChoice.arborealVersatility) {
      return _applyArborealVersatility(
        userTeam,
        targetTeam,
        choice: choice,
        damagePotency: damagePotency,
        swapDamagePotency: followUpDamagePotency,
        isCritical: isCritical,
        performSwap: performSwap,
      );
    }

    if (choice == 0) {
      return _healTeam(userTeam, targetTeam, 10);
    }
    if (choice == 1) {
      return performSwap
          ? _swapSelfAfterDamage(
              userTeam,
              targetTeam,
              damagePotency,
              isCritical,
            )
          : _damageActive(userTeam, targetTeam, damagePotency, isCritical);
    }

    final swapApplication = _forceOpponentRandomSwap(userTeam, targetTeam);
    return _applyStatuses(
      swapApplication,
      const [
        StatusApplication(
          type: StatusType.famine,
          target: StatusTarget.opponent,
        ),
      ],
      isCritical: isCritical,
      attackerSpeciesCard: userTeam.active.equippedSpeciesCard,
      blockOpponentEffects: false,
    );
  }

  _MoveApplication _applyArborealVersatility(
    BattleTeam userTeam,
    BattleTeam targetTeam, {
    required int choice,
    required double damagePotency,
    required double swapDamagePotency,
    required bool isCritical,
    required bool performSwap,
  }) {
    if (choice == 0) {
      return _damageActive(userTeam, targetTeam, damagePotency, isCritical);
    }
    if (choice == 1) {
      final healingApplication = _healSelf(userTeam, targetTeam, 20);
      return healingApplication.copyWith(
        userTeam: healingApplication.userTeam.clearHarmfulStatusesFromActive(),
      );
    }

    final swapApplication = performSwap
        ? _swapSelfAfterDamage(
            userTeam,
            targetTeam,
            swapDamagePotency,
            isCritical,
          )
        : _damageActive(userTeam, targetTeam, swapDamagePotency, isCritical);
    if (!swapApplication.swapped) return swapApplication;
    return swapApplication.copyWith(
      userTeam: swapApplication.userTeam.applyStatusToActive(
        const StatusApplication(
          type: StatusType.alphaMomentum,
          target: StatusTarget.self,
        ),
      ),
    );
  }

  bool _mixedChoiceDamagesActive(MixedMoveChoice choiceType, int choice) {
    return switch (choiceType) {
      MixedMoveChoice.falseEvolution => choice == 1,
      MixedMoveChoice.arborealVersatility => choice == 0 || choice == 2,
    };
  }

  _MoveApplication _swapSelfAfterDamage(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    final damageApplication = _damageActive(
      userTeam,
      targetTeam,
      potency,
      isCritical,
    );
    return damageApplication.copyWith(
      userTeam: damageApplication.userTeam.swapToFirstReserve(),
      swapped: damageApplication.userTeam.swapIndexes.isNotEmpty,
    );
  }

  _MoveApplication _swapSelfAfterTeamDamage(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    final damageApplication = _damageTeam(
      userTeam,
      targetTeam,
      potency,
      isCritical,
    );
    return damageApplication.copyWith(
      userTeam: damageApplication.userTeam.swapToFirstReserve(),
      swapped: damageApplication.userTeam.swapIndexes.isNotEmpty,
    );
  }

  _MoveApplication _recklessDamage(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
    bool isCritical,
  ) {
    final damageApplication = _damageActive(
      userTeam,
      targetTeam,
      potency,
      isCritical,
    );
    final healthBeforeRecoil = damageApplication.userTeam.active.currentHealth;
    final recoiledTeam = damageApplication.userTeam.damageActive(
      damageApplication.activeDamage / 3,
    );
    final recoilDamage = healthBeforeRecoil - recoiledTeam.active.currentHealth;
    return damageApplication.copyWith(
      userTeam: recoiledTeam,
      effectEvents: [
        ...damageApplication.effectEvents,
        if (recoilDamage > 0)
          _ApplicationEffectEvent(
            targetsUser: true,
            combatantIndex: damageApplication.userTeam.activeIndex,
            type: BattleEffectType.recoilDamage,
            amount: recoilDamage,
          ),
      ],
    );
  }

  _MoveApplication _damageTarget(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    int targetIndex,
    double potency,
    bool isCritical,
  ) {
    final target = targetTeam.combatants[targetIndex];
    var modifiedDamage = _modifiedDamage(
      attacker: userTeam.active,
      defender: target,
      potency: potency,
    );
    if (isCritical &&
        targetIndex == targetTeam.activeIndex &&
        target.equippedSpeciesCard == SpeciesCard.sourceOfLife) {
      modifiedDamage *= 0.34;
    }

    final damagedTarget = target.takeDamage(modifiedDamage);
    final actualDamage = target.currentHealth - damagedTarget.currentHealth;
    var nextUserTeam = userTeam;
    final nextTargetTeam = targetTeam.replaceCombatant(
      targetIndex,
      damagedTarget,
    );

    var reflectedDamage = 0.0;
    if (actualDamage > 0 && target.hasStatus(StatusType.jaggedScales)) {
      final henodusCopies = target.companionCount(Companion.henodus);
      final reflectedFraction = henodusCopies > 0
          ? 0.33 * henodusCopies * target.companionEffectMultiplier
          : 0.33;
      final attackerHealthBeforeReflection = nextUserTeam.active.currentHealth;
      nextUserTeam = nextUserTeam.damageActive(
        actualDamage * reflectedFraction,
      );
      reflectedDamage =
          attackerHealthBeforeReflection - nextUserTeam.active.currentHealth;
    }

    return _MoveApplication(
      userTeam: nextUserTeam,
      targetTeam: nextTargetTeam,
      activeDamage: targetIndex == targetTeam.activeIndex ? actualDamage : 0,
      reserveDamage: targetIndex == targetTeam.activeIndex ? 0 : actualDamage,
      effectEvents: [
        if (actualDamage > 0)
          _ApplicationEffectEvent(
            targetsUser: false,
            combatantIndex: targetIndex,
            type: BattleEffectType.combatDamage,
            amount: actualDamage,
          ),
        if (reflectedDamage > 0)
          _ApplicationEffectEvent(
            targetsUser: true,
            combatantIndex: userTeam.activeIndex,
            type: BattleEffectType.jaggedScalesDamage,
            amount: reflectedDamage,
          ),
      ],
    );
  }

  _MoveApplication _transferHarmfulStatuses(
    _MoveApplication application, {
    required bool blockTargetEffects,
  }) {
    final harmfulStatuses = application.userTeam.active.statuses
        .where((status) => status.type.isHarmful)
        .toList(growable: false);
    final target = application.targetTeam.active;
    if (harmfulStatuses.isEmpty ||
        blockTargetEffects ||
        target.hasStatus(StatusType.secondaryImmunity) ||
        target.hasCompanion(Companion.simosuchus)) {
      return application;
    }

    var targetTeam = application.targetTeam;
    for (final status in harmfulStatuses) {
      targetTeam = targetTeam.applyEnemyStatusToActive(
        StatusApplication(
          type: status.type,
          target: StatusTarget.opponent,
          stacks: status.stacks,
          durationTurns: status.remainingTurns,
          permanent: status.remainingTurns == null,
          delayFirstTick: status.justApplied,
        ),
      );
    }
    return application.copyWith(
      userTeam: application.userTeam.clearHarmfulStatusesFromActive(),
      targetTeam: targetTeam,
    );
  }

  _MoveApplication _applyStatuses(
    _MoveApplication application,
    List<StatusApplication> statusApplications, {
    required bool isCritical,
    required SpeciesCard? attackerSpeciesCard,
    required bool blockOpponentEffects,
  }) {
    var nextApplication = application;

    for (final statusApplication in statusApplications) {
      if (blockOpponentEffects &&
          (statusApplication.target == StatusTarget.opponent ||
              statusApplication.target == StatusTarget.opponentTeam)) {
        continue;
      }
      final adjustedApplication = _adjustStatusApplication(
        statusApplication,
        isCritical: isCritical,
        attackerSpeciesCard: attackerSpeciesCard,
        targetTeam: nextApplication.targetTeam,
      );
      nextApplication = switch (adjustedApplication.target) {
        StatusTarget.self => nextApplication.copyWith(
          userTeam: nextApplication.userTeam.applyStatusToActive(
            adjustedApplication,
          ),
        ),
        StatusTarget.selfTeam => nextApplication.copyWith(
          userTeam: nextApplication.userTeam.applyStatusToAll(
            adjustedApplication,
          ),
        ),
        StatusTarget.opponent => nextApplication.copyWith(
          targetTeam: nextApplication.targetTeam.applyEnemyStatusToActive(
            adjustedApplication,
          ),
        ),
        StatusTarget.opponentTeam => nextApplication.copyWith(
          targetTeam: nextApplication.targetTeam.applyEnemyStatusToAll(
            adjustedApplication,
          ),
        ),
      };
    }

    return nextApplication;
  }

  StatusApplication _adjustStatusApplication(
    StatusApplication application, {
    required bool isCritical,
    required SpeciesCard? attackerSpeciesCard,
    required BattleTeam targetTeam,
  }) {
    final baseDuration = application.resolvedDurationTurns;
    if (!isCritical || baseDuration == null) return application;

    var duration = baseDuration;
    if (attackerSpeciesCard == SpeciesCard.shadowHunter) {
      duration += 2;
    }
    if ((application.target == StatusTarget.opponent ||
            application.target == StatusTarget.opponentTeam) &&
        targetTeam.active.equippedSpeciesCard == SpeciesCard.sourceOfLife) {
      duration = 1;
    }

    return StatusApplication(
      type: application.type,
      target: application.target,
      stacks: application.stacks,
      durationTurns: duration,
      permanent: application.permanent,
      delayFirstTick: application.delayFirstTick,
    );
  }

  double _speciesModifiedDamagePotency({
    required Combatant attacker,
    required Combatant target,
    required ChampionMove move,
    required double potency,
    required bool targetSwappedThisTurn,
  }) {
    if (!_dealsDamage(move.effect) && move.effect != MoveEffect.mixedChoice) {
      return potency;
    }

    final conditionalPotency = targetSwappedThisTurn
        ? move.bonusPotencyIfTargetSwapped
        : 0;
    final bleedingPotency = target.hasStatus(StatusType.bleeding)
        ? move.bonusPotencyIfTargetBleeding
        : 0;
    final roundPotency =
        attacker.roundsWithoutWinning * move.bonusPotencyPerRoundWithoutWinning;
    final lowHealthPotency = attacker.currentHealth <= attacker.maxHealth / 2
        ? move.bonusPotencyIfAtOrBelowHalfHealth
        : 0;
    final dragonflyPotency = attacker.companionValue(
      10.0 * attacker.companionCount(Companion.dragonfly),
    );
    final criticalCompanionPotency = move.isCritical
        ? attacker.companionValue(
            30.0 * attacker.companionCount(Companion.longisquama),
          )
        : 0;
    var multiplier = 1.0;
    if (attacker.equippedSpeciesCard == SpeciesCard.superPredator) {
      multiplier *= 1.5;
    }
    if (move.isCritical &&
        attacker.equippedSpeciesCard == SpeciesCard.shadowHunter) {
      multiplier *= 1.66;
    }
    return (potency +
            conditionalPotency +
            bleedingPotency +
            roundPotency +
            lowHealthPotency +
            dragonflyPotency +
            criticalCompanionPotency) *
        multiplier;
  }

  double _victoryCompanionHealing(Combatant bearer) {
    return bearer.companionValue(
      10.0 * bearer.companionCount(Companion.iberomesornis),
    );
  }

  _MoveApplication _applyVictoryHealing(
    _MoveApplication application, {
    required int bearerIndex,
    required double amount,
  }) {
    if (amount <= 0 ||
        application.userTeam.combatants[bearerIndex].isDefeated) {
      return application;
    }
    final beforeHealth =
        application.userTeam.combatants[bearerIndex].currentHealth;
    final healedTeam = application.userTeam.healCombatant(bearerIndex, amount);
    final actualHealing =
        healedTeam.combatants[bearerIndex].currentHealth - beforeHealth;
    return application.copyWith(
      userTeam: healedTeam,
      healing: application.healing + actualHealing,
      effectEvents: [
        ...application.effectEvents,
        if (actualHealing > 0)
          _ApplicationEffectEvent(
            targetsUser: true,
            combatantIndex: bearerIndex,
            type: BattleEffectType.healing,
            amount: actualHealing,
          ),
      ],
    );
  }

  _MoveApplication _applyCompanionMoveEffect(
    _MoveApplication application,
    CompanionMoveEffect effect, {
    required int originalBearerIndex,
    required bool blockTargetEffects,
  }) {
    if (blockTargetEffects && effect == CompanionMoveEffect.stealRandom) {
      return application;
    }

    final nextApplication = switch (effect) {
      CompanionMoveEffect.none => application,
      CompanionMoveEffect.summonRandom => _summonCompanion(
        application,
        originalBearerIndex,
      ),
      CompanionMoveEffect.stealRandom => _stealCompanion(
        application,
        originalBearerIndex,
      ),
      CompanionMoveEffect.transferOnSwap => _transferCompanionsAfterSwap(
        application,
        originalBearerIndex,
      ),
      CompanionMoveEffect.sacrificeRandom => _sacrificeCompanion(
        application,
        originalBearerIndex,
      ),
    };
    return blockTargetEffects
        ? nextApplication.copyWith(targetTeam: application.targetTeam)
        : nextApplication;
  }

  _MoveApplication _summonCompanion(
    _MoveApplication application,
    int bearerIndex,
  ) {
    final companion = _companionRandomizer.chooseAppearing(
      beetleBlocked:
          application.userTeam.active.hasCompanion(Companion.beetle) ||
          application.targetTeam.active.hasCompanion(Companion.beetle),
    );
    return companion == null
        ? application
        : _attachCompanion(application, bearerIndex, companion);
  }

  _MoveApplication _stealCompanion(
    _MoveApplication application,
    int bearerIndex,
  ) {
    final targetIndex = application.targetTeam.activeIndex;
    final companion = _companionRandomizer.chooseFrom(
      application.targetTeam.combatants[targetIndex].companions,
    );
    if (companion == null) return application;

    final targetTeam = application.targetTeam.removeCompanion(
      bearerIndex: targetIndex,
      companion: companion,
    );
    return _attachCompanion(
      application.copyWith(targetTeam: targetTeam),
      bearerIndex,
      companion,
    );
  }

  _MoveApplication _sacrificeCompanion(
    _MoveApplication application,
    int bearerIndex,
  ) {
    final companion = _companionRandomizer.chooseFrom(
      application.userTeam.combatants[bearerIndex].companions,
    );
    if (companion == null) return application;

    return application.copyWith(
      userTeam: application.userTeam.removeCompanion(
        bearerIndex: bearerIndex,
        companion: companion,
      ),
    );
  }

  _MoveApplication _transferCompanionsAfterSwap(
    _MoveApplication application,
    int originalBearerIndex,
  ) {
    if (!application.swapped ||
        application.userTeam.activeIndex == originalBearerIndex) {
      return application;
    }
    final transferredCompanions =
        application.userTeam.combatants[originalBearerIndex].companions;
    final transferredTeam = application.userTeam.transferCompanions(
      fromIndex: originalBearerIndex,
      toIndex: application.userTeam.activeIndex,
      activateEffectsImmediately: false,
    );
    final transferredApplication = application.copyWith(
      userTeam: transferredTeam,
    );
    return transferredCompanions.any(
          (companion) =>
              companion == Companion.weta || companion == Companion.beetle,
        )
        ? _applyFamineFromBearer(
            transferredApplication,
            transferredTeam.activeIndex,
            delayFirstTick: transferredCompanions.contains(Companion.weta),
          )
        : transferredApplication;
  }

  _MoveApplication _attachCompanion(
    _MoveApplication application,
    int bearerIndex,
    Companion companion,
  ) {
    final beforeBearer = application.userTeam.combatants[bearerIndex];
    final userTeam = application.userTeam.addCompanion(
      bearerIndex: bearerIndex,
      companion: companion,
      activateEffectsImmediately: false,
    );
    final afterBearer = userTeam.combatants[bearerIndex];
    if (afterBearer.companions.length == beforeBearer.companions.length) {
      return application;
    }

    final attachedApplication = application.copyWith(userTeam: userTeam);
    return companion == Companion.weta || companion == Companion.beetle
        ? _applyFamineFromBearer(
            attachedApplication,
            bearerIndex,
            delayFirstTick: companion == Companion.weta,
          )
        : attachedApplication;
  }

  _MoveApplication _applyFamineFromBearer(
    _MoveApplication application,
    int bearerIndex, {
    required bool delayFirstTick,
  }) {
    final bearer = application.userTeam.combatants[bearerIndex];
    final famineStacks =
        (bearer.companionCount(Companion.weta) *
                bearer.companionEffectMultiplier)
            .round();
    if (famineStacks <= 0) return application;

    return application.copyWith(
      targetTeam: application.targetTeam.applyStatusToActive(
        StatusApplication(
          type: StatusType.famine,
          target: StatusTarget.opponent,
          stacks: famineStacks,
          permanent: true,
          delayFirstTick: delayFirstTick,
        ),
      ),
    );
  }

  bool _dealsDamage(MoveEffect effect) => switch (effect) {
    MoveEffect.damage ||
    MoveEffect.drainHealth ||
    MoveEffect.damageTeam ||
    MoveEffect.damageActiveAndReserves ||
    MoveEffect.damageActiveAndRandomReserves ||
    MoveEffect.damageReserve ||
    MoveEffect.damageReserveAndPromote ||
    MoveEffect.damageSwapOpponentAndDamage ||
    MoveEffect.swapSelf ||
    MoveEffect.damageTeamAndSwapSelf ||
    MoveEffect.recklessDamage => true,
    MoveEffect.none ||
    MoveEffect.healSelf ||
    MoveEffect.healTeam ||
    MoveEffect.healTeamAndRedistributeHealth ||
    MoveEffect.forceOpponentSwap ||
    MoveEffect.mixedChoice => false,
  };

  bool _moveDamagesActive(MoveEffect effect, BattleTeam targetTeam) {
    return switch (effect) {
      MoveEffect.damage ||
      MoveEffect.drainHealth ||
      MoveEffect.damageTeam ||
      MoveEffect.damageActiveAndReserves ||
      MoveEffect.damageActiveAndRandomReserves ||
      MoveEffect.damageSwapOpponentAndDamage ||
      MoveEffect.swapSelf ||
      MoveEffect.damageTeamAndSwapSelf ||
      MoveEffect.recklessDamage => true,
      MoveEffect.damageReserve || MoveEffect.damageReserveAndPromote =>
        targetTeam.firstReserveIndex == null,
      MoveEffect.none ||
      MoveEffect.healSelf ||
      MoveEffect.healTeam ||
      MoveEffect.healTeamAndRedistributeHealth ||
      MoveEffect.forceOpponentSwap ||
      MoveEffect.mixedChoice => false,
    };
  }

  double _modifiedDamage({
    required Combatant attacker,
    required Combatant defender,
    required double potency,
  }) {
    var multiplier = 1.0;

    if (attacker.hasStatus(StatusType.intimidation)) multiplier *= 0.7;
    if (attacker.hasStatus(StatusType.alphaMomentum)) multiplier *= 1.5;
    if (defender.hasStatus(StatusType.brokenBone)) multiplier *= 1.3;
    if (defender.hasStatus(StatusType.protectiveScales)) multiplier *= 0.7;
    if (defender.hasStatus(StatusType.totalCover)) multiplier *= 0.5;
    if (defender.hasStatus(StatusType.groundedRegeneration)) multiplier *= 0.5;

    return potency * multiplier;
  }
}

class _MoveApplication {
  _MoveApplication({
    required this.userTeam,
    required this.targetTeam,
    this.activeDamage = 0,
    this.reserveDamage = 0,
    this.healing = 0,
    this.swapped = false,
    this.targetSwapped = false,
    List<_ApplicationEffectEvent> effectEvents = const [],
  }) : effectEvents = List.unmodifiable(effectEvents);

  factory _MoveApplication.noop({
    required BattleTeam userTeam,
    required BattleTeam targetTeam,
  }) {
    return _MoveApplication(userTeam: userTeam, targetTeam: targetTeam);
  }

  final BattleTeam userTeam;
  final BattleTeam targetTeam;
  final double activeDamage;
  final double reserveDamage;
  final double healing;
  final bool swapped;
  final bool targetSwapped;
  final List<_ApplicationEffectEvent> effectEvents;

  _MoveApplication copyWith({
    BattleTeam? userTeam,
    BattleTeam? targetTeam,
    double? activeDamage,
    double? reserveDamage,
    double? healing,
    bool? swapped,
    bool? targetSwapped,
    List<_ApplicationEffectEvent>? effectEvents,
  }) {
    return _MoveApplication(
      userTeam: userTeam ?? this.userTeam,
      targetTeam: targetTeam ?? this.targetTeam,
      activeDamage: activeDamage ?? this.activeDamage,
      reserveDamage: reserveDamage ?? this.reserveDamage,
      healing: healing ?? this.healing,
      swapped: swapped ?? this.swapped,
      targetSwapped: targetSwapped ?? this.targetSwapped,
      effectEvents: effectEvents ?? this.effectEvents,
    );
  }

  _MoveApplication mergeUserTeam(BattleTeam userTeam) {
    return copyWith(userTeam: userTeam);
  }
}

class _ApplicationEffectEvent {
  const _ApplicationEffectEvent({
    required this.targetsUser,
    required this.combatantIndex,
    required this.type,
    required this.amount,
  });

  final bool targetsUser;
  final int combatantIndex;
  final BattleEffectType type;
  final double amount;
}

class _EndTurnEffectEvent {
  const _EndTurnEffectEvent({
    required this.combatantIndex,
    required this.type,
    required this.amount,
  });

  final int combatantIndex;
  final BattleEffectType type;
  final double amount;
}

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
  });

  BattleResolution resolveGuaranteedOpponentMove({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleGesture opponentGesture,
  });
}

class StandardBattleRules implements BattleRules {
  StandardBattleRules({required CompanionRandomizer companionRandomizer})
    : _companionRandomizer = companionRandomizer;

  final CompanionRandomizer _companionRandomizer;

  @override
  BattleResolution resolve({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleGesture playerGesture,
    required BattleGesture opponentGesture,
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
    final playerEndTurn = _finishTurn(playerApplication.userTeam);
    final opponentEndTurn = _finishTurn(opponentApplication.userTeam);
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
        }
      }
    }

    var nextTeam = team.tickStatuses();
    var healing = 0.0;
    final active = nextTeam.active;

    if (!active.isDefeated &&
        active.equippedSpeciesCard == SpeciesCard.colossusAmongGiants) {
      final healthBeforeRegeneration = active.currentHealth;
      nextTeam = nextTeam.healActive(active.maxHealth * 0.08);
      healing = nextTeam.active.currentHealth - healthBeforeRegeneration;
      if (healing > 0) {
        effectEvents.add(
          _EndTurnEffectEvent(
            combatantIndex: nextTeam.activeIndex,
            type: BattleEffectType.healing,
            amount: healing,
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
  }) {
    final resolutions =
        userTeam.active.equippedSpeciesCard == SpeciesCard.packPower ? 2 : 1;
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
  }) {
    final damagePotency = _speciesModifiedDamagePotency(
      attacker: userTeam.active,
      move: move,
      potency: potency,
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
      MoveEffect.damageTeam => _damageTeam(
        userTeam,
        targetTeam,
        damagePotency,
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
      application = _applyStatuses(
        application,
        move.statusApplications,
        isCritical: move.isCritical,
        attackerSpeciesCard: userTeam.active.equippedSpeciesCard,
      );
      application = _applyCompanionMoveEffect(
        application,
        move.companionEffect,
        originalBearerIndex: userTeam.activeIndex,
      );
    }

    final bleedingStacks =
        userTeam.active.companionCount(Companion.didelphodon) *
        userTeam.active.companionEffectMultiplier.round();
    if (applySecondaryEffects &&
        _dealsDamage(move.effect) &&
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

  _MoveApplication _applyStatuses(
    _MoveApplication application,
    List<StatusApplication> statusApplications, {
    required bool isCritical,
    required SpeciesCard? attackerSpeciesCard,
  }) {
    var nextApplication = application;

    for (final statusApplication in statusApplications) {
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
        StatusTarget.opponent => nextApplication.copyWith(
          targetTeam: nextApplication.targetTeam.applyEnemyStatusToActive(
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
    if (application.target == StatusTarget.opponent &&
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
    required ChampionMove move,
    required double potency,
    required bool targetSwappedThisTurn,
  }) {
    if (!_dealsDamage(move.effect)) return potency;

    final conditionalPotency = targetSwappedThisTurn
        ? move.bonusPotencyIfTargetSwapped
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
  }) {
    return switch (effect) {
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
    };
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
    MoveEffect.damageReserve ||
    MoveEffect.damageReserveAndPromote ||
    MoveEffect.swapSelf ||
    MoveEffect.recklessDamage => true,
    MoveEffect.none ||
    MoveEffect.healSelf ||
    MoveEffect.healTeam ||
    MoveEffect.forceOpponentSwap => false,
  };

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

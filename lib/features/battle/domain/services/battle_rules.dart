import 'dart:math' as math;

import '../../../champions/domain/entities/champion_move.dart';
import '../../../species_cards/domain/entities/species_card.dart';
import '../entities/battle_gesture.dart';
import '../entities/battle_resolution.dart';
import '../entities/battle_status.dart';
import '../entities/battle_team.dart';
import '../entities/combatant.dart';

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
  const StandardBattleRules();

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
      final playerApplication = _applyMove(
        userTeam: playerTeam,
        targetTeam: opponentTeam,
        move: playerMove,
        potency: playerMove.potency,
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

    final opponentApplication = _applyMove(
      userTeam: opponentTeam,
      targetTeam: playerTeam,
      move: opponentMove,
      potency: opponentMove.potency,
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
    );
  }

  ({BattleTeam team, double healing}) _finishTurn(BattleTeam team) {
    var nextTeam = team.tickStatuses();
    var healing = 0.0;
    final active = nextTeam.active;

    if (!active.isDefeated &&
        active.equippedSpeciesCard == SpeciesCard.colossusAmongGiants) {
      final healthBeforeRegeneration = active.currentHealth;
      nextTeam = nextTeam.healActive(active.maxHealth * 0.08);
      healing = nextTeam.active.currentHealth - healthBeforeRegeneration;
    }

    return (team: nextTeam.promoteIfActiveDefeated(), healing: healing);
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
        application = application.copyWith(
          userTeam: healedTeam,
          healing:
              application.healing +
              healedTeam.active.currentHealth -
              healthBeforeHealing,
        );
      }
      if (move.cleansesHarmfulStatuses) {
        application = application.copyWith(
          userTeam: application.userTeam.clearHarmfulStatusesFromActive(),
        );
      }
      if (move.selfDamage > 0) {
        application = application.copyWith(
          userTeam: application.userTeam.damageActive(move.selfDamage),
        );
      }
    }

    return applySecondaryEffects
        ? _applyStatuses(
            application,
            move.statusApplications,
            isCritical: move.isCritical,
            attackerSpeciesCard: userTeam.active.equippedSpeciesCard,
          )
        : application;
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
    final healing = damageApplication.activeDamage / 2;
    return damageApplication.copyWith(
      userTeam: damageApplication.userTeam.healActive(healing),
      healing: healing,
    );
  }

  _MoveApplication _healSelf(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    return _MoveApplication(
      userTeam: userTeam.healActive(potency),
      targetTeam: targetTeam,
      healing: potency,
    );
  }

  _MoveApplication _healTeam(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    return _MoveApplication(
      userTeam: userTeam.healAll(potency),
      targetTeam: targetTeam,
      healing: potency,
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
    }

    return _MoveApplication(
      userTeam: nextUserTeam,
      targetTeam: nextTargetTeam,
      activeDamage: activeDamage,
      reserveDamage: reserveDamage,
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
    return damageApplication.copyWith(
      userTeam: damageApplication.userTeam.damageActive(
        damageApplication.activeDamage / 3,
      ),
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

    if (actualDamage > 0 && target.hasStatus(StatusType.jaggedScales)) {
      nextUserTeam = nextUserTeam.damageActive(actualDamage * 0.3);
    }

    return _MoveApplication(
      userTeam: nextUserTeam,
      targetTeam: nextTargetTeam,
      activeDamage: targetIndex == targetTeam.activeIndex ? actualDamage : 0,
      reserveDamage: targetIndex == targetTeam.activeIndex ? 0 : actualDamage,
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
          targetTeam: nextApplication.targetTeam.applyStatusToActive(
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
    var multiplier = 1.0;
    if (attacker.equippedSpeciesCard == SpeciesCard.superPredator) {
      multiplier *= 1.5;
    }
    if (move.isCritical &&
        attacker.equippedSpeciesCard == SpeciesCard.shadowHunter) {
      multiplier *= 1.66;
    }
    return (potency + conditionalPotency) * multiplier;
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
  const _MoveApplication({
    required this.userTeam,
    required this.targetTeam,
    this.activeDamage = 0,
    this.reserveDamage = 0,
    this.healing = 0,
    this.swapped = false,
    this.targetSwapped = false,
  });

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

  _MoveApplication copyWith({
    BattleTeam? userTeam,
    BattleTeam? targetTeam,
    double? activeDamage,
    double? reserveDamage,
    double? healing,
    bool? swapped,
    bool? targetSwapped,
  }) {
    return _MoveApplication(
      userTeam: userTeam ?? this.userTeam,
      targetTeam: targetTeam ?? this.targetTeam,
      activeDamage: activeDamage ?? this.activeDamage,
      reserveDamage: reserveDamage ?? this.reserveDamage,
      healing: healing ?? this.healing,
      swapped: swapped ?? this.swapped,
      targetSwapped: targetSwapped ?? this.targetSwapped,
    );
  }

  _MoveApplication mergeUserTeam(BattleTeam userTeam) {
    return copyWith(userTeam: userTeam);
  }
}

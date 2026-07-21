import 'dart:math' as math;

import '../entities/battle_gesture.dart';
import '../entities/battle_resolution.dart';
import '../entities/battle_status.dart';
import '../entities/battle_team.dart';
import '../entities/champion_move.dart';
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
      );
      final opponentApplication = _applyMove(
        userTeam: playerApplication.targetTeam,
        targetTeam: playerApplication.userTeam,
        move: opponentMove,
        potency: opponentPotency,
      );

      return _buildResolution(
        outcome: BattleOutcome.draw,
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
    );

    return _buildResolution(
      outcome: BattleOutcome.opponentVictory,
      playerApplication: _MoveApplication.noop(
        userTeam: opponentApplication.targetTeam,
        targetTeam: opponentApplication.userTeam,
      ),
      opponentApplication: opponentApplication,
    );
  }

  BattleResolution _buildResolution({
    required BattleOutcome outcome,
    required _MoveApplication playerApplication,
    required _MoveApplication opponentApplication,
  }) {
    final nextPlayerTeam = playerApplication.userTeam
        .tickStatuses()
        .promoteIfActiveDefeated();
    final nextOpponentTeam = opponentApplication.userTeam
        .tickStatuses()
        .promoteIfActiveDefeated();

    return BattleResolution(
      outcome: outcome,
      damageToPlayer: opponentApplication.activeDamage,
      damageToOpponent: playerApplication.activeDamage,
      playerTeam: nextPlayerTeam,
      opponentTeam: nextOpponentTeam,
      healingToPlayer: playerApplication.healing,
      healingToOpponent: opponentApplication.healing,
      reserveDamageToPlayer: opponentApplication.reserveDamage,
      reserveDamageToOpponent: playerApplication.reserveDamage,
      playerSwapped:
          playerApplication.swapped ||
          nextPlayerTeam.activeIndex != playerApplication.userTeam.activeIndex,
      opponentSwapped:
          opponentApplication.swapped ||
          nextOpponentTeam.activeIndex !=
              opponentApplication.userTeam.activeIndex,
    );
  }

  _MoveApplication _applyMove({
    required BattleTeam userTeam,
    required BattleTeam targetTeam,
    required ChampionMove move,
    required double potency,
  }) {
    var application = switch (move.effect) {
      MoveEffect.none => _MoveApplication.noop(
        userTeam: userTeam,
        targetTeam: targetTeam,
      ),
      MoveEffect.damage => _damageActive(userTeam, targetTeam, potency),
      MoveEffect.drainHealth => _drainHealth(userTeam, targetTeam, potency),
      MoveEffect.healSelf => _healSelf(userTeam, targetTeam, potency),
      MoveEffect.healTeam => _healTeam(userTeam, targetTeam, potency),
      MoveEffect.damageTeam => _damageTeam(userTeam, targetTeam, potency),
      MoveEffect.damageReserve => _damageReserve(userTeam, targetTeam, potency),
      MoveEffect.swapSelf => _swapSelfAfterDamage(
        userTeam,
        targetTeam,
        potency,
      ),
      MoveEffect.recklessDamage => _recklessDamage(
        userTeam,
        targetTeam,
        potency,
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

    return _applyStatuses(application, move.statusApplications);
  }

  _MoveApplication _damageActive(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    return _damageTarget(userTeam, targetTeam, targetTeam.activeIndex, potency);
  }

  _MoveApplication _drainHealth(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    final damageApplication = _damageActive(userTeam, targetTeam, potency);
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
  ) {
    return _damageTarget(
      userTeam,
      targetTeam,
      targetTeam.firstReserveIndex ?? targetTeam.activeIndex,
      potency,
    );
  }

  _MoveApplication _swapSelfAfterDamage(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    final damageApplication = _damageActive(userTeam, targetTeam, potency);
    return damageApplication.copyWith(
      userTeam: damageApplication.userTeam.swapToFirstReserve(),
      swapped: damageApplication.userTeam.swapIndexes.isNotEmpty,
    );
  }

  _MoveApplication _recklessDamage(
    BattleTeam userTeam,
    BattleTeam targetTeam,
    double potency,
  ) {
    final damageApplication = _damageActive(userTeam, targetTeam, potency);
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
  ) {
    final target = targetTeam.combatants[targetIndex];
    final modifiedDamage = _modifiedDamage(
      attacker: userTeam.active,
      defender: target,
      potency: potency,
    );
    final actualDamage = math.min(target.currentHealth, modifiedDamage);
    var nextUserTeam = userTeam;
    final nextTargetTeam = targetTeam.replaceCombatant(
      targetIndex,
      target.takeDamage(modifiedDamage),
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
    List<StatusApplication> statusApplications,
  ) {
    var nextApplication = application;

    for (final statusApplication in statusApplications) {
      nextApplication = switch (statusApplication.target) {
        StatusTarget.self => nextApplication.copyWith(
          userTeam: nextApplication.userTeam.applyStatusToActive(
            statusApplication,
          ),
        ),
        StatusTarget.opponent => nextApplication.copyWith(
          targetTeam: nextApplication.targetTeam.applyStatusToActive(
            statusApplication,
          ),
        ),
      };
    }

    return nextApplication;
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

  _MoveApplication copyWith({
    BattleTeam? userTeam,
    BattleTeam? targetTeam,
    double? activeDamage,
    double? reserveDamage,
    double? healing,
    bool? swapped,
  }) {
    return _MoveApplication(
      userTeam: userTeam ?? this.userTeam,
      targetTeam: targetTeam ?? this.targetTeam,
      activeDamage: activeDamage ?? this.activeDamage,
      reserveDamage: reserveDamage ?? this.reserveDamage,
      healing: healing ?? this.healing,
      swapped: swapped ?? this.swapped,
    );
  }

  _MoveApplication mergeUserTeam(BattleTeam userTeam) {
    return copyWith(userTeam: userTeam);
  }
}

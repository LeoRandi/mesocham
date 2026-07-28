import '../../../companions/domain/entities/companion.dart';
import '../../domain/entities/battle_effect_event.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
import '../../domain/entities/battle_state.dart';
import '../../domain/entities/battle_status.dart';
import '../../domain/entities/battle_team.dart';

class BattleLogFormatter {
  const BattleLogFormatter._();

  static List<String> combatStart({
    required String playerName,
    required String opponentName,
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
  }) {
    return [
      '-COMBAT START-',
      '$playerName vs $opponentName',
      'Equipo de $playerName:',
      for (final combatant in playerTeam.combatants)
        '-${combatant.champion.name}',
      'Equipo de $opponentName:',
      for (final combatant in opponentTeam.combatants)
        '-${combatant.champion.name}',
    ];
  }

  static List<String> resolvedTurn({
    required BattleState beforeAction,
    required BattleState resolvedAction,
    required BattleState afterAction,
    required String playerName,
    required String opponentName,
  }) {
    final resolution = afterAction.lastResolution;
    if (resolution == null) return const [];

    final lines = <String>[
      '---',
      _headline(
        beforeAction: beforeAction,
        resolvedAction: resolvedAction,
        resolution: resolution,
        playerName: playerName,
        opponentName: opponentName,
      ),
    ];

    for (final event in resolution.effectEvents.where(
      (event) => event.type == BattleEffectType.combatDamage,
    )) {
      lines.add(
        _effectLine(
          event,
          actionState: resolvedAction,
          playerName: playerName,
          opponentName: opponentName,
        ),
      );
    }

    _appendStatusChanges(
      lines,
      beforeAction: beforeAction,
      afterAction: afterAction,
      playerName: playerName,
      opponentName: opponentName,
      famineChanges: false,
    );
    _appendCompanionChanges(
      lines,
      beforeAction: beforeAction,
      afterAction: afterAction,
      playerName: playerName,
      opponentName: opponentName,
    );
    _appendStatusChanges(
      lines,
      beforeAction: beforeAction,
      afterAction: afterAction,
      playerName: playerName,
      opponentName: opponentName,
      famineChanges: true,
    );

    for (final event in resolution.effectEvents.where(
      (event) => event.type != BattleEffectType.combatDamage,
    )) {
      lines.add(
        _effectLine(
          event,
          actionState: resolvedAction,
          playerName: playerName,
          opponentName: opponentName,
        ),
      );
    }

    _appendDefeats(
      lines,
      beforeAction: beforeAction,
      afterAction: afterAction,
      playerName: playerName,
      opponentName: opponentName,
    );
    _appendSpeciesCardChanges(
      lines,
      beforeAction: beforeAction,
      afterAction: afterAction,
      playerName: playerName,
      opponentName: opponentName,
    );
    _appendActiveChanges(
      lines,
      beforeAction: beforeAction,
      afterAction: afterAction,
      playerName: playerName,
      opponentName: opponentName,
    );

    if (afterAction.playerTeam.isDefeated) {
      lines.add('¡$opponentName gana el combate!');
    } else if (afterAction.opponentTeam.isDefeated) {
      lines.add('¡$playerName gana el combate!');
    }
    lines.add('---');
    return lines;
  }

  static String companionAppeared(Companion companion) =>
      '¡Ha aparecido el compañero ${companion.name}!';

  static String _headline({
    required BattleState beforeAction,
    required BattleState resolvedAction,
    required BattleResolution resolution,
    required String playerName,
    required String opponentName,
  }) {
    final player = beforeAction.player.champion.name;
    final opponent = resolvedAction.opponent.champion.name;
    final playerLabel = '$player($playerName)';
    final opponentLabel = '$opponent($opponentName)';

    if (resolvedAction.pendingAction == PendingBattleAction.swap) {
      final nextPlayer = resolvedAction.player.champion.name;
      return '$playerLabel cambia a $nextPlayer($playerName). '
          '$opponentLabel ataca con '
          '${_gestureLabel(resolvedAction.opponentGesture!)}.';
    }

    final playerGesture = _gestureLabel(resolvedAction.playerGesture!);
    final opponentGesture = _gestureLabel(resolvedAction.opponentGesture!);
    return switch (resolution.outcome) {
      BattleOutcome.playerVictory =>
        '¡$playerLabel gana con $playerGesture a $opponentLabel!',
      BattleOutcome.opponentVictory =>
        '¡$opponentLabel gana con $opponentGesture a $playerLabel!',
      BattleOutcome.draw =>
        '¡$playerLabel empata con $playerGesture contra $opponentLabel!',
    };
  }

  static String _effectLine(
    BattleEffectEvent event, {
    required BattleState actionState,
    required String playerName,
    required String opponentName,
  }) {
    final team = event.side == BattleSide.player
        ? actionState.playerTeam
        : actionState.opponentTeam;
    final owner = event.side == BattleSide.player ? playerName : opponentName;
    final combatant = team.combatants[event.combatantIndex];
    final isReserve = event.combatantIndex != team.activeIndex;
    final subject = isReserve
        ? '${combatant.champion.name}(Reserva de $owner)'
        : combatant.champion.name;
    final amount = _amount(event.amount);

    return switch (event.type) {
      BattleEffectType.combatDamage =>
        '$subject recibe $amount de daño de combate',
      BattleEffectType.jaggedScalesDamage =>
        '$subject recibe $amount de daño de Escamas dentadas',
      BattleEffectType.recoilDamage =>
        '$subject recibe $amount de daño de retroceso',
      BattleEffectType.selfDamage =>
        '$subject recibe $amount de daño autoinfligido',
      BattleEffectType.bleedingDamage =>
        '$subject recibe $amount de daño de Sangrado',
      BattleEffectType.famineMaxHealthLoss =>
        '$subject pierde $amount de vida máxima por Hambruna',
      BattleEffectType.healing => '$subject recupera $amount PS',
    };
  }

  static void _appendStatusChanges(
    List<String> lines, {
    required BattleState beforeAction,
    required BattleState afterAction,
    required String playerName,
    required String opponentName,
    required bool famineChanges,
  }) {
    _appendTeamStatusChanges(
      lines,
      before: beforeAction.playerTeam,
      after: afterAction.playerTeam,
      owner: playerName,
      famineChanges: famineChanges,
    );
    _appendTeamStatusChanges(
      lines,
      before: beforeAction.opponentTeam,
      after: afterAction.opponentTeam,
      owner: opponentName,
      famineChanges: famineChanges,
    );
  }

  static void _appendTeamStatusChanges(
    List<String> lines, {
    required BattleTeam before,
    required BattleTeam after,
    required String owner,
    required bool famineChanges,
  }) {
    for (var index = 0; index < before.combatants.length; index++) {
      final previous = before.combatants[index];
      final next = after.combatants[index];
      final previousStatuses = {
        for (final status in previous.statuses) status.type: status,
      };
      final nextStatuses = {
        for (final status in next.statuses) status.type: status,
      };

      for (final type in StatusType.values) {
        if ((type == StatusType.famine) != famineChanges) continue;
        final oldStatus = previousStatuses[type];
        final newStatus = nextStatuses[type];
        if (oldStatus == null && newStatus != null) {
          lines.add(
            '${next.champion.name} gana el estado ${type.label}'
            '${newStatus.stacks > 1 ? ' (${newStatus.stacks})' : ''}',
          );
        } else if (oldStatus != null && newStatus == null) {
          if (type == StatusType.alphaMomentum) {
            lines.add(
              '${previous.champion.name} pierde el estado ${type.label}',
            );
          } else {
            lines.add(
              'El estado ${type.label} desaparece de '
              '${previous.champion.name}($owner)',
            );
          }
        } else if (oldStatus != null &&
            newStatus != null &&
            oldStatus.stacks != newStatus.stacks) {
          lines.add(
            '${next.champion.name} pasa a tener ${newStatus.stacks} '
            'acumulaciones de ${type.label}',
          );
        }
      }
    }
  }

  static void _appendCompanionChanges(
    List<String> lines, {
    required BattleState beforeAction,
    required BattleState afterAction,
    required String playerName,
    required String opponentName,
  }) {
    _appendTeamCompanionChanges(
      lines,
      before: beforeAction.playerTeam,
      after: afterAction.playerTeam,
      owner: playerName,
    );
    _appendTeamCompanionChanges(
      lines,
      before: beforeAction.opponentTeam,
      after: afterAction.opponentTeam,
      owner: opponentName,
    );
  }

  static void _appendDefeats(
    List<String> lines, {
    required BattleState beforeAction,
    required BattleState afterAction,
    required String playerName,
    required String opponentName,
  }) {
    for (final side in BattleSide.values) {
      final before = side == BattleSide.player
          ? beforeAction.playerTeam
          : beforeAction.opponentTeam;
      final after = side == BattleSide.player
          ? afterAction.playerTeam
          : afterAction.opponentTeam;
      final owner = side == BattleSide.player ? playerName : opponentName;
      for (var index = 0; index < before.combatants.length; index++) {
        if (!before.combatants[index].isDefeated &&
            after.combatants[index].isDefeated) {
          lines.add(
            '${after.combatants[index].champion.name}($owner) '
            'queda derrotado',
          );
        }
      }
    }
  }

  static void _appendTeamCompanionChanges(
    List<String> lines, {
    required BattleTeam before,
    required BattleTeam after,
    required String owner,
  }) {
    for (var index = 0; index < before.combatants.length; index++) {
      final previous = before.combatants[index];
      final next = after.combatants[index];
      for (final companion in Companion.values) {
        final oldCount = previous.companionCount(companion);
        final newCount = next.companionCount(companion);
        if (newCount > oldCount) {
          for (var copy = oldCount; copy < newCount; copy++) {
            lines.add(
              '${companion.name} se une a ${next.champion.name}($owner)',
            );
          }
        } else if (newCount < oldCount && !next.isDefeated) {
          for (var copy = newCount; copy < oldCount; copy++) {
            lines.add(
              '${companion.name} abandona a ${previous.champion.name}($owner)',
            );
          }
        }
      }
    }
  }

  static void _appendSpeciesCardChanges(
    List<String> lines, {
    required BattleState beforeAction,
    required BattleState afterAction,
    required String playerName,
    required String opponentName,
  }) {
    for (final side in BattleSide.values) {
      final before = side == BattleSide.player
          ? beforeAction.playerTeam
          : beforeAction.opponentTeam;
      final after = side == BattleSide.player
          ? afterAction.playerTeam
          : afterAction.opponentTeam;
      final owner = side == BattleSide.player ? playerName : opponentName;
      for (var index = 0; index < before.combatants.length; index++) {
        final oldCard = before.combatants[index].equippedSpeciesCard;
        final newCard = after.combatants[index].equippedSpeciesCard;
        if (oldCard == null && newCard != null) {
          lines.add(
            '${after.combatants[index].champion.name}($owner) equipa '
            'la carta de especie ${newCard.name}',
          );
        }
      }
    }
  }

  static void _appendActiveChanges(
    List<String> lines, {
    required BattleState beforeAction,
    required BattleState afterAction,
    required String playerName,
    required String opponentName,
  }) {
    _appendTeamActiveChange(
      lines,
      before: beforeAction.playerTeam,
      after: afterAction.playerTeam,
      owner: playerName,
    );
    _appendTeamActiveChange(
      lines,
      before: beforeAction.opponentTeam,
      after: afterAction.opponentTeam,
      owner: opponentName,
    );
  }

  static void _appendTeamActiveChange(
    List<String> lines, {
    required BattleTeam before,
    required BattleTeam after,
    required String owner,
  }) {
    if (before.activeIndex == after.activeIndex) return;
    lines.add(
      '${after.active.champion.name}($owner) entra como campeón activo',
    );
  }

  static String _gestureLabel(BattleGesture gesture) => switch (gesture) {
    BattleGesture.rock => 'Piedra',
    BattleGesture.paper => 'Papel',
    BattleGesture.scissors => 'Tijera',
  };

  static String _amount(double value) => value.round().toString();
}

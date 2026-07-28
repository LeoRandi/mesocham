import '../../../champions/domain/entities/status_effect.dart';

export '../../../champions/domain/entities/status_effect.dart';

class StatusCondition {
  const StatusCondition({
    required this.type,
    this.stacks = 1,
    this.remainingTurns,
    this.justApplied = false,
  });

  final StatusType type;
  final int stacks;
  final int? remainingTurns;
  final bool justApplied;

  bool get isExpired => remainingTurns != null && remainingTurns! <= 0;

  StatusCondition apply(StatusApplication application) {
    if (type != application.type) return this;

    return switch (type) {
      StatusType.bleeding => StatusCondition(
        type: type,
        stacks: stacks + application.stacks,
        remainingTurns: application.resolvedDurationTurns,
        justApplied: application.delayFirstTick,
      ),
      StatusType.famine => StatusCondition(
        type: type,
        stacks: application.stacks > stacks ? application.stacks : stacks,
        remainingTurns:
            remainingTurns == null || application.resolvedDurationTurns == null
            ? null
            : application.resolvedDurationTurns,
        justApplied: justApplied || application.delayFirstTick,
      ),
      StatusType.alphaMomentum => StatusCondition(
        type: type,
        justApplied: true,
      ),
      _ => StatusCondition(
        type: type,
        stacks: application.stacks > stacks ? application.stacks : stacks,
        remainingTurns: type == StatusType.famine && remainingTurns == null
            ? null
            : application.resolvedDurationTurns,
        justApplied: application.delayFirstTick,
      ),
    };
  }

  StatusCondition tick() {
    if (justApplied) {
      return StatusCondition(
        type: type,
        stacks: stacks,
        remainingTurns: remainingTurns,
      );
    }
    if (remainingTurns == null) return this;
    return StatusCondition(
      type: type,
      stacks: stacks,
      remainingTurns: remainingTurns! - 1,
    );
  }
}

extension StatusTypeLabel on StatusType {
  String get label => switch (this) {
    StatusType.intimidation => 'Intimidación',
    StatusType.bleeding => 'Sangrado',
    StatusType.brokenBone => 'Hueso roto',
    StatusType.alphaMomentum => 'Ímpetu de alfa',
    StatusType.protectiveScales => 'Escamas protectoras',
    StatusType.famine => 'Hambruna',
    StatusType.jaggedScales => 'Escamas dentadas',
    StatusType.secondaryImmunity => 'Inmunidad secundaria',
    StatusType.swapLocked => 'Cambio bloqueado',
  };

  String get shortLabel => switch (this) {
    StatusType.intimidation => 'INT',
    StatusType.bleeding => 'SNG',
    StatusType.brokenBone => 'HUE',
    StatusType.alphaMomentum => 'ALF',
    StatusType.protectiveScales => 'PRO',
    StatusType.famine => 'HAM',
    StatusType.jaggedScales => 'DEN',
    StatusType.secondaryImmunity => 'INM',
    StatusType.swapLocked => 'BLQ',
  };
}

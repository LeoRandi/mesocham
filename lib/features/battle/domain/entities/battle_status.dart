enum StatusType {
  intimidation,
  bleeding,
  brokenBone,
  alphaMomentum,
  protectiveScales,
  famine,
  jaggedScales,
}

enum StatusTarget { self, opponent }

class StatusApplication {
  const StatusApplication({
    required this.type,
    required this.target,
    this.stacks = 1,
    this.durationTurns,
  });

  final StatusType type;
  final StatusTarget target;
  final int stacks;
  final int? durationTurns;

  int? get resolvedDurationTurns => durationTurns ?? type.defaultDurationTurns;
}

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
        justApplied: true,
      ),
      StatusType.alphaMomentum => StatusCondition(
        type: type,
        justApplied: true,
      ),
      _ => StatusCondition(
        type: type,
        stacks: application.stacks > stacks ? application.stacks : stacks,
        remainingTurns: application.resolvedDurationTurns,
        justApplied: true,
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

extension StatusTypeRules on StatusType {
  int? get defaultDurationTurns => switch (this) {
    StatusType.alphaMomentum => null,
    StatusType.bleeding => 5,
    _ => 3,
  };
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
  };

  String get shortLabel => switch (this) {
    StatusType.intimidation => 'INT',
    StatusType.bleeding => 'SNG',
    StatusType.brokenBone => 'HUE',
    StatusType.alphaMomentum => 'ALF',
    StatusType.protectiveScales => 'PRO',
    StatusType.famine => 'HAM',
    StatusType.jaggedScales => 'DEN',
  };
}

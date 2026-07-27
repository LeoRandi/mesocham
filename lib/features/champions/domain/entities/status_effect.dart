enum StatusType {
  intimidation,
  bleeding,
  brokenBone,
  alphaMomentum,
  protectiveScales,
  famine,
  jaggedScales,
  secondaryImmunity,
  swapLocked,
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

extension StatusTypeRules on StatusType {
  int? get defaultDurationTurns => switch (this) {
    StatusType.alphaMomentum => null,
    StatusType.bleeding => 5,
    StatusType.swapLocked => 1,
    _ => 3,
  };

  bool get isHarmful => switch (this) {
    StatusType.intimidation ||
    StatusType.bleeding ||
    StatusType.brokenBone ||
    StatusType.famine ||
    StatusType.swapLocked => true,
    StatusType.alphaMomentum ||
    StatusType.protectiveScales ||
    StatusType.jaggedScales ||
    StatusType.secondaryImmunity => false,
  };
}

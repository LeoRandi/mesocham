enum BattleSide { player, opponent }

enum BattleEffectType {
  combatDamage,
  jaggedScalesDamage,
  recoilDamage,
  selfDamage,
  bleedingDamage,
  famineMaxHealthLoss,
  healing,
}

class BattleEffectEvent {
  const BattleEffectEvent({
    required this.side,
    required this.combatantIndex,
    required this.type,
    required this.amount,
  });

  final BattleSide side;
  final int combatantIndex;
  final BattleEffectType type;
  final double amount;
}

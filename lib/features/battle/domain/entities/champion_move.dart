import 'battle_gesture.dart';
import 'battle_status.dart';

enum MoveEffect {
  none,
  damage,
  drainHealth,
  healSelf,
  healTeam,
  damageTeam,
  damageReserve,
  swapSelf,
  recklessDamage,
}

class ChampionMove {
  const ChampionMove({
    required this.name,
    required this.gesture,
    required this.potency,
    required this.effect,
    required this.description,
    this.statusApplications = const [],
    this.effectTurns = 0,
    this.isCritical = false,
    this.dealsFullDamageOnDraw = false,
  });

  final String name;
  final BattleGesture gesture;
  final double potency;
  final MoveEffect effect;
  final String description;
  final List<StatusApplication> statusApplications;
  final int effectTurns;
  final bool isCritical;
  final bool dealsFullDamageOnDraw;
}

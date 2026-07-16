import 'battle_gesture.dart';

enum MoveEffect { damage, damageReduction }

class ChampionMove {
  const ChampionMove({
    required this.name,
    required this.gesture,
    required this.effect,
    required this.description,
    this.effectTurns = 0,
    this.isCritical = false,
    this.dealsFullDamageOnDraw = false,
  });

  final String name;
  final BattleGesture gesture;
  final MoveEffect effect;
  final String description;
  final int effectTurns;
  final bool isCritical;
  final bool dealsFullDamageOnDraw;
}

import '../domain/entities/battle_gesture.dart';
import '../domain/entities/champion.dart';
import '../domain/entities/champion_move.dart';
import '../domain/entities/combatant.dart';

abstract final class DemoBattleFactory {
  static final Champion triceratops = Champion(
    id: 'triceratops-horridus',
    name: 'Triceratops',
    period: MesozoicPeriod.cretaceous,
    type: ChampionType.crown,
    maxHealth: 160,
    attack: 34,
    moves: [
      ChampionMove(
        name: 'Crown Shield',
        gesture: BattleGesture.rock,
        effect: MoveEffect.damageReduction,
        description: 'Reduces incoming damage for 2 turns.',
        effectTurns: 2,
      ),
      ChampionMove(
        name: 'Broken Beak',
        gesture: BattleGesture.paper,
        effect: MoveEffect.damage,
        description: 'Deals damage with a crushing beak strike.',
      ),
      ChampionMove(
        name: 'Three-Pronged Charge',
        gesture: BattleGesture.scissors,
        effect: MoveEffect.damage,
        description: 'Deals full damage on a win or a draw.',
        isCritical: true,
        dealsFullDamageOnDraw: true,
      ),
    ],
  );

  static Combatant player() => Combatant.fresh(triceratops);

  static Combatant opponent() => Combatant.fresh(triceratops);
}

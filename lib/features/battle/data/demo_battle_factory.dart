import '../domain/entities/battle_gesture.dart';
import '../domain/entities/champion.dart';
import '../domain/entities/champion_move.dart';
import '../domain/entities/combatant.dart';

abstract final class DemoBattleFactory {
  static final Champion ornithosuchus = Champion(
    id: 'ornithosuchus-longidens',
    name: 'Ornithosuchus',
    period: MesozoicPeriod.triassic,
    type: ChampionType.jaw,
    maxHealth: 150,
    attack: 36,
    imageAssetPath: 'assets/dinos/ornitosuchus.png',
    closeUpAssetPath: 'assets/dinos/closeUps/ornitosuchus-closeUp.png',
    moves: [
      ChampionMove(
        name: 'Hunting Roar',
        gesture: BattleGesture.rock,
        effect: MoveEffect.damageReduction,
        description: 'Reduces incoming damage for 2 turns.',
        effectTurns: 2,
      ),
      ChampionMove(
        name: 'Lethal Bite',
        gesture: BattleGesture.paper,
        effect: MoveEffect.damage,
        description: 'Deals damage with a crushing bite.',
      ),
      ChampionMove(
        name: 'Ambush',
        gesture: BattleGesture.scissors,
        effect: MoveEffect.damage,
        description: 'Deals full damage on a win or a draw.',
        isCritical: true,
        dealsFullDamageOnDraw: true,
      ),
    ],
  );

  static Combatant player() => Combatant.fresh(ornithosuchus);

  static Combatant opponent() => Combatant.fresh(ornithosuchus);
}

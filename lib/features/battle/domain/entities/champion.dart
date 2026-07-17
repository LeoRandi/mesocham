import 'battle_gesture.dart';
import 'champion_move.dart';

enum MesozoicPeriod { triassic, jurassic, cretaceous, chimera }

enum ChampionType { jaw, nest, wings, plates, claws, titan, water, crown }

class Champion {
  Champion({
    required this.id,
    required this.name,
    required this.period,
    required this.type,
    required this.maxHealth,
    required this.attack,
    required this.moves,
  }) : assert(moves.length == 3, 'Every champion needs exactly three moves.');

  final String id;
  final String name;
  final MesozoicPeriod period;
  final ChampionType type;
  final int maxHealth;
  final int attack;
  final List<ChampionMove> moves;

  ChampionMove moveFor(BattleGesture gesture) {
    return moves.firstWhere((move) => move.gesture == gesture);
  }
}

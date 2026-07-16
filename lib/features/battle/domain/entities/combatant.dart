import 'champion.dart';

class Combatant {
  const Combatant({required this.champion, required this.currentHealth});

  factory Combatant.fresh(Champion champion) {
    return Combatant(champion: champion, currentHealth: champion.maxHealth);
  }

  final Champion champion;
  final int currentHealth;

  bool get isDefeated => currentHealth <= 0;

  Combatant takeDamage(int damage) {
    return Combatant(
      champion: champion,
      currentHealth: (currentHealth - damage)
          .clamp(0, champion.maxHealth)
          .toInt(),
    );
  }
}

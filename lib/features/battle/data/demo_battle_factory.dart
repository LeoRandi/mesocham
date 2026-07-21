import 'presets/champion_move_presets.dart';
import 'presets/champion_presets.dart';
import '../domain/entities/battle_gesture.dart';
import '../domain/entities/battle_team.dart';
import '../domain/entities/champion.dart';
import '../domain/entities/champion_move.dart';
import '../domain/entities/champion_preset.dart';
import '../domain/entities/combatant.dart';

abstract final class DemoBattleFactory {
  static final Champion ornithosuchus = championFromPreset(
    ChampionPresets.byId['ornithosuchus']!,
  );

  static Champion championFromPreset(ChampionPreset preset) {
    final typeMoves = ChampionTypeMovePresets.forType(preset.type);

    final moves = [
      for (final gesture in BattleGesture.values)
        _moveFromPreset(
          gesture,
          preset.moveOverrides[gesture]?.isCritical ?? false
              ? preset.moveOverrides[gesture]!
              : typeMoves[gesture]!,
          normalPotency: typeMoves[gesture]!.potency,
        ),
    ];

    return Champion(
      id: preset.id,
      name: preset.name,
      period: preset.period,
      type: preset.type,
      maxHealth: ChampionTypeHealthPresets.forType(preset.type),
      imageAssetPath: preset.imageAssetPath,
      closeUpAssetPath: preset.closeUpAssetPath,
      moves: moves,
    );
  }

  static ChampionMove _moveFromPreset(
    BattleGesture gesture,
    ChampionMovePreset preset, {
    required double normalPotency,
  }) {
    return ChampionMove(
      name: preset.name,
      gesture: gesture,
      potency: preset.isCritical ? normalPotency : preset.potency,
      effect: preset.effect,
      description:
          preset.effectDescription ??
          (preset.isCritical
              ? 'Ataque crítico de especie.'
              : 'Ataque básico de tipo.'),
      statusApplications: preset.statusApplications,
      effectTurns: preset.effectTurns,
      isCritical: preset.isCritical,
      dealsFullDamageOnDraw: preset.dealsFullDamageOnDraw,
    );
  }

  static Combatant player() => Combatant.fresh(ornithosuchus);

  static Combatant opponent() => Combatant.fresh(ornithosuchus);

  static BattleTeam playerTeam() {
    return BattleTeam.fresh([ornithosuchus, ornithosuchus, ornithosuchus]);
  }

  static BattleTeam opponentTeam() {
    return BattleTeam.fresh([ornithosuchus, ornithosuchus, ornithosuchus]);
  }
}

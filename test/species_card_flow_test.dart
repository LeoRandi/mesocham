import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/features/battle/application/services/battle_session.dart';
import 'package:mesocham/features/battle/domain/entities/battle_gesture.dart';
import 'package:mesocham/features/battle/domain/entities/battle_state.dart';
import 'package:mesocham/features/battle/domain/entities/battle_team.dart';
import 'package:mesocham/features/battle/domain/entities/battle_turn.dart';
import 'package:mesocham/features/battle/domain/entities/combatant.dart';
import 'package:mesocham/features/battle/domain/services/ai_move_strategy.dart';
import 'package:mesocham/features/battle/domain/services/battle_rules.dart';
import 'package:mesocham/features/battle/domain/services/companion_randomizer.dart';
import 'package:mesocham/features/champions/data/local/local_champion_catalog.dart';

void main() {
  final catalog = LocalChampionCatalog();

  BattleTeam team() => BattleTeam.fresh([
    catalog.championById('allosaurus')!,
    catalog.championById('triceratops')!,
    catalog.championById('pterodactylus')!,
  ]);

  BattleSession session(BattleGesture opponentGesture) {
    final companionRandomizer = CompanionRandomizer(random: math.Random(1));
    return BattleSession(
      rules: StandardBattleRules(
        companionRandomizer: companionRandomizer,
        random: math.Random(1),
      ),
      opponentStrategy: _FixedAiStrategy(opponentGesture),
      companionRandomizer: companionRandomizer,
    );
  }

  BattleState resolveCardAttempt({
    required BattleGesture playerGesture,
    required BattleGesture opponentGesture,
  }) {
    final battleSession = session(opponentGesture);
    var state = battleSession.initialState(
      playerTeam: team(),
      opponentTeam: team(),
    );
    state = battleSession.startSpeciesCardSelection(state);
    state = battleSession.selectPlayerSpeciesCard(state, 0);
    state = battleSession.cancelSpeciesCardSelection(state);
    state = battleSession.startFight(state);
    state = battleSession.selectPlayerGesture(state, playerGesture);
    state = battleSession.beginShowdown(state);
    return battleSession.resolvePendingAction(state);
  }

  test('a failed species-card attempt is lost for the rest of battle', () {
    final state = resolveCardAttempt(
      playerGesture: BattleGesture.scissors,
      opponentGesture: BattleGesture.rock,
    );

    expect(state.playerTeam.speciesCardSlots[0].lost, isTrue);
    expect(state.playerTeam.speciesCardSlots[0].consumed, isFalse);
  });

  test('a successful species-card attempt records its bearer', () {
    final state = resolveCardAttempt(
      playerGesture: BattleGesture.rock,
      opponentGesture: BattleGesture.scissors,
    );

    expect(state.playerTeam.speciesCardSlots[0].lost, isFalse);
    expect(state.playerTeam.speciesCardSlots[0].consumed, isTrue);
    expect(state.playerTeam.speciesCardSlots[0].bearerIndex, 0);
  });
}

class _FixedAiStrategy implements AiMoveStrategy {
  const _FixedAiStrategy(this.gesture);

  final BattleGesture gesture;

  @override
  BattleGesture chooseMove({
    required Combatant self,
    required Combatant opponent,
    required BattleTurn? previousTurn,
  }) => gesture;
}

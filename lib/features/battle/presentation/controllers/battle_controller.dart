import 'package:flutter/foundation.dart';

import '../../../champions/domain/entities/champion_move.dart';
import '../../../companions/domain/entities/companion.dart';
import '../../application/services/battle_session.dart';
import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
import '../../domain/entities/battle_state.dart';
import '../../domain/entities/battle_team.dart';
import '../../domain/entities/combatant.dart';

class BattleController extends ChangeNotifier {
  BattleController({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleSession session,
  }) : _session = session,
       _initialState = session.initialState(
         playerTeam: playerTeam,
         opponentTeam: opponentTeam,
       ),
       _state = session.initialState(
         playerTeam: playerTeam,
         opponentTeam: opponentTeam,
       );

  final BattleSession _session;
  final BattleState _initialState;
  BattleState _state;

  BattleState get state => _state;
  Combatant get player => _state.player;
  Combatant get opponent => _state.opponent;
  BattleTeam get playerTeam => _state.playerTeam;
  BattleTeam get opponentTeam => _state.opponentTeam;
  BattlePhase get phase => _state.phase;
  BattleGesture? get playerGesture => _state.playerGesture;
  BattleResolution? get lastResolution => _state.lastResolution;
  int? get pendingPlayerSpeciesCardIndex =>
      _state.pendingPlayerSpeciesCardIndex;
  int get resolutionSequence => _state.resolutionSequence;
  List<int> get playerSwapIndexes => _state.playerSwapIndexes;
  bool get isFightOverlayVisible => _state.isFightOverlayVisible;
  bool get isSwapOverlayVisible => _state.isSwapOverlayVisible;
  bool get canShowdown => _state.canShowdown;
  bool get canSwap => _state.canSwap;
  ChampionMove? get selectedPlayerMove => _state.selectedPlayerMove;
  List<Companion> get wildCompanionStack => _state.wildCompanionStack;

  void startFight() => _emit(_session.startFight(_state));

  void startSwap() => _emit(_session.startSwap(_state));

  void cancelSwap() => _emit(_session.cancelSwap(_state));

  void selectPlayerGesture(BattleGesture gesture) {
    _emit(_session.selectPlayerGesture(_state, gesture));
  }

  void selectPlayerSpeciesCard(int index) {
    _emit(_session.selectPlayerSpeciesCard(_state, index));
  }

  bool beginShowdown() => _emit(_session.beginShowdown(_state));

  bool beginSwap(int index) => _emit(_session.beginSwap(_state, index));

  bool resolvePendingAction() {
    return _emit(_session.resolvePendingAction(_state));
  }

  bool completeResolution() {
    return _emit(_session.completeResolution(_state));
  }

  void resetBattle() => _emit(_initialState);

  bool _emit(BattleState nextState) {
    if (identical(nextState, _state)) return false;
    _state = nextState;
    notifyListeners();
    return true;
  }
}

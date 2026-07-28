import 'package:flutter/foundation.dart';

import '../../../champions/domain/entities/champion_move.dart';
import '../../../companions/domain/entities/companion.dart';
import '../../application/services/battle_log_formatter.dart';
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
    this.playerName = 'Jugador',
    this.opponentName = 'John(CPU)',
  }) : _session = session,
       _initialState = session.initialState(
         playerTeam: playerTeam,
         opponentTeam: opponentTeam,
       ),
       _state = session.initialState(
         playerTeam: playerTeam,
         opponentTeam: opponentTeam,
       ),
       _combatLog = BattleLogFormatter.combatStart(
         playerName: playerName,
         opponentName: opponentName,
         playerTeam: playerTeam,
         opponentTeam: opponentTeam,
       );

  final BattleSession _session;
  final BattleState _initialState;
  final String playerName;
  final String opponentName;
  final List<String> _combatLog;
  BattleState _state;
  BattleState? _pendingActionStartState;

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
  List<String> get combatLog => List.unmodifiable(_combatLog);

  void startFight() => _emit(_session.startFight(_state));

  void startSwap() => _emit(_session.startSwap(_state));

  void cancelSwap() => _emit(_session.cancelSwap(_state));

  void selectPlayerGesture(BattleGesture gesture) {
    _emit(_session.selectPlayerGesture(_state, gesture));
  }

  void selectPlayerSpeciesCard(int index) {
    _emit(_session.selectPlayerSpeciesCard(_state, index));
  }

  bool beginShowdown() {
    final nextState = _session.beginShowdown(_state);
    if (identical(nextState, _state)) return false;
    _pendingActionStartState = _state;
    return _emit(nextState);
  }

  bool beginSwap(int index) {
    final nextState = _session.beginSwap(_state, index);
    if (identical(nextState, _state)) return false;
    _pendingActionStartState = _state;
    return _emit(nextState);
  }

  bool resolvePendingAction() {
    final nextState = _session.resolvePendingAction(_state);
    if (identical(nextState, _state)) return false;
    _combatLog.addAll(
      BattleLogFormatter.resolvedTurn(
        beforeAction: _pendingActionStartState ?? _state,
        resolvedAction: _state,
        afterAction: nextState,
        playerName: playerName,
        opponentName: opponentName,
      ),
    );
    return _emit(nextState);
  }

  bool completeResolution() {
    final previousCompanions = _state.wildCompanionStack;
    final nextState = _session.completeResolution(_state);
    if (identical(nextState, _state)) return false;
    if (nextState.wildCompanionStack.length > previousCompanions.length) {
      _combatLog.add(
        BattleLogFormatter.companionAppeared(nextState.wildCompanionStack.last),
      );
    }
    _pendingActionStartState = null;
    return _emit(nextState);
  }

  void resetBattle() {
    _pendingActionStartState = null;
    _combatLog
      ..clear()
      ..addAll(
        BattleLogFormatter.combatStart(
          playerName: playerName,
          opponentName: opponentName,
          playerTeam: _initialState.playerTeam,
          opponentTeam: _initialState.opponentTeam,
        ),
      );
    if (!_emit(_initialState)) notifyListeners();
  }

  bool _emit(BattleState nextState) {
    if (identical(nextState, _state)) return false;
    _state = nextState;
    notifyListeners();
    return true;
  }
}

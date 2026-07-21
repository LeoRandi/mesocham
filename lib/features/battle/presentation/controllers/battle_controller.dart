import 'package:flutter/foundation.dart';

import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
import '../../domain/entities/battle_team.dart';
import '../../domain/entities/battle_turn.dart';
import '../../domain/entities/champion_move.dart';
import '../../domain/entities/combatant.dart';
import '../../domain/services/ai_move_strategy.dart';
import '../../domain/services/battle_rules.dart';

class BattleController extends ChangeNotifier {
  BattleController({
    required BattleTeam playerTeam,
    required BattleTeam opponentTeam,
    required BattleRules rules,
    required AiMoveStrategy opponentStrategy,
  }) : _initialPlayerTeam = playerTeam,
       _initialOpponentTeam = opponentTeam,
       _playerTeam = playerTeam,
       _opponentTeam = opponentTeam,
       _rules = rules,
       _opponentStrategy = opponentStrategy;

  final BattleTeam _initialPlayerTeam;
  final BattleTeam _initialOpponentTeam;
  final BattleRules _rules;
  final AiMoveStrategy _opponentStrategy;

  BattleTeam _playerTeam;
  BattleTeam _opponentTeam;
  BattlePhase _phase = BattlePhase.command;
  BattleGesture? _playerGesture;
  BattleGesture? _opponentGesture;
  BattleResolution? _lastResolution;
  BattleTurn? _previousTurn;
  bool _disposed = false;
  bool _resolving = false;

  Combatant get player => _playerTeam.active;
  Combatant get opponent => _opponentTeam.active;
  BattleTeam get playerTeam => _playerTeam;
  BattleTeam get opponentTeam => _opponentTeam;
  BattlePhase get phase => _phase;
  BattleGesture? get playerGesture => _playerGesture;
  BattleResolution? get lastResolution => _lastResolution;
  List<int> get playerSwapIndexes => _playerTeam.swapIndexes;
  bool get isFightOverlayVisible =>
      _phase == BattlePhase.choosingMove || _phase == BattlePhase.resolving;
  bool get isSwapOverlayVisible => _phase == BattlePhase.swapping;
  bool get canShowdown =>
      _phase == BattlePhase.choosingMove && _playerGesture != null;
  bool get canSwap =>
      _phase == BattlePhase.command && playerSwapIndexes.isNotEmpty;

  ChampionMove? get selectedPlayerMove =>
      _playerGesture == null ? null : player.champion.moveFor(_playerGesture!);

  void startFight() {
    if (_phase != BattlePhase.command) return;

    _lastResolution = null;
    _playerGesture = null;
    _opponentGesture = _opponentStrategy.chooseMove(
      self: opponent,
      opponent: player,
      previousTurn: _previousTurn,
    );
    _phase = BattlePhase.choosingMove;
    notifyListeners();
  }

  void startSwap() {
    if (!canSwap) return;

    _lastResolution = null;
    _playerGesture = null;
    _opponentGesture = _opponentStrategy.chooseMove(
      self: opponent,
      opponent: player,
      previousTurn: _previousTurn,
    );
    _phase = BattlePhase.swapping;
    notifyListeners();
  }

  void cancelSwap() {
    if (_phase != BattlePhase.swapping) return;

    _opponentGesture = null;
    _phase = BattlePhase.command;
    notifyListeners();
  }

  Future<void> swapPlayerTo(int index) async {
    if (_phase != BattlePhase.swapping ||
        !_playerTeam.swapIndexes.contains(index) ||
        _opponentGesture == null ||
        _resolving) {
      return;
    }

    _resolving = true;
    _playerTeam = _playerTeam.swapTo(index);
    _phase = BattlePhase.resolving;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (_disposed) return;

    final resolution = _rules.resolveGuaranteedOpponentMove(
      playerTeam: _playerTeam,
      opponentTeam: _opponentTeam,
      opponentGesture: _opponentGesture!,
    );
    _previousTurn = null;
    _lastResolution = resolution;
    _playerTeam = resolution.playerTeam;
    _opponentTeam = resolution.opponentTeam;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1250));
    if (_disposed) return;

    _phase = _playerTeam.isDefeated || _opponentTeam.isDefeated
        ? BattlePhase.gameOver
        : BattlePhase.command;
    _playerGesture = null;
    _opponentGesture = null;
    _lastResolution = null;
    _resolving = false;
    notifyListeners();
  }

  void selectPlayerGesture(BattleGesture gesture) {
    if (_phase != BattlePhase.choosingMove) return;

    _playerGesture = gesture;
    notifyListeners();
  }

  Future<void> showdown() async {
    if (!canShowdown || _resolving) return;

    _resolving = true;
    _phase = BattlePhase.resolving;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (_disposed) return;

    final resolution = _rules.resolve(
      playerTeam: _playerTeam,
      opponentTeam: _opponentTeam,
      playerGesture: _playerGesture!,
      opponentGesture: _opponentGesture!,
    );
    _previousTurn = BattleTurn(
      playerGesture: _playerGesture!,
      opponentGesture: _opponentGesture!,
      outcome: resolution.outcome,
    );
    _lastResolution = resolution;
    _playerTeam = resolution.playerTeam;
    _opponentTeam = resolution.opponentTeam;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1250));
    if (_disposed) return;

    _phase = _playerTeam.isDefeated || _opponentTeam.isDefeated
        ? BattlePhase.gameOver
        : BattlePhase.command;
    _playerGesture = null;
    _opponentGesture = null;
    _lastResolution = null;
    _resolving = false;
    notifyListeners();
  }

  void resetBattle() {
    _playerTeam = _initialPlayerTeam;
    _opponentTeam = _initialOpponentTeam;
    _phase = BattlePhase.command;
    _playerGesture = null;
    _opponentGesture = null;
    _lastResolution = null;
    _previousTurn = null;
    _resolving = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

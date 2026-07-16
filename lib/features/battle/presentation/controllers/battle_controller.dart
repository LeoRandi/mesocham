import 'package:flutter/foundation.dart';

import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/battle_resolution.dart';
import '../../domain/entities/champion_move.dart';
import '../../domain/entities/combatant.dart';
import '../../domain/services/ai_move_strategy.dart';
import '../../domain/services/battle_rules.dart';

class BattleController extends ChangeNotifier {
  BattleController({
    required Combatant player,
    required Combatant opponent,
    required BattleRules rules,
    required AiMoveStrategy opponentStrategy,
  }) : _initialPlayer = player,
       _initialOpponent = opponent,
       _player = player,
       _opponent = opponent,
       _rules = rules,
       _opponentStrategy = opponentStrategy;

  final Combatant _initialPlayer;
  final Combatant _initialOpponent;
  final BattleRules _rules;
  final AiMoveStrategy _opponentStrategy;

  Combatant _player;
  Combatant _opponent;
  BattlePhase _phase = BattlePhase.command;
  BattleGesture? _playerGesture;
  BattleGesture? _opponentGesture;
  BattleResolution? _lastResolution;
  bool _disposed = false;
  bool _resolving = false;

  Combatant get player => _player;
  Combatant get opponent => _opponent;
  BattlePhase get phase => _phase;
  BattleGesture? get playerGesture => _playerGesture;
  BattleGesture? get opponentGesture => _opponentGesture;
  BattleResolution? get lastResolution => _lastResolution;
  bool get isFightOverlayVisible =>
      _phase == BattlePhase.choosingMove || _phase == BattlePhase.resolving;
  bool get canShowdown =>
      _phase == BattlePhase.choosingMove && _playerGesture != null;

  ChampionMove? get selectedPlayerMove =>
      _playerGesture == null ? null : _player.champion.moveFor(_playerGesture!);

  void startFight() {
    if (_phase != BattlePhase.command) return;

    _lastResolution = null;
    _playerGesture = null;
    _opponentGesture = _opponentStrategy.chooseMove(
      self: _opponent,
      opponent: _player,
    );
    _phase = BattlePhase.choosingMove;
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
      player: _player,
      opponent: _opponent,
      playerGesture: _playerGesture!,
      opponentGesture: _opponentGesture!,
    );
    _lastResolution = resolution;
    _player = _player.takeDamage(resolution.damageToPlayer);
    _opponent = _opponent.takeDamage(resolution.damageToOpponent);
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1250));
    if (_disposed) return;

    _phase = _player.isDefeated || _opponent.isDefeated
        ? BattlePhase.gameOver
        : BattlePhase.command;
    _playerGesture = null;
    _opponentGesture = null;
    _lastResolution = null;
    _resolving = false;
    notifyListeners();
  }

  void resetBattle() {
    _player = _initialPlayer;
    _opponent = _initialOpponent;
    _phase = BattlePhase.command;
    _playerGesture = null;
    _opponentGesture = null;
    _lastResolution = null;
    _resolving = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/battle_gesture.dart';

class BattleGestureIcon extends StatelessWidget {
  const BattleGestureIcon({
    super.key,
    required this.gesture,
    required this.size,
    this.critical = false,
  });

  final BattleGesture gesture;
  final double size;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }

  String get _assetPath => switch ((gesture, critical)) {
    (BattleGesture.rock, false) => 'assets/images/Piedra.png',
    (BattleGesture.paper, false) => 'assets/images/Papel.png',
    (BattleGesture.scissors, false) => 'assets/images/Tijera.png',
    (BattleGesture.rock, true) => 'assets/images/C Piedra.png',
    (BattleGesture.paper, true) => 'assets/images/C Papel.png',
    (BattleGesture.scissors, true) => 'assets/images/C Tijera.png',
  };
}

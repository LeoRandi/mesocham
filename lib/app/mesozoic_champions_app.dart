import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/battle/presentation/pages/battle_room_page.dart';
import '../features/menu/presentation/pages/game_menu_page.dart';

class MesozoicChampionsApp extends StatelessWidget {
  const MesozoicChampionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mesozoic Champions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<void> _onGenerateRoute(RouteSettings settings) {
    final page = settings.name == '/battle'
        ? const BattleRoomPage()
        : const GameMenuPage();

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.025, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

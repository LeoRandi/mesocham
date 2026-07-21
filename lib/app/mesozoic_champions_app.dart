import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/battle/presentation/pages/battle_room_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/loading/presentation/pages/game_loading_page.dart';
import '../features/menu/presentation/pages/game_menu_page.dart';

class MesozoicChampionsApp extends StatelessWidget {
  const MesozoicChampionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mesozoic Champions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<void> _onGenerateRoute(RouteSettings settings) {
    final loadingDestination = settings.arguments is String
        ? settings.arguments! as String
        : '/menu';
    final page = switch (settings.name) {
      '/menu' => const GameMenuPage(),
      '/loading' => GameLoadingPage(
        destinationRoute: loadingDestination,
        retainedRouteName: loadingDestination == '/battle' ? '/menu' : null,
      ),
      '/battle' => const BattleRoomPage(),
      _ => const HomePage(),
    };
    final usesHorizontalTransition =
        settings.name == '/menu' ||
        settings.name == '/loading' ||
        settings.name == '/battle';

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: Duration(
        milliseconds: usesHorizontalTransition ? 360 : 520,
      ),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final exiting = SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
              .animate(
                CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeInCubic,
                  reverseCurve: Curves.easeOutCubic,
                ),
              ),
          child: child,
        );
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        if (usesHorizontalTransition) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: exiting,
          );
        }

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.025, end: 1).animate(curved),
            child: exiting,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/battle/presentation/pages/battle_room_page.dart';
import '../features/champions/data/local/local_champion_catalog.dart';
import '../features/champions/domain/repositories/champion_catalog.dart';
import '../features/collection/presentation/pages/collection_page.dart';
import '../features/decks/domain/entities/player_deck.dart';
import '../features/decks/presentation/pages/deck_creation_page.dart';
import '../features/home/data/player_preferences.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/loading/presentation/pages/game_loading_page.dart';
import '../features/menu/presentation/pages/game_menu_page.dart';

class MesozoicChampionsApp extends StatelessWidget {
  const MesozoicChampionsApp({super.key, this.catalog, this.playerPreferences});

  final ChampionCatalog? catalog;
  final PlayerPreferences? playerPreferences;

  @override
  Widget build(BuildContext context) {
    final resolvedCatalog = catalog ?? LocalChampionCatalog();
    final resolvedPlayerPreferences = playerPreferences ?? PlayerPreferences();

    return MaterialApp(
      title: 'Mesozoic Champions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      onGenerateRoute: (settings) => _onGenerateRoute(
        settings,
        catalog: resolvedCatalog,
        playerPreferences: resolvedPlayerPreferences,
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(
    RouteSettings settings, {
    required ChampionCatalog catalog,
    required PlayerPreferences playerPreferences,
  }) {
    final loadingRequest = settings.arguments is GameLoadingRequest
        ? settings.arguments! as GameLoadingRequest
        : null;
    final loadingDestination =
        loadingRequest?.destinationRoute ??
        (settings.arguments is String
            ? settings.arguments! as String
            : '/menu');
    final page = switch (settings.name) {
      '/menu' => GameMenuPage(
        catalog: catalog,
        playerPreferences: playerPreferences,
      ),
      '/loading' => GameLoadingPage(
        catalog: catalog,
        destinationRoute: loadingDestination,
        destinationArguments: loadingRequest?.destinationArguments,
        retainedRouteName:
            loadingDestination == '/battle' ||
                loadingDestination == '/collection'
            ? '/menu'
            : null,
      ),
      '/battle' => BattleRoomPage(
        catalog: catalog,
        playerPreferences: playerPreferences,
        playerDeck: settings.arguments is PlayerDeck
            ? settings.arguments! as PlayerDeck
            : null,
      ),
      '/collection' => CollectionPage(
        catalog: catalog,
        playerPreferences: playerPreferences,
      ),
      '/deck-creation' => DeckCreationPage(
        catalog: catalog,
        playerPreferences: playerPreferences,
        deckToEdit: settings.arguments is PlayerDeck
            ? settings.arguments! as PlayerDeck
            : null,
      ),
      _ => HomePage(catalog: catalog, playerPreferences: playerPreferences),
    };
    final usesHorizontalTransition =
        settings.name == '/menu' ||
        settings.name == '/loading' ||
        settings.name == '/battle' ||
        settings.name == '/collection' ||
        settings.name == '/deck-creation';

    return PageRouteBuilder<dynamic>(
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

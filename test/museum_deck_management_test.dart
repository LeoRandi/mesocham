import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/app/mesozoic_champions_app.dart';
import 'package:mesocham/features/champions/data/local/local_champion_catalog.dart';
import 'package:mesocham/features/decks/domain/entities/player_deck.dart';
import 'package:mesocham/features/home/data/player_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<({LocalChampionCatalog catalog, PlayerPreferences preferences})>
  pumpCollection(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);

    final catalog = LocalChampionCatalog();
    final preferences = PlayerPreferences();
    await preferences.saveChampionCollectionCounts({
      catalog.champions.first.id: 3,
    });
    await tester.pumpWidget(
      MesozoicChampionsApp(catalog: catalog, playerPreferences: preferences),
    );
    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamedAndRemoveUntil<void>('/collection', (route) => false);
    await tester.pumpAndSettle();
    return (catalog: catalog, preferences: preferences);
  }

  testWidgets('Museum deck-list button is disabled without saved decks', (
    tester,
  ) async {
    await pumpCollection(tester);

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('collection-view-decks')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Museum deck list opens a saved deck for editing', (
    tester,
  ) async {
    final (:catalog, :preferences) = await pumpCollection(tester);
    final championId = catalog.champions.first.id;
    final deck = PlayerDeck.create(
      name: 'Favorito-1',
      championIds: [championId, championId, championId],
      isFavorite: true,
    );
    await preferences.saveDeck(deck);

    // Re-entering Collection reloads the newly saved deck list.
    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushReplacementNamed('/collection');
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('collection-view-decks')),
    );
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('collection-view-decks')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('museum-deck-dialog')), findsOneWidget);
    expect(find.text('EDITAR'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('museum-deck-${deck.id}')));
    await tester.pumpAndSettle();

    expect(find.text('EDITAR MAZO'), findsOneWidget);
    final nameField = tester.widget<TextField>(
      find.byKey(const ValueKey('deck-name-field')),
    );
    expect(nameField.controller!.text, 'Favorito-1');

    await tester.enterText(
      find.byKey(const ValueKey('deck-name-field')),
      'Renamed_Deck!?',
    );
    await tester.tap(find.byKey(const ValueKey('save-deck-button')));
    await tester.pumpAndSettle();

    final savedDecks = await preferences.getDecks();
    expect(savedDecks, hasLength(1));
    expect(savedDecks.single.id, deck.id);
    expect(savedDecks.single.name, 'RenamedDeck');
    expect(savedDecks.single.isFavorite, isTrue);
  });
}

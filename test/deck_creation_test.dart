import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/core/theme/app_theme.dart';
import 'package:mesocham/features/battle/application/services/fossil_race_team_factory.dart';
import 'package:mesocham/features/champions/data/local/local_champion_catalog.dart';
import 'package:mesocham/features/collection/presentation/pages/champion_info_page.dart';
import 'package:mesocham/features/decks/domain/entities/player_deck.dart';
import 'package:mesocham/features/decks/presentation/pages/deck_creation_page.dart';
import 'package:mesocham/features/home/data/player_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('decks persist every battle-relevant field in order', () async {
    final preferences = PlayerPreferences();
    final timestamp = DateTime.utc(2026, 8, 1, 12, 30);
    final deck = PlayerDeck.create(
      name: 'Mis gigantes',
      championIds: const ['alamosaurus', 'utahraptor', 'alamosaurus'],
      isFavorite: true,
      now: timestamp,
    );

    await preferences.saveDeck(deck);
    final savedDecks = await preferences.getDecks();

    expect(savedDecks, hasLength(1));
    expect(savedDecks.single.id, deck.id);
    expect(savedDecks.single.name, 'Mis gigantes');
    expect(savedDecks.single.championIds, const [
      'alamosaurus',
      'utahraptor',
      'alamosaurus',
    ]);
    expect(savedDecks.single.isFavorite, isTrue);
    expect(savedDecks.single.schemaVersion, PlayerDeck.currentSchemaVersion);
    expect(savedDecks.single.createdAt, timestamp);
    expect(savedDecks.single.updatedAt, timestamp);
  });

  test('saved decks build the player battle team in exact slot order', () {
    final catalog = LocalChampionCatalog();
    final first = catalog.champions[0].id;
    final second = catalog.champions[1].id;
    final factory = FossilRaceTeamFactory(
      catalog: catalog,
      random: math.Random(4),
    );

    final teams = factory.create(
      {first: 2, second: 1},
      playerChampionIds: [first, second, first],
    );

    expect(
      teams.playerTeam.combatants.map((combatant) => combatant.champion.id),
      [first, second, first],
    );
    expect(
      () =>
          factory.create({first: 2}, playerChampionIds: [first, first, first]),
      throwsA(isA<StateError>()),
    );
  });

  test('deck names keep only allowed characters and stop at 12', () {
    final createdAt = DateTime.utc(2026, 8, 1);
    final deck = PlayerDeck.create(
      name: 'Mazo_#Ágil.123456',
      championIds: const ['a', 'b', 'c'],
      isFavorite: false,
      now: createdAt,
    );

    expect(deck.name, 'MazoÁgil.123');
    final edited = deck.updated(
      name: 'Nuevo*nombre-largo',
      championIds: deck.championIds,
      isFavorite: true,
      now: createdAt.add(const Duration(minutes: 5)),
    );
    expect(edited.name, 'Nuevonombre-');
    expect(edited.id, deck.id);
    expect(edited.createdAt, deck.createdAt);
    expect(edited.updatedAt, isNot(deck.updatedAt));
  });

  testWidgets('creation page selects repeated copies and saves the full deck', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);

    final catalog = LocalChampionCatalog();
    final champion = catalog.champions.first;
    final preferences = PlayerPreferences();
    await preferences.saveChampionCollectionCounts({champion.id: 3});
    PlayerDeck? createdDeck;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  createdDeck = await Navigator.of(context).push<PlayerDeck>(
                    MaterialPageRoute<PlayerDeck>(
                      builder: (context) => DeckCreationPage(
                        catalog: catalog,
                        playerPreferences: preferences,
                      ),
                    ),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('Deck-1'), findsOneWidget);
    expect(find.text('PRIMER\nCAMPEÓN'), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-slot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-slot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-slot-2')), findsOneWidget);

    await tester.tap(
      find.byKey(ValueKey('deck-champion-${champion.id}')),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChampionInfoPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(ChampionInfoPage))).pop();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('deck-name-field')),
      'Equipo_Alfa!.-123',
    );
    await tester.tap(find.byKey(const ValueKey('deck-favorite-toggle')));
    for (var copy = 0; copy < 3; copy++) {
      await tester.tap(find.byKey(ValueKey('deck-champion-${champion.id}')));
      await tester.pump();
    }

    await tester.tap(
      find.byKey(const ValueKey('deck-slot-0')),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChampionInfoPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(ChampionInfoPage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('save-deck-button')));
    await tester.pumpAndSettle();

    expect(createdDeck, isNotNull);
    expect(createdDeck!.name, 'EquipoAlfa.-');
    expect(createdDeck!.championIds, [champion.id, champion.id, champion.id]);
    expect(createdDeck!.isFavorite, isTrue);
    final savedDecks = await preferences.getDecks();
    expect(savedDecks.single.id, createdDeck!.id);
  });
}

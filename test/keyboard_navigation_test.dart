import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/app/mesozoic_champions_app.dart';
import 'package:mesocham/features/champions/data/local/local_champion_catalog.dart';
import 'package:mesocham/features/decks/domain/entities/player_deck.dart';
import 'package:mesocham/features/home/data/player_preferences.dart';
import 'package:mesocham/features/loading/presentation/pages/game_loading_page.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  Future<void> pumpFor(
    WidgetTester tester,
    Duration duration, {
    Duration step = const Duration(milliseconds: 50),
  }) async {
    var elapsed = Duration.zero;
    while (elapsed < duration) {
      await tester.pump(step);
      elapsed += step;
    }
  }

  Future<PlayerDeck?> pumpGame(
    WidgetTester tester, {
    bool withSavedDeck = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final catalog = LocalChampionCatalog();
    final preferences = PlayerPreferences();
    final champion = catalog.champions.first;
    await preferences.savePlayerName('Keyboard tester');
    await preferences.saveChampionCollectionCounts({champion.id: 3});
    final deck = PlayerDeck.create(
      name: 'Keyboard deck',
      championIds: [champion.id, champion.id, champion.id],
      isFavorite: true,
    );
    if (withSavedDeck) {
      await preferences.saveDeck(deck);
    }

    await tester.pumpWidget(
      MesozoicChampionsApp(catalog: catalog, playerPreferences: preferences),
    );
    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamedAndRemoveUntil<void>('/menu', (route) => false);
    await pumpFor(tester, const Duration(milliseconds: 700));
    return withSavedDeck ? deck : null;
  }

  FocusNode focusNodeFor(WidgetTester tester, Finder finder) {
    final widget = tester.widget(finder);
    return switch (widget) {
      InkWell(:final focusNode?) => focusNode,
      Focus(:final focusNode?) => focusNode,
      ButtonStyleButton(:final focusNode?) => focusNode,
      _ => throw TestFailure('No focus node found for $finder.'),
    };
  }

  testWidgets('Tab and number keys focus the four top-level menu options', (
    tester,
  ) async {
    await pumpGame(tester);

    final arena = find.byKey(const ValueKey('menu-option-arena'));
    final excavation = find.byKey(const ValueKey('menu-option-excavation'));
    final missions = find.byKey(const ValueKey('menu-option-missions'));

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(focusNodeFor(tester, arena).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusNodeFor(tester, excavation).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
    await tester.pump();
    expect(focusNodeFor(tester, missions).hasFocus, isTrue);
    expect(find.byKey(const ValueKey('description-missions')), findsOneWidget);
    expect(find.text('4'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(focusNodeFor(tester, missions).hasFocus, isTrue);
    expect(find.text('YOUR CHAMPION'), findsNothing);
  });

  testWidgets('Arena opens its submenu and deck picker starts battle loading', (
    tester,
  ) async {
    final deck = (await pumpGame(tester))!;

    final arena = find.byKey(const ValueKey('menu-option-arena'));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(focusNodeFor(tester, arena).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 500));

    final fossilRace = find.byKey(const ValueKey('menu-option-fossil-race'));
    final extinctionColiseum = find.byKey(
      const ValueKey('menu-option-extinction-coliseum'),
    );
    expect(fossilRace, findsOneWidget);
    expect(extinctionColiseum, findsOneWidget);
    expect(find.byKey(const ValueKey('menu-option-tutorial')), findsOneWidget);
    expect(focusNodeFor(tester, fossilRace).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(focusNodeFor(tester, extinctionColiseum).hasFocus, isTrue);
    expect(find.text('YOUR CHAMPION'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(arena, findsOneWidget);
    expect(focusNodeFor(tester, arena).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('arena-deck-dialog')), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('arena-deck-${deck.id}')));
    await pumpFor(tester, const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('arena-deck-dialog')), findsNothing);
    expect(find.byType(GameLoadingPage), findsOneWidget);
  });

  testWidgets('Arena opens deck creation when the player has no decks', (
    tester,
  ) async {
    await pumpGame(tester, withSavedDeck: false);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 1500));

    expect(find.text('Deck-1'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-deck-button')), findsOneWidget);
  });

  testWidgets('number shortcuts focus battle commands and move controls', (
    tester,
  ) async {
    await pumpGame(tester);

    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamed<void>('/battle');
    await pumpFor(tester, const Duration(milliseconds: 800));

    final fight = find.byKey(const ValueKey('battle-action-1'));
    final teamSkill = find.byKey(const ValueKey('battle-action-2'));
    final swap = find.byKey(const ValueKey('battle-action-4'));

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pump();
    expect(focusNodeFor(tester, swap).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(focusNodeFor(tester, fight).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusNodeFor(tester, teamSkill).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 500));

    final paper = find.byKey(const ValueKey('battle-move-paper'));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(focusNodeFor(tester, paper).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 500));

    final showdown = find.byKey(const ValueKey('showdown'));
    expect(showdown, findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
    await tester.pump();
    expect(focusNodeFor(tester, showdown).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 2200));
    expect(focusNodeFor(tester, fight).hasFocus, isTrue);
  });
}

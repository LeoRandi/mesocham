import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/app/mesozoic_champions_app.dart';
import 'package:mesocham/features/battle/domain/entities/battle_gesture.dart';
import 'package:mesocham/features/battle/presentation/widgets/gesture_wheel.dart';
import 'package:mesocham/features/champions/data/local/local_champion_catalog.dart';
import 'package:mesocham/features/champions/presentation/widgets/battle_gesture_icon.dart';
import 'package:mesocham/features/companions/presentation/widgets/companion_orb.dart';
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
    await pumpFor(tester, const Duration(milliseconds: 400));
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
    final speciesCards = find.byKey(const ValueKey('battle-action-2'));
    final swap = find.byKey(const ValueKey('battle-action-3'));

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();
    expect(focusNodeFor(tester, swap).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(focusNodeFor(tester, fight).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusNodeFor(tester, speciesCards).hasFocus, isTrue);

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

  testWidgets(
    'fight flow animates mirrored rings and previews moves on hover',
    (tester) async {
      await pumpGame(tester);
      tester.view.physicalSize = const Size(835, 528);
      await tester.pump();

      Navigator.of(
        tester.element(find.byType(Scaffold)),
      ).pushNamed<void>('/battle');
      await pumpFor(tester, const Duration(milliseconds: 800));

      final opponentWheel = find.byKey(const ValueKey('opponent-fight-wheel'));
      final playerWheel = find.byKey(const ValueKey('player-fight-wheel'));
      final actionPalette = find.byKey(
        const ValueKey('animated-battle-action-palette'),
      );
      final hiddenOpponentRect = tester.getRect(opponentWheel);
      final hiddenPlayerRect = tester.getRect(playerWheel);
      final normalPaletteRect = tester.getRect(actionPalette);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      final movingOpponentRect = tester.getRect(opponentWheel);
      final movingPlayerRect = tester.getRect(playerWheel);
      await tester.pump(const Duration(milliseconds: 320));
      final shownOpponentRect = tester.getRect(opponentWheel);
      final shownPlayerRect = tester.getRect(playerWheel);
      final fightPaletteRect = tester.getRect(actionPalette);

      expect(
        movingOpponentRect.center.dy,
        inExclusiveRange(
          hiddenOpponentRect.center.dy,
          shownOpponentRect.center.dy,
        ),
      );
      expect(
        movingPlayerRect.center.dy,
        inExclusiveRange(shownPlayerRect.center.dy, hiddenPlayerRect.center.dy),
      );
      expect(
        fightPaletteRect.center.dx,
        closeTo(normalPaletteRect.center.dx, 0.01),
      );
      expect(fightPaletteRect.width, greaterThan(normalPaletteRect.width));
      expect(
        find.byKey(const ValueKey('fight-background-filter')),
        findsOneWidget,
      );
      for (final side in ['opponent', 'player']) {
        expect(find.byKey(ValueKey('$side-fight-ring-outer')), findsOneWidget);
        expect(find.byKey(ValueKey('$side-fight-ring-inner')), findsOneWidget);
      }
      final opponentChampion = tester
          .widget<GestureWheel>(opponentWheel)
          .champion;
      final playerChampion = tester.widget<GestureWheel>(playerWheel).champion;
      for (final gesture in BattleGesture.values) {
        for (final (side, champion) in [
          ('opponent-move', opponentChampion),
          ('battle-move', playerChampion),
        ]) {
          final icon = tester.widget<BattleGestureIcon>(
            find.descendant(
              of: find.byKey(ValueKey('$side-${gesture.name}')),
              matching: find.byType(BattleGestureIcon),
            ),
          );
          expect(icon.critical, champion.moveFor(gesture).isCritical);
          expect(icon.size, closeTo(72, 0.01));
        }
      }
      final opponentRock = find.byKey(const ValueKey('opponent-move-rock'));
      final opponentScissors = find.byKey(
        const ValueKey('opponent-move-scissors'),
      );
      final playerRock = find.byKey(const ValueKey('battle-move-rock'));
      final playerScissors = find.byKey(const ValueKey('battle-move-scissors'));
      expect(
        tester.getCenter(opponentRock).dy,
        greaterThan(tester.getCenter(opponentScissors).dy),
      );
      expect(
        tester.getCenter(playerRock).dy,
        lessThan(tester.getCenter(playerScissors).dy),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(tester.getCenter(opponentRock));
      await tester.pump();
      final opponentDetails = find.byKey(
        const ValueKey('opponent-move-details-rock'),
      );
      final opponentMove = opponentChampion.moveFor(BattleGesture.rock);
      final opponentPotency =
          opponentMove.potency == opponentMove.potency.roundToDouble()
          ? opponentMove.potency.toStringAsFixed(0)
          : opponentMove.potency.toStringAsFixed(1);
      expect(opponentDetails, findsOneWidget);
      expect(
        find.descendant(
          of: opponentDetails,
          matching: find.text(opponentMove.name),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: opponentDetails,
          matching: find.text(opponentMove.description),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: opponentDetails,
          matching: find.text(opponentPotency),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getRect(opponentDetails)
            .contains(tester.getCenter(opponentRock)),
        isFalse,
      );

      await mouse.moveTo(tester.getCenter(playerRock));
      await tester.pump();
      expect(opponentDetails, findsNothing);
      expect(
        find.byKey(const ValueKey('player-move-details-rock')),
        findsOneWidget,
      );

      for (final gesture in [BattleGesture.scissors, BattleGesture.paper]) {
        final target = find.byKey(ValueKey('battle-move-${gesture.name}'));
        final pointerPosition = tester.getCenter(target);
        await mouse.moveTo(pointerPosition);
        await tester.pump();
        final details = find.byKey(
          ValueKey('player-move-details-${gesture.name}'),
        );
        final detailsRect = tester.getRect(details);
        expect(pointerPosition.dy - detailsRect.bottom, closeTo(10, 0.01));
        expect(
          pointerPosition.dx >= detailsRect.left &&
              pointerPosition.dx <= detailsRect.right,
          isTrue,
        );
      }

      await mouse.moveTo(tester.getCenter(playerRock));
      await tester.pump();

      await tester.tap(playerRock);
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('selected-battle-move-rock')),
        findsOneWidget,
      );
      expect(find.text('SHOWDOWN'), findsOneWidget);
      expect(find.text('4  SHOWDOWN'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      await tester.pump();
      expect(
        focusNodeFor(tester, find.byKey(const ValueKey('showdown'))).hasFocus,
        isTrue,
      );
      await mouse.removePointer();
    },
  );

  testWidgets(
    'long press pins move details and wild companion hover explains its effect',
    (tester) async {
      await pumpGame(tester);
      tester.view.physicalSize = const Size(835, 528);
      await tester.pump();

      Navigator.of(
        tester.element(find.byType(Scaffold)),
      ).pushNamed<void>('/battle');
      await pumpFor(tester, const Duration(milliseconds: 800));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpFor(tester, const Duration(milliseconds: 600));

      final playerRock = find.byKey(const ValueKey('battle-move-rock'));
      final playerRockDetails = find.byKey(
        const ValueKey('player-move-details-rock'),
      );
      await tester.longPress(playerRock);
      await tester.pump();
      expect(playerRockDetails, findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(playerRockDetails, findsOneWidget);

      await tester.tapAt(tester.getCenter(playerRockDetails));
      await tester.pump();
      expect(playerRockDetails, findsOneWidget);
      expect(
        find.byKey(const ValueKey('selected-battle-move-rock')),
        findsNothing,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(playerRockDetails, findsNothing);

      await tester.longPress(playerRock);
      await tester.pump();
      expect(playerRockDetails, findsOneWidget);

      final opponentPaper = find.byKey(const ValueKey('opponent-move-paper'));
      await tester.longPress(opponentPaper);
      await tester.pump();
      expect(playerRockDetails, findsNothing);
      expect(
        find.byKey(const ValueKey('opponent-move-details-paper')),
        findsOneWidget,
      );

      await tester.tap(playerRock);
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('opponent-move-details-paper')),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpFor(tester, const Duration(milliseconds: 2200));

      final wildCompanionFinder = find.byWidgetPredicate(
        (widget) => widget is CompanionOrb && widget.wild,
      );
      expect(wildCompanionFinder, findsOneWidget);
      final wildCompanion = tester
          .widget<CompanionOrb>(wildCompanionFinder)
          .companion;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(tester.getCenter(wildCompanionFinder));
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.text('${wildCompanion.name}\n${wildCompanion.effectDescription}'),
        findsOneWidget,
      );
      await mouse.removePointer();
    },
  );

  testWidgets('fight palette can switch to either alternate action', (
    tester,
  ) async {
    await pumpGame(tester);
    tester.view.physicalSize = const Size(835, 528);
    await tester.pump();

    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamed<void>('/battle');
    await pumpFor(tester, const Duration(milliseconds: 800));

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('battle-move-rock')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('SHOWDOWN'), findsOneWidget);

    final speciesCards = find.descendant(
      of: find.byKey(const ValueKey('fight-palette-action-2')),
      matching: find.text('SPECIES\nCARDS'),
    );
    await tester.tap(speciesCards);
    await pumpFor(tester, const Duration(milliseconds: 1150));
    expect(find.byKey(const ValueKey('species-flow-visible')), findsOneWidget);
    expect(find.text('SHOWDOWN'), findsNothing);

    final fight = find.descendant(
      of: find.byKey(const ValueKey('species-palette-action-1')),
      matching: find.text('FIGHT'),
    );
    await tester.tap(fight);
    await pumpFor(tester, const Duration(milliseconds: 1150));
    expect(
      find.byKey(const ValueKey('selected-battle-move-rock')),
      findsNothing,
    );
    expect(find.text('SHOWDOWN'), findsNothing);

    final swap = find.descendant(
      of: find.byKey(const ValueKey('fight-palette-action-3')),
      matching: find.text('SWAP'),
    );
    await tester.tap(swap);
    await pumpFor(tester, const Duration(milliseconds: 1150));
    expect(find.byKey(const ValueKey('swap-flow-visible')), findsOneWidget);
    expect(find.byKey(const ValueKey('species-flow-visible')), findsNothing);
  });

  testWidgets('expanded swap palette cancels and switches actions', (
    tester,
  ) async {
    await pumpGame(tester);
    tester.view.physicalSize = const Size(835, 528);
    await tester.pump();

    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamed<void>('/battle');
    await pumpFor(tester, const Duration(milliseconds: 800));

    final palette = find.byKey(
      const ValueKey('animated-battle-action-palette'),
    );
    final playerReserve = find.byKey(const ValueKey('expanded-player-reserve'));
    final normalPaletteRect = tester.getRect(palette);
    final hiddenReserveRect = tester.getRect(playerReserve);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    final movingPaletteRect = tester.getRect(palette);
    final movingReserveRect = tester.getRect(playerReserve);
    await tester.pump(const Duration(milliseconds: 320));
    final swapPaletteRect = tester.getRect(palette);
    final shownReserveRect = tester.getRect(playerReserve);

    expect(
      movingPaletteRect.center.dx,
      inExclusiveRange(swapPaletteRect.center.dx, normalPaletteRect.center.dx),
    );
    expect(
      movingPaletteRect.width,
      inExclusiveRange(normalPaletteRect.width, swapPaletteRect.width),
    );
    expect(
      movingReserveRect.left,
      inExclusiveRange(shownReserveRect.left, hiddenReserveRect.left),
    );

    expect(
      find.byKey(const ValueKey('swap-background-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expanded-opponent-reserve')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expanded-player-reserve')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('swap-target-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('swap-target-2')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final expandedSwap = find.byKey(const ValueKey('swap-palette-action-3'));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();
    expect(focusNodeFor(tester, expandedSwap).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('swap-flow-visible')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 600));
    final expandedSpeciesCards = find.descendant(
      of: find.byKey(const ValueKey('swap-palette-action-2')),
      matching: find.text('SPECIES\nCARDS'),
    );
    await tester.tap(expandedSpeciesCards);
    await pumpFor(tester, const Duration(milliseconds: 1150));
    expect(find.byKey(const ValueKey('swap-flow-visible')), findsNothing);
    expect(
      find.byKey(const ValueKey('player-species-card-menu')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('species-flow-visible')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 600));
    final expandedFight = find.descendant(
      of: find.byKey(const ValueKey('swap-palette-action-1')),
      matching: find.text('FIGHT'),
    );
    await tester.tap(expandedFight);
    await pumpFor(tester, const Duration(milliseconds: 1150));
    expect(find.byKey(const ValueKey('swap-flow-visible')), findsNothing);
    expect(find.byKey(const ValueKey('battle-move-paper')), findsOneWidget);
  });

  testWidgets('species-card action opens both team menus and selects a card', (
    tester,
  ) async {
    await pumpGame(tester);
    tester.view.physicalSize = const Size(835, 528);
    await tester.pump();

    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamed<void>('/battle');
    await pumpFor(tester, const Duration(milliseconds: 800));

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final palette = find.byKey(
      const ValueKey('animated-battle-action-palette'),
    );
    final playerSpeciesMenu = find.byKey(
      const ValueKey('player-species-card-menu'),
    );
    final normalPaletteRect = tester.getRect(palette);
    final hiddenMenuRect = tester.getRect(playerSpeciesMenu);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    final movingPaletteRect = tester.getRect(palette);
    final movingMenuRect = tester.getRect(playerSpeciesMenu);
    await tester.pump(const Duration(milliseconds: 320));
    final speciesPaletteRect = tester.getRect(palette);
    final shownMenuRect = tester.getRect(playerSpeciesMenu);

    expect(
      movingPaletteRect.center.dy,
      inExclusiveRange(
        speciesPaletteRect.center.dy,
        normalPaletteRect.center.dy,
      ),
    );
    expect(
      movingPaletteRect.width,
      inExclusiveRange(normalPaletteRect.width, speciesPaletteRect.width),
    );
    expect(
      movingMenuRect.top,
      inExclusiveRange(shownMenuRect.top, hiddenMenuRect.top),
    );

    expect(
      find.byKey(const ValueKey('opponent-species-card-menu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('player-species-card-menu')),
      findsOneWidget,
    );
    for (var index = 0; index < 3; index++) {
      expect(
        find.byKey(ValueKey('opponent-species-card-$index')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('player-species-card-$index')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('player-species-card-0')));
    await pumpFor(tester, const Duration(milliseconds: 220));
    expect(
      find.byKey(const ValueKey('player-species-card-menu')),
      findsOneWidget,
    );
    expect(find.text('SELECTED'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, const Duration(milliseconds: 600));

    final pendingPanel = find.byKey(
      const ValueKey('pending-player-species-card-panel'),
    );
    final activeChampion = find.byKey(
      const ValueKey('player-active-champion-card'),
    );
    expect(pendingPanel, findsOneWidget);
    expect(find.text('Activada'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pending-player-species-card-image')),
      findsOneWidget,
    );
    expect(
      tester.getRect(pendingPanel).right,
      lessThan(tester.getRect(activeChampion).left),
    );
    expect(
      tester.getRect(pendingPanel).bottom,
      greaterThanOrEqualTo(tester.view.physicalSize.height),
    );
  });
}

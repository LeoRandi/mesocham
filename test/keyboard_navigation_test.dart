import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/app/mesozoic_champions_app.dart';

void main() {
  Future<void> pumpGame(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MesozoicChampionsApp());
    await tester.pump();
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

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
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
    await tester.pumpAndSettle();
    expect(focusNodeFor(tester, missions).hasFocus, isTrue);
    expect(find.text('YOUR CHAMPION'), findsNothing);
  });

  testWidgets('Arena opens its submenu and Fossil Race launches the battle', (
    tester,
  ) async {
    await pumpGame(tester);

    final arena = find.byKey(const ValueKey('menu-option-arena'));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    expect(focusNodeFor(tester, arena).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    expect(focusNodeFor(tester, extinctionColiseum).hasFocus, isTrue);
    expect(find.text('YOUR CHAMPION'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(arena, findsOneWidget);
    expect(focusNodeFor(tester, arena).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('YOUR CHAMPION'), findsOneWidget);
  });

  testWidgets('number shortcuts focus battle commands and move controls', (
    tester,
  ) async {
    await pumpGame(tester);

    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamed<void>('/battle');
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    final paper = find.byKey(const ValueKey('battle-move-paper'));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(focusNodeFor(tester, paper).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final showdown = find.byKey(const ValueKey('showdown'));
    expect(showdown, findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
    await tester.pump();
    expect(focusNodeFor(tester, showdown).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(focusNodeFor(tester, fight).hasFocus, isTrue);
  });
}

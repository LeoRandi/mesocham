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

  testWidgets('Tab focuses the menu option and Enter opens it', (tester) async {
    await pumpGame(tester);

    const menuButtonKey = ValueKey('menu-fossil-race');
    final menuButton = find.byKey(menuButtonKey);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusNodeFor(tester, menuButton).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('YOUR CHAMPION'), findsOneWidget);
  });

  testWidgets('number shortcuts focus battle commands and move controls', (
    tester,
  ) async {
    await pumpGame(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
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

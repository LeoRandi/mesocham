import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Creates 1-9 shortcuts that move focus to the matching item.
///
/// Null entries leave that number unassigned. Both the number row and the
/// numeric keypad are supported.
Map<ShortcutActivator, Intent> numberFocusShortcuts(
  List<FocusNode?> focusNodes,
) {
  assert(focusNodes.length <= 9, 'Only shortcuts 1 through 9 are supported.');

  const digitKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];
  const numpadKeys = [
    LogicalKeyboardKey.numpad1,
    LogicalKeyboardKey.numpad2,
    LogicalKeyboardKey.numpad3,
    LogicalKeyboardKey.numpad4,
    LogicalKeyboardKey.numpad5,
    LogicalKeyboardKey.numpad6,
    LogicalKeyboardKey.numpad7,
    LogicalKeyboardKey.numpad8,
    LogicalKeyboardKey.numpad9,
  ];

  return {
    for (var index = 0; index < focusNodes.length; index++) ...{
      if (focusNodes[index] case final focusNode?) ...{
        SingleActivator(digitKeys[index]): RequestFocusIntent(focusNode),
        SingleActivator(numpadKeys[index]): RequestFocusIntent(focusNode),
      },
    },
  };
}

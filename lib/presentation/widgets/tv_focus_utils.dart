import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyEvent, KeyDownEvent, LogicalKeyboardKey;

/// TV remote helpers — shared across all screens.
bool isTvActivateKey(KeyEvent event) {
  return event is KeyDownEvent &&
      (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.space);
}

bool isTvBackKey(KeyEvent event) {
  if (event is! KeyDownEvent) return false;
  return event.logicalKey == LogicalKeyboardKey.escape ||
      event.logicalKey == LogicalKeyboardKey.goBack;
}

KeyEventResult handleTvActivate(KeyEvent event, VoidCallback onActivate) {
  if (isTvActivateKey(event)) {
    onActivate();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

KeyEventResult handleTvBack(KeyEvent event, VoidCallback onBack) {
  if (isTvBackKey(event)) {
    onBack();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

/// Restores focus on [node] after the frame completes.
void restoreFocusAfterFrame(FocusNode node, {bool Function()? ifMounted}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ifMounted != null && !ifMounted()) return;
    if (node.canRequestFocus) {
      node.requestFocus();
    }
  });
}

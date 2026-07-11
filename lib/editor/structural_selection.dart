import 'package:flutter/services.dart';

import 'krom_code_controller.dart';

/// Bracket-based structural selection — Shift+Alt+→ expands, Shift+Alt+← shrinks.
///
/// Upgrade path: replace [_findEnclosingBrackets] with
/// [ParserService.getNodeAtPosition] for AST-aware expansion.
class StructuralSelection {
  StructuralSelection();

  final List<TextSelection> _stack = [];

  void clear() => _stack.clear();

  void expand(KromCodeController controller) {
    final current = controller.selection;
    if (!current.isValid) return;

    final next = _findEnclosingBrackets(controller.fullText, current);
    if (next == null) return;

    _stack.add(current);
    controller.selection = next;
  }

  void shrink(KromCodeController controller) {
    if (_stack.isEmpty) return;
    controller.selection = _stack.removeLast();
  }

  /// Finds the smallest bracket pair `()`, `[]`, `{}` that fully encloses
  /// [selection]. Returns the selection inside those brackets on the first
  /// call; if [selection] already equals that inner range, returns the range
  /// inclusive of the brackets themselves.
  static TextSelection? _findEnclosingBrackets(
    String text,
    TextSelection selection,
  ) {
    const opens = '({[';
    const closes = ')}]';

    final start = selection.start;
    final end = selection.end;

    var depth = 0;
    for (var i = start - 1; i >= 0; i--) {
      final c = text[i];
      final closeIdx = closes.indexOf(c);
      if (closeIdx >= 0) {
        depth++;
        continue;
      }
      final openIdx = opens.indexOf(c);
      if (openIdx < 0) continue;

      if (depth > 0) {
        depth--;
        continue;
      }

      final matchClose = closes[openIdx];
      var inner = 0;
      for (var j = i + 1; j < text.length; j++) {
        if (text[j] == text[i]) {
          inner++;
        } else if (text[j] == matchClose) {
          if (inner > 0) {
            inner--;
            continue;
          }
          final innerSel = TextSelection(baseOffset: i + 1, extentOffset: j);
          if (selection.start == i + 1 && selection.end == j) {
            return TextSelection(baseOffset: i, extentOffset: j + 1);
          }
          if (j >= end) return innerSel;
          break;
        }
      }
      break;
    }
    return null;
  }
}

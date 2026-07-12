import 'package:flutter/services.dart';

import 'krom_code_controller.dart';

/// Multi-cursor helpers — Ctrl+D and Ctrl+Shift+L.
class MultiCursorController {
  MultiCursorController(this._controller);

  final KromCodeController _controller;

  List<TextSelection> get extraSelections => _controller.extraSelections;

  void clear() => _controller.clearExtraSelections();

  /// Adds the next occurrence of the selected word as an extra cursor.
  void addNextOccurrence() {
    final sel = _controller.selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final text = _controller.fullText;
    final word = text.substring(sel.start, sel.end);
    if (word.isEmpty) return;

    var searchFrom = sel.end;
    while (true) {
      final idx = text.indexOf(word, searchFrom);
      if (idx < 0) return;
      final match = TextSelection(baseOffset: idx, extentOffset: idx + word.length);
      if (!_hasSelection(match)) {
        _controller.addExtraSelection(match);
        return;
      }
      searchFrom = idx + 1;
    }
  }

  /// Selects all occurrences of the current word in the file.
  void selectAllOccurrences() {
    final sel = _controller.selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final text = _controller.fullText;
    final word = text.substring(sel.start, sel.end);
    if (word.isEmpty) return;

    _controller.clearExtraSelections();
    var idx = 0;
    while (true) {
      final found = text.indexOf(word, idx);
      if (found < 0) break;
      final match = TextSelection(baseOffset: found, extentOffset: found + word.length);
      if (found != sel.start) {
        _controller.addExtraSelection(match);
      }
      idx = found + 1;
    }
  }

  bool _hasSelection(TextSelection sel) {
    if (_controller.selection == sel) return true;
    for (final s in _controller.extraSelections) {
      if (s == sel) return true;
    }
    return false;
  }
}

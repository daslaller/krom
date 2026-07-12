import 'package:flutter/services.dart';
import 'package:parser_client/parser_client.dart';

import '../services/parser_service.dart';
import '../utils/text_position.dart';
import 'krom_code_controller.dart';

/// AST-aware structural selection with bracket fallback.
class StructuralSelection {
  StructuralSelection({this.parserService});

  final ParserService? parserService;
  final List<TextSelection> _stack = [];

  void clear() => _stack.clear();

  Future<void> expand(KromCodeController controller) async {
    final current = controller.selection;
    if (!current.isValid) return;

    final parser = parserService;
    if (parser != null && parser.isAvailable) {
      final astSel = await _expandViaParser(controller, current);
      if (astSel != null && astSel != current) {
        _stack.add(current);
        controller.selection = astSel;
        return;
      }
    }

    final next = _findEnclosingBrackets(controller.fullText, current);
    if (next == null) return;

    _stack.add(current);
    controller.selection = next;
  }

  void shrink(KromCodeController controller) {
    if (_stack.isEmpty) return;
    controller.selection = _stack.removeLast();
  }

  Future<TextSelection?> _expandViaParser(
    KromCodeController controller,
    TextSelection selection,
  ) async {
    final text = controller.fullText;
    final offset = selection.start.clamp(0, text.length);
    final (line, column) = offsetToLineChar(text, offset);

    final node = await parserService!.getNodeAtPosition(
      controller.filePath,
      line,
      column,
    );
    if (node == null) return null;

    final nodeSel = _nodeToSelection(text, node);
    if (nodeSel == null) return null;

    if (_contains(nodeSel, selection) && nodeSel != selection) {
      return nodeSel;
    }

    return _findEnclosingBrackets(text, selection);
  }

  static bool _contains(TextSelection outer, TextSelection inner) =>
      inner.start >= outer.start && inner.end <= outer.end;

  static TextSelection? _nodeToSelection(String text, ParserNodeInfo node) {
    final start = positionToOffset(text, node.startLine, node.startColumn);
    final end = positionToOffset(text, node.endLine, node.endColumn);
    if (end < start) return null;
    return TextSelection(
      baseOffset: start.clamp(0, text.length),
      extentOffset: end.clamp(0, text.length),
    );
  }

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

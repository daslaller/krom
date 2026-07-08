import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tree_sitter/flutter_tree_sitter.dart';

/// Configuration for a tree-sitter language grammar and highlight query.
class TreeSitterGrammar {
  const TreeSitterGrammar({
    required this.languageId,
    required this.language,
    required this.highlightQuery,
  });

  final String languageId;
  final Pointer language;
  final String highlightQuery;
}

/// Registry of tree-sitter grammars available at runtime.
///
/// Grammars are loaded lazily. Languages without a registered grammar fall
/// back to highlight.js via [KromCodeController].
class TreeSitterRegistry {
  TreeSitterRegistry._();

  static final TreeSitterRegistry instance = TreeSitterRegistry._();

  final Map<String, TreeSitterGrammar> _grammars = {};
  final Map<String, Highlighter> _highlighters = {};
  final Map<String, TreeSitterParser> _parsers = {};

  bool hasGrammar(String languageId) => _grammars.containsKey(languageId);

  void register(TreeSitterGrammar grammar) {
    _grammars[grammar.languageId] = grammar;
  }

  Highlighter? highlighterFor(String languageId) {
    final grammar = _grammars[languageId];
    if (grammar == null) return null;
    return _highlighters.putIfAbsent(
      languageId,
      () => Highlighter(grammar.language, highlightQuery: grammar.highlightQuery),
    );
  }

  TreeSitterParser? parserFor(String languageId) {
    final grammar = _grammars[languageId];
    if (grammar == null) return null;
    return _parsers.putIfAbsent(languageId, () {
      final parser = TreeSitterParser();
      parser.setLanguage(grammar.language);
      return parser;
    });
  }

  void dispose() {
    for (final h in _highlighters.values) {
      h.delete();
    }
    for (final p in _parsers.values) {
      p.delete();
    }
    _highlighters.clear();
    _parsers.clear();
  }
}

/// Builds a [TextSpan] tree from tree-sitter highlight spans.
TextSpan buildTreeSitterTextSpan({
  required String text,
  required List<HighlightSpan> spans,
  required Map<String, TextStyle> theme,
  TextStyle? rootStyle,
}) {
  return TextSpan(
    style: rootStyle,
    children: spans.map((span) {
      final style = span.type.isEmpty
          ? rootStyle
          : theme[span.type] ?? theme[_fallbackKey(span.type)] ?? rootStyle;
      return TextSpan(text: span.text, style: style);
    }).toList(),
  );
}

String _fallbackKey(String capture) {
  // Map tree-sitter capture names to highlight.js theme keys.
  return switch (capture) {
    'function.method' => 'function',
    'function.builtin' => 'built_in',
    'constant.builtin' => 'literal',
    'punctuation.special' => 'punctuation',
    'property' => 'attr',
    'embedded' => 'string',
    _ => capture.split('.').first,
  };
}

/// Highlights [text] using tree-sitter for [languageId].
List<HighlightSpan>? highlightWithTreeSitter(String languageId, String text) {
  final registry = TreeSitterRegistry.instance;
  final parser = registry.parserFor(languageId);
  final highlighter = registry.highlighterFor(languageId);
  if (parser == null || highlighter == null) return null;

  final tree = parser.parseString(text);
  final root = tree.rootNode;
  final map = highlighter.highlight(root);
  tree.delete();

  final bytes = Uint8List.fromList(text.codeUnits);
  return highlighter.render(bytes, map);
}

/// Offset of the start of [line] (0-based) in [text].
int lineStartOffset(String text, int line) {
  if (line <= 0) return 0;
  var currentLine = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '\n') {
      currentLine++;
      if (currentLine == line) return i + 1;
    }
  }
  return text.length;
}

/// Converts (line, character) to a flat text offset.
int positionToOffset(String text, int line, int character) =>
    lineStartOffset(text, line) + character;

/// Converts a flat offset to (line, character).
(int line, int character) offsetToLineChar(String text, int offset) {
  var line = 0;
  var lineStart = 0;
  final end = offset.clamp(0, text.length);
  for (var i = 0; i < end; i++) {
    if (text[i] == '\n') {
      line++;
      lineStart = i + 1;
    }
  }
  return (line, end - lineStart);
}

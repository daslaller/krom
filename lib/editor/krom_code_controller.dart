import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:parser_client/parser_client.dart';
import 'package:path/path.dart' as p;

import '../utils/text_position.dart';
import 'bracket_colorizer.dart';
import 'highlight_builder.dart';

/// Extended [CodeController] with parser highlighting, bracket pairs, multi-cursor.
class KromCodeController extends CodeController {
  KromCodeController({
    required super.text,
    super.language,
    required this.filePath,
    this.useParser = true,
    List<Color>? bracketPairColors,
    super.params = const EditorParams(tabSpaces: 2),
  })  : _languageId = _resolveLanguageId(filePath),
        _bracketPairColors = bracketPairColors ?? const [];

  final String filePath;
  final bool useParser;
  final String _languageId;
  List<Color> _bracketPairColors;

  List<ParserHighlightSpan>? _highlightSpans;
  bool _parserAvailable = false;
  final List<TextSelection> extraSelections = [];
  Map<int, int>? _bracketColors;

  List<Color> get bracketPairColors => _bracketPairColors;
  List<ParserHighlightSpan>? get highlightSpans => _highlightSpans;

  bool get hasParserGrammar =>
      useParser && _languageId.isNotEmpty && _parserAvailable;

  void configureBracketColors(List<Color> colors) {
    if (_bracketPairColors == colors) return;
    _bracketPairColors = colors;
    notifyListeners();
  }

  void setParserAvailable(bool available) {
    if (_parserAvailable == available) return;
    _parserAvailable = available;
    notifyListeners();
  }

  void setHighlightSpans(List<ParserHighlightSpan> spans) {
    _highlightSpans = spans;
    notifyListeners();
  }

  void addExtraSelection(TextSelection selection) {
    extraSelections.add(selection);
    notifyListeners();
  }

  void clearExtraSelections() {
    if (extraSelections.isEmpty) return;
    extraSelections.clear();
    notifyListeners();
  }

  static String _resolveLanguageId(String path) {
    final ext = p.extension(path);
    return ParserLanguageIds.fromExtension(ext) ??
        LspLanguageIds.fromExtension(ext) ??
        '';
  }

  void revealPosition(int line, {int character = 0}) {
    final offset = positionToOffset(fullText, line, character);
    selection = TextSelection.collapsed(offset: offset.clamp(0, fullText.length));
    notifyListeners();
  }

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue;
    _bracketColors = BracketColorizer.colorize(newValue.text);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool? withComposing,
  }) {
    TextSpan baseSpan;
    if (!hasParserGrammar || _highlightSpans == null) {
      baseSpan = super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    } else {
      final theme = CodeTheme.of(context)?.styles ?? {};
      baseSpan = buildHighlightTextSpan(
        text: text,
        spans: _highlightSpans!,
        theme: theme,
        rootStyle: style,
      );
    }

    _bracketColors ??= BracketColorizer.colorize(text);
    if (_bracketPairColors.isNotEmpty && _bracketColors!.isNotEmpty) {
      baseSpan = BracketColorizer.applyToSpan(
        baseSpan,
        text,
        _bracketColors!,
        _bracketPairColors,
        style,
      );
    }

    baseSpan = _applyExtraSelectionHighlights(baseSpan, style);
    lastTextSpan = baseSpan;
    return baseSpan;
  }

  TextSpan _applyExtraSelectionHighlights(TextSpan span, TextStyle? style) {
    if (extraSelections.isEmpty) return span;

    final highlights = <(int, int)>[];
    for (final sel in extraSelections) {
      if (sel.isValid && !sel.isCollapsed) {
        highlights.add((sel.start, sel.end));
      }
    }
    if (highlights.isEmpty) return span;

    final children = <InlineSpan>[];
    var offset = 0;

    void walk(InlineSpan node) {
      if (node is TextSpan) {
        final nodeText = node.text;
        if (nodeText != null && nodeText.isNotEmpty) {
          var local = 0;
          while (local < nodeText.length) {
            final highlighted = highlights.any(
              (h) => offset + local >= h.$1 && offset + local < h.$2,
            );
            final runStart = local;
            while (local < nodeText.length) {
              final g = offset + local;
              final h = highlights.any((r) => g >= r.$1 && g < r.$2);
              if (h != highlighted) break;
              local++;
            }
            children.add(
              TextSpan(
                text: nodeText.substring(runStart, local),
                style: highlighted
                    ? (node.style ?? style)?.copyWith(
                        backgroundColor: const Color(0x338B93FF),
                      )
                    : node.style ?? style,
              ),
            );
          }
          offset += nodeText.length;
        }
        if (node.children != null) {
          for (final child in node.children!) {
            walk(child);
          }
        }
      }
    }

    walk(span);
    if (children.isEmpty) return span;
    return TextSpan(style: span.style ?? style, children: children);
  }
}

class ParserLanguageIds {
  static String? fromExtension(String ext) =>
      _extToLanguageId[ext.toLowerCase()];

  static const _extToLanguageId = <String, String>{'.py': 'python'};
}

class LspLanguageIds {
  static String? fromExtension(String ext) =>
      _extToLanguageId[ext.toLowerCase()];

  static const _extToLanguageId = <String, String>{
    '.dart': 'dart',
    '.py': 'python',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.jsx': 'javascript',
    '.tsx': 'typescript',
    '.go': 'go',
    '.java': 'java',
    '.kt': 'kotlin',
    '.cs': 'csharp',
    '.cpp': 'cpp',
    '.c': 'c',
    '.h': 'cpp',
    '.rs': 'rust',
    '.rb': 'ruby',
    '.swift': 'swift',
    '.php': 'php',
    '.html': 'html',
    '.css': 'css',
    '.json': 'json',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.sh': 'shellscript',
    '.md': 'markdown',
    '.sql': 'sql',
    '.lua': 'lua',
  };
}

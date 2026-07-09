import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:parser_client/parser_client.dart';
import 'package:path/path.dart' as p;

import '../utils/text_position.dart';
import 'highlight_builder.dart';

/// Extended [CodeController] with krom-parser syntax highlighting and
/// navigation helpers.
class KromCodeController extends CodeController {
  KromCodeController({
    required super.text,
    super.language,
    required this.filePath,
    this.useParser = true,
  }) : _languageId = _resolveLanguageId(filePath);

  final String filePath;
  final bool useParser;
  final String _languageId;

  List<ParserHighlightSpan>? _highlightSpans;
  bool _parserAvailable = false;

  bool get hasParserGrammar =>
      useParser && _languageId.isNotEmpty && _parserAvailable;

  void setParserAvailable(bool available) {
    if (_parserAvailable == available) return;
    _parserAvailable = available;
    notifyListeners();
  }

  void setHighlightSpans(List<ParserHighlightSpan> spans) {
    _highlightSpans = spans;
    notifyListeners();
  }

  static String _resolveLanguageId(String path) {
    final ext = p.extension(path);
    return ParserLanguageIds.fromExtension(ext) ??
        LspLanguageIds.fromExtension(ext) ??
        '';
  }

  /// Moves the cursor to [line] (0-based) and selects [character] on that line.
  void revealPosition(int line, {int character = 0}) {
    final offset = positionToOffset(fullText, line, character);
    selection = TextSelection.collapsed(offset: offset.clamp(0, fullText.length));
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool? withComposing,
  }) {
    if (!hasParserGrammar || _highlightSpans == null) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final theme = CodeTheme.of(context)?.styles ?? {};
    final baseSpan = buildHighlightTextSpan(
      text: text,
      spans: _highlightSpans!,
      theme: theme,
      rootStyle: style,
    );

    lastTextSpan = baseSpan;
    return baseSpan;
  }
}

/// Language IDs supported by krom-parser plugins.
class ParserLanguageIds {
  static String? fromExtension(String ext) =>
      _extToLanguageId[ext.toLowerCase()];

  static const _extToLanguageId = <String, String>{
    '.py': 'python',
  };
}

/// Shared language ID mapping (mirrors LspService extension map).
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

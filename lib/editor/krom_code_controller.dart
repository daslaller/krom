import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_tree_sitter/flutter_tree_sitter.dart';
import 'package:path/path.dart' as p;

import '../syntax/tree_sitter_languages.dart';
import '../syntax/tree_sitter_registry.dart';

/// Extended [CodeController] with tree-sitter syntax highlighting and
/// navigation helpers.
class KromCodeController extends CodeController {
  KromCodeController({
    required super.text,
    super.language,
    required this.filePath,
    this.useTreeSitter = true,
  }) : _languageId = _resolveLanguageId(filePath);

  final String filePath;
  final bool useTreeSitter;
  final String _languageId;

  List<HighlightSpan>? _cachedSpans;
  String _cachedSpanText = '';

  static String _resolveLanguageId(String path) {
    final ext = p.extension(path);
    return treeSitterLanguageIdFromExtension(ext) ??
        LspLanguageIds.fromExtension(ext) ??
        '';
  }

  bool get hasTreeSitterGrammar =>
      useTreeSitter &&
      _languageId.isNotEmpty &&
      TreeSitterRegistry.instance.hasGrammar(_languageId);

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
    if (!hasTreeSitterGrammar) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final text = this.text;
    if (text != _cachedSpanText) {
      _cachedSpans = highlightWithTreeSitter(_languageId, text);
      _cachedSpanText = text;
    }

    final theme = CodeTheme.of(context)?.styles ?? {};
    final baseSpan = buildTreeSitterTextSpan(
      text: text,
      spans: _cachedSpans ?? [HighlightSpan('', text)],
      theme: theme,
      rootStyle: style,
    );

  // Reuse the parent's search-highlight overlay when a search is active.
    lastTextSpan = baseSpan;
    return baseSpan;
  }
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

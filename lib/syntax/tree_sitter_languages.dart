import 'package:flutter_tree_sitter_python/flutter_tree_sitter_python.dart'
    as ts_python;
import 'package:flutter_tree_sitter_python/highlight.dart' as ts_python_hl;

import 'tree_sitter_registry.dart';

/// Registers all bundled tree-sitter grammars.
///
/// Add new language plugins here as FFI grammar packages become available.
void registerBundledTreeSitterGrammars() {
  final registry = TreeSitterRegistry.instance;

  registry.register(
    TreeSitterGrammar(
      languageId: 'python',
      language: ts_python.treeSitterPython,
      highlightQuery: ts_python_hl.pythonHighlightQuery,
    ),
  );
}

/// Maps file extension to tree-sitter language ID.
String? treeSitterLanguageIdFromExtension(String ext) {
  return _extToLanguageId[ext.toLowerCase()];
}

const _extToLanguageId = <String, String>{
  '.py': 'python',
};

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import 'ide_concepts_theme.dart';

/// Builds a [CodeThemeData] from an [IdeConceptsTheme]'s `syntax` palette.
///
/// Krom highlights code two ways depending on parser availability
/// (see [KromCodeController.buildTextSpan]):
///  - krom-parser (tree-sitter) capture names, e.g. `keyword`, `string`,
///    `function`, `property`, `punctuation`.
///  - highlight.js class names, e.g. `keyword`, `string`, `title`,
///    `attr`, `tag`.
/// Both paths are mapped onto the same five-bucket palette
/// (keyword / string / comment / function / number / tag / property /
/// plain / punc) the mockup defines, so every token style resolves to one
/// of those buckets regardless of which highlighter produced it.
CodeThemeData buildIdeConceptsCodeTheme(IdeConceptsTheme theme) {
  final plain = theme.syntax['plain'] ?? theme.text;
  final italic = theme.syntaxItalic.contains('comment');

  TextStyle style(String kind, {bool? forceItalic}) => TextStyle(
    color: theme.syntax[kind] ?? plain,
    fontStyle: (forceItalic ?? theme.syntaxItalic.contains(kind))
        ? FontStyle.italic
        : FontStyle.normal,
  );

  return CodeThemeData(
    styles: {
      'root': TextStyle(backgroundColor: theme.editorBg, color: plain),

      // Shared bucket keys (also used directly as tree-sitter captures).
      'keyword': style('keyword'),
      'string': style('string'),
      'comment': style('comment', forceItalic: italic),
      'function': style('function'),
      'number': style('number'),
      'tag': style('tag'),
      'property': style('property'),
      'plain': style('plain'),
      'punc': style('punc'),
      'punctuation': style('punc'),

      // Tree-sitter capture names that map onto the same buckets.
      'variable': style('plain'),
      'type': style('tag'),
      'constant': style('number'),
      'operator': style('punc'),
      'literal': style('number'),
      'built_in': style('function'),
      'embedded': style('string'),

      // highlight.js class names used by the highlight.js fallback path.
      'title': style('function'),
      'params': style('plain'),
      'class': style('tag'),
      'attr': style('property'),
      'attribute': style('string'),
      'name': style('tag'),
      'symbol': style('function'),
      'meta': style('function'),
      'meta-keyword': style('keyword'),
      'meta-string': style('string'),
      'section': style('function'),
      'doctag': style('string'),
      'bullet': style('function'),
      'code': style('string'),
      'formula': style('tag'),
      'link': style('function'),
      'quote': style('comment', forceItalic: italic),
      'selector-tag': style('tag'),
      'selector-id': style('function'),
      'selector-class': style('tag'),
      'selector-attr': style('keyword'),
      'selector-pseudo': style('string'),
      'template-tag': style('tag'),
      'template-variable': style('tag'),
      'subst': style('number'),
      'addition': style('string'),
      'deletion': style('number'),
      'emphasis': const TextStyle(fontStyle: FontStyle.italic),
      'strong': const TextStyle(fontWeight: FontWeight.bold),
    },
  );
}

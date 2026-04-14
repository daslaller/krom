import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'krom_colors.dart';

// Dark syntax theme based on a refined one-dark palette.
// Keys match highlight.js CSS class names.
final kromEditorTheme = CodeThemeData(
  styles: {
    'root': TextStyle(
      backgroundColor: KromColors.background,
      color: KromColors.text,
    ),
    'keyword': const TextStyle(color: Color(0xFFC678DD)),
    'built_in': const TextStyle(color: Color(0xFF61AFEF)),
    'type': const TextStyle(color: Color(0xFFE5C07B)),
    'literal': const TextStyle(color: Color(0xFFD19A66)),
    'number': const TextStyle(color: Color(0xFFD19A66)),
    'string': const TextStyle(color: Color(0xFF98C379)),
    'subst': const TextStyle(color: Color(0xFFE06C75)),
    'symbol': const TextStyle(color: Color(0xFF61AFEF)),
    'class': const TextStyle(color: Color(0xFFE5C07B)),
    'function': const TextStyle(color: Color(0xFF61AFEF)),
    'title': const TextStyle(color: Color(0xFF61AFEF)),
    'params': const TextStyle(color: KromColors.text),
    'comment': TextStyle(
      color: KromColors.textSecondary,
      fontStyle: FontStyle.italic,
    ),
    'doctag': const TextStyle(color: Color(0xFF98C379)),
    'meta': const TextStyle(color: Color(0xFF61AFEF)),
    'meta-keyword': const TextStyle(color: Color(0xFFC678DD)),
    'meta-string': const TextStyle(color: Color(0xFF98C379)),
    'section': const TextStyle(color: Color(0xFF61AFEF)),
    'tag': const TextStyle(color: Color(0xFFE06C75)),
    'name': const TextStyle(color: Color(0xFFE06C75)),
    'attr': const TextStyle(color: Color(0xFFD19A66)),
    'attribute': const TextStyle(color: Color(0xFF98C379)),
    'variable': const TextStyle(color: Color(0xFFE06C75)),
    'bullet': const TextStyle(color: Color(0xFF61AFEF)),
    'code': const TextStyle(color: Color(0xFF98C379)),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'strong': const TextStyle(fontWeight: FontWeight.bold),
    'formula': const TextStyle(color: Color(0xFFE5C07B)),
    'link': const TextStyle(color: Color(0xFF61AFEF)),
    'quote': TextStyle(
      color: KromColors.textSecondary,
      fontStyle: FontStyle.italic,
    ),
    'selector-tag': const TextStyle(color: Color(0xFFE06C75)),
    'selector-id': const TextStyle(color: Color(0xFF61AFEF)),
    'selector-class': const TextStyle(color: Color(0xFFE5C07B)),
    'selector-attr': const TextStyle(color: Color(0xFFC678DD)),
    'selector-pseudo': const TextStyle(color: Color(0xFF98C379)),
    'template-tag': const TextStyle(color: Color(0xFFE06C75)),
    'template-variable': const TextStyle(color: Color(0xFFE06C75)),
    'addition': const TextStyle(color: Color(0xFF98C379)),
    'deletion': const TextStyle(color: Color(0xFFE06C75)),
  },
);

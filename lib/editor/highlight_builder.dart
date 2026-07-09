import 'package:flutter/material.dart';
import 'package:parser_client/parser_client.dart';

/// Builds a [TextSpan] tree from krom-parser highlight byte spans.
TextSpan buildHighlightTextSpan({
  required String text,
  required List<ParserHighlightSpan> spans,
  required Map<String, TextStyle> theme,
  TextStyle? rootStyle,
}) {
  if (spans.isEmpty) {
    return TextSpan(text: text, style: rootStyle);
  }

  final children = <InlineSpan>[];
  var cursor = 0;

  for (final span in spans) {
    final start = span.startByte.clamp(0, text.length);
    final end = span.endByte.clamp(start, text.length);
    if (start > cursor) {
      children.add(TextSpan(text: text.substring(cursor, start), style: rootStyle));
    }
    if (end > start) {
      final style = theme[span.capture] ??
          theme[_fallbackKey(span.capture)] ??
          rootStyle;
      children.add(TextSpan(text: text.substring(start, end), style: style));
    }
    cursor = end;
  }

  if (cursor < text.length) {
    children.add(TextSpan(text: text.substring(cursor), style: rootStyle));
  }

  return TextSpan(style: rootStyle, children: children);
}

String _fallbackKey(String capture) {
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

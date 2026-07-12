import 'package:flutter/material.dart';

/// Finds matching bracket pairs and assigns a color index to each character.
class BracketColorizer {
  const BracketColorizer._();

  static const opens = '({[';
  static const closes = ')}]';

  /// Maps byte offset → color index for bracket characters.
  static Map<int, int> colorize(String text) {
    final result = <int, int>{};
    final stack = <_Entry>[];
    var colorCounter = 0;

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      final openIdx = opens.indexOf(c);
      if (openIdx >= 0) {
        stack.add(_Entry(offset: i, pairIndex: openIdx, colorIndex: colorCounter % 8));
        colorCounter++;
        continue;
      }
      final closeIdx = closes.indexOf(c);
      if (closeIdx >= 0) {
        for (var j = stack.length - 1; j >= 0; j--) {
          if (stack[j].pairIndex == closeIdx) {
            final entry = stack.removeAt(j);
            result[entry.offset] = entry.colorIndex;
            result[i] = entry.colorIndex;
            break;
          }
        }
      }
    }
    return result;
  }

  /// Applies bracket colors to an existing [TextSpan] tree.
  static TextSpan applyToSpan(
    TextSpan span,
    String text,
    Map<int, int> bracketColors,
    List<Color> colors,
    TextStyle? baseStyle,
  ) {
    if (bracketColors.isEmpty) return span;

    final children = <InlineSpan>[];
    var offset = 0;

    void walk(InlineSpan node) {
      if (node is TextSpan) {
        final nodeText = node.text;
        if (nodeText != null && nodeText.isNotEmpty) {
          var local = 0;
          while (local < nodeText.length) {
            final globalOffset = offset + local;
            final colorIdx = bracketColors[globalOffset];
            if (colorIdx != null) {
              final runStart = local;
              while (local < nodeText.length &&
                  bracketColors[offset + local] == colorIdx) {
                local++;
              }
              children.add(
                TextSpan(
                  text: nodeText.substring(runStart, local),
                  style: (node.style ?? baseStyle)?.copyWith(
                    color: colors[colorIdx % colors.length],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            } else {
              final runStart = local;
              while (local < nodeText.length &&
                  bracketColors[offset + local] == null) {
                local++;
              }
              children.add(
                TextSpan(
                  text: nodeText.substring(runStart, local),
                  style: node.style ?? baseStyle,
                ),
              );
            }
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
    return TextSpan(style: span.style ?? baseStyle, children: children);
  }
}

class _Entry {
  const _Entry({
    required this.offset,
    required this.pairIndex,
    required this.colorIndex,
  });

  final int offset;
  final int pairIndex;
  final int colorIndex;
}

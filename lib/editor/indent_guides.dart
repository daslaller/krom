import 'package:flutter/material.dart';

/// A single brace-color-coded indent guide dot on one line.
class IndentGuideDot {
  const IndentGuideDot({
    required this.line,
    required this.column,
    required this.colorIndex,
  });

  final int line;
  final int column;
  final int colorIndex;
}

/// Analyzes source text and produces per-line indent guide dots colored by
/// enclosing `()`, `[]`, or `{}` blocks.
class IndentGuideAnalyzer {
  const IndentGuideAnalyzer._();

  static const tabSize = 2;

  static List<List<IndentGuideDot>> analyze(String text) {
    final lines = text.split('\n');
    final stack = <_BraceFrame>[];
    var colorCounter = 0;
    final result = List.generate(lines.length, (_) => <IndentGuideDot>[]);

    for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];
      final indent = _leadingIndent(line);
      final indentLevel = indent ~/ tabSize;

      for (var level = 1; level <= indentLevel; level++) {
        final col = level * tabSize - 1;
        final colorIdx = _colorAtIndentLevel(stack, level);
        result[lineIdx].add(
          IndentGuideDot(line: lineIdx, column: col, colorIndex: colorIdx),
        );
      }

      for (var i = indent; i < line.length; i++) {
        final c = line[i];
        if (c == '(' || c == '[' || c == '{') {
          stack.add(
            _BraceFrame(
              char: c,
              colorIndex: colorCounter % 8,
              indentLevel: indent ~/ tabSize,
            ),
          );
          colorCounter++;
        } else if (c == ')' || c == ']' || c == '}') {
          _popMatching(stack, c);
        }
      }
    }
    return result;
  }

  static int _leadingIndent(String line) {
    var i = 0;
    while (i < line.length && line[i] == ' ') {
      i++;
    }
    return i;
  }

  static int _colorAtIndentLevel(List<_BraceFrame> stack, int level) {
    for (var i = stack.length - 1; i >= 0; i--) {
      if (stack[i].indentLevel < level) {
        return stack[i].colorIndex;
      }
    }
    return level % 8;
  }

  static void _popMatching(List<_BraceFrame> stack, String close) {
    const pairs = {'(': ')', '[': ']', '{': '}'};
    for (var i = stack.length - 1; i >= 0; i--) {
      if (pairs[stack[i].char] == close) {
        stack.removeAt(i);
        return;
      }
    }
  }
}

class _BraceFrame {
  const _BraceFrame({
    required this.char,
    required this.colorIndex,
    required this.indentLevel,
  });

  final String char;
  final int colorIndex;
  final int indentLevel;
}

/// Paints brace-color-coded indent guide dots synced with editor scroll.
class IndentGuidePainter extends CustomPainter {
  IndentGuidePainter({
    required this.dots,
    required this.colors,
    required this.scrollOffset,
    required this.lineHeight,
    required this.charWidth,
    required this.topPadding,
    required this.leftPadding,
  });

  final List<List<IndentGuideDot>> dots;
  final List<Color> colors;
  final double scrollOffset;
  final double lineHeight;
  final double charWidth;
  final double topPadding;
  final double leftPadding;

  static const _dotRadius = 1.75;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final visibleTop = scrollOffset;
    final visibleBottom = scrollOffset + size.height;

    for (var lineIdx = 0; lineIdx < dots.length; lineIdx++) {
      final y = topPadding + lineIdx * lineHeight + lineHeight / 2;
      if (y < visibleTop - lineHeight || y > visibleBottom + lineHeight) {
        continue;
      }
      final screenY = y - scrollOffset;
      for (final dot in dots[lineIdx]) {
        paint.color = colors[dot.colorIndex % colors.length]
            .withValues(alpha: 0.55);
        final x = leftPadding + dot.column * charWidth + charWidth / 2;
        canvas.drawCircle(Offset(x, screenY), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IndentGuidePainter old) {
    return old.dots != dots ||
        old.scrollOffset != scrollOffset ||
        old.colors != colors ||
        old.lineHeight != lineHeight;
  }
}

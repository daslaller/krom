import 'package:flutter/material.dart';
import 'package:parser_client/parser_client.dart';

import '../ide_concepts_theme.dart';

/// Right-edge syntax-colored minimap strip; click to scroll.
class EditorMinimap extends StatelessWidget {
  const EditorMinimap({
    super.key,
    required this.theme,
    required this.text,
    required this.highlightSpans,
    required this.scrollFraction,
    required this.viewportFraction,
    required this.onTapFraction,
    this.width = 72,
  });

  final IdeConceptsTheme theme;
  final String text;
  final List<ParserHighlightSpan>? highlightSpans;
  final double scrollFraction;
  final double viewportFraction;
  final void Function(double fraction) onTapFraction;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final fraction = (details.localPosition.dy / context.size!.height)
            .clamp(0.0, 1.0);
        onTapFraction(fraction);
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: theme.editorBg.withValues(alpha: 0.85),
          border: Border(left: BorderSide(color: theme.hairline)),
        ),
        child: CustomPaint(
          painter: _MinimapPainter(
            text: text,
            highlightSpans: highlightSpans,
            syntax: theme.syntax,
            scrollFraction: scrollFraction,
            viewportFraction: viewportFraction,
            viewportColor: theme.accent.withValues(alpha: 0.15),
            defaultColor: theme.syntax['plain'] ?? theme.text,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.text,
    required this.highlightSpans,
    required this.syntax,
    required this.scrollFraction,
    required this.viewportFraction,
    required this.viewportColor,
    required this.defaultColor,
  });

  final String text;
  final List<ParserHighlightSpan>? highlightSpans;
  final Map<String, Color> syntax;
  final double scrollFraction;
  final double viewportFraction;
  final Color viewportColor;
  final Color defaultColor;

  @override
  void paint(Canvas canvas, Size size) {
    final lines = text.split('\n');
    if (lines.isEmpty) return;

    final lineH = size.height / lines.length.clamp(1, 1 << 20);
    final paint = Paint();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final y = i * lineH;
      Color color = defaultColor.withValues(alpha: 0.35);

      if (highlightSpans != null) {
        final lineStart = _lineStartOffset(lines, i);
        for (final span in highlightSpans!) {
          if (span.endByte <= lineStart) continue;
          if (span.startByte >= lineStart + line.length) break;
          color = (syntax[span.capture] ?? defaultColor).withValues(alpha: 0.5);
          break;
        }
      }

      paint.color = color;
      final barWidth = (line.length.clamp(1, 80) / 80) * (size.width - 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, y + 0.5, barWidth, lineH.clamp(0.5, 2)),
          const Radius.circular(0.5),
        ),
        paint,
      );
    }

    final vpTop = scrollFraction * size.height;
    final vpHeight = (viewportFraction * size.height).clamp(8.0, size.height);
    paint.color = viewportColor;
    canvas.drawRect(Rect.fromLTWH(0, vpTop, size.width, vpHeight), paint);
    paint
      ..color = viewportColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, vpTop, size.width, vpHeight), paint);
  }

  int _lineStartOffset(List<String> lines, int lineIndex) {
    var offset = 0;
    for (var i = 0; i < lineIndex; i++) {
      offset += lines[i].length + 1;
    }
    return offset;
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter old) {
    return old.text != text ||
        old.scrollFraction != scrollFraction ||
        old.highlightSpans != highlightSpans;
  }
}

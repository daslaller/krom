import 'package:flutter/material.dart';

import '../../../services/git_service.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

class GitDiffGutter extends StatelessWidget {
  const GitDiffGutter({
    super.key,
    required this.theme,
    required this.lineCount,
    required this.markers,
    required this.lineHeight,
    required this.topPadding,
  });

  final IdeConceptsTheme theme;
  final int lineCount;
  final FileDiffMarkers markers;
  final double lineHeight;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      color: theme.editorBg,
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: List.generate(lineCount, (i) {
          final added = markers.addedLines.contains(i);
          final removed = markers.removedLines.contains(i);
          String? symbol;
          Color? color;
          if (added) {
            symbol = '+';
            color = const Color(0xFF3FB950);
          } else if (removed) {
            symbol = '−';
            color = const Color(0xFFF85149);
          }
          return SizedBox(
            height: lineHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: symbol == null
                  ? const SizedBox.shrink()
                  : Text(symbol, style: IdeFonts.mono(color: color, fontSize: 12, weight: FontWeight.w700)),
            ),
          );
        }),
      ),
    );
  }
}

class GitBlameGutter extends StatelessWidget {
  const GitBlameGutter({
    super.key,
    required this.theme,
    required this.lineCount,
    required this.blame,
    required this.lineHeight,
    required this.topPadding,
    this.onLineHover,
  });

  final IdeConceptsTheme theme;
  final int lineCount;
  final Map<int, BlameLine> blame;
  final double lineHeight;
  final double topPadding;
  final void Function(int line, BlameLine? info)? onLineHover;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      color: theme.editorBg,
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: List.generate(lineCount, (i) {
          final info = blame[i];
          return MouseRegion(
            onEnter: (_) => onLineHover?.call(i, info),
            onExit: (_) => onLineHover?.call(i, null),
            child: SizedBox(
              height: lineHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: info == null
                    ? const SizedBox.shrink()
                    : Text(
                        info.summary,
                        overflow: TextOverflow.ellipsis,
                        style: IdeFonts.mono(color: theme.lineNum.withValues(alpha: 0.85), fontSize: 10),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

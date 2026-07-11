import 'package:flutter/material.dart';

import '../../../services/ghost_completion_service.dart';
import '../ide_fonts.dart';
import '../ide_concepts_theme.dart';

class GhostCompletionOverlay extends StatelessWidget {
  const GhostCompletionOverlay({
    super.key,
    required this.theme,
    required this.suggestion,
    required this.line,
    required this.column,
    required this.lineHeight,
    required this.charWidth,
    required this.gutterWidth,
    required this.horizontalPad,
    required this.verticalPad,
  });

  final IdeConceptsTheme theme;
  final String? suggestion;
  final int line;
  final int column;
  final double lineHeight;
  final double charWidth;
  final double gutterWidth;
  final double horizontalPad;
  final double verticalPad;

  @override
  Widget build(BuildContext context) {
    final text = suggestion;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: gutterWidth + horizontalPad + column * charWidth,
      top: verticalPad + line * lineHeight,
      child: IgnorePointer(
        child: Text(
          text,
          style: IdeFonts.mono(
            fontSize: 13.5,
            height: lineHeight / 13.5,
            color: theme.muted.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

void acceptGhostSuggestion({
  required dynamic controller,
  required GhostCompletionService service,
  required String fileText,
  required int cursorOffset,
}) {
  final suffix = service.suggestion;
  if (suffix == null || suffix.isEmpty) return;

  controller.text = fileText.substring(0, cursorOffset) +
      suffix +
      fileText.substring(cursorOffset);
  controller.selection =
      TextSelection.collapsed(offset: cursorOffset + suffix.length);
  service.clear();
}

import 'package:flutter/material.dart';

import '../../../editor/tab_model.dart';
import '../../../utils/text_position.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../language_labels.dart';

class IdeConceptsStatusBar extends StatelessWidget {
  const IdeConceptsStatusBar({
    super.key,
    required this.theme,
    required this.activeTab,
    this.focusOn = false,
    this.autosaveOn = true,
    this.blameHint,
    this.onExitFocus,
  });

  final IdeConceptsTheme theme;
  final TabModel? activeTab;
  final bool focusOn;
  final bool autosaveOn;
  final String? blameHint;
  final VoidCallback? onExitFocus;

  @override
  Widget build(BuildContext context) {
    final tab = activeTab;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.statusBg,
        border: Border(top: BorderSide(color: theme.hairline)),
      ),
      child: Row(
        children: [
          _dot(theme.statusAccent),
          const SizedBox(width: 7),
          Text(
            'main',
            style: IdeFonts.mono(fontSize: 11, color: theme.statusText),
          ),
          if (tab != null) ...[
            _separator(theme),
            Text(
              languageLabelForPath(tab.filePath),
              style: IdeFonts.mono(fontSize: 11, color: theme.statusText),
            ),
          ],
          if (blameHint != null && blameHint!.isNotEmpty) ...[ _separator(theme), Flexible(child: Text(blameHint!, overflow: TextOverflow.ellipsis, style: IdeFonts.mono(fontSize: 10.5, color: theme.statusText))), ],
          const Spacer(),
          if (focusOn && onExitFocus != null)
            GestureDetector(
              onTap: onExitFocus,
              child: Text(
                'esc to exit focus',
                style: IdeFonts.mono(fontSize: 11, color: theme.accent),
              ),
            ),
          if (autosaveOn) ...[
            const SizedBox(width: 12),
            Text(
              'autosave',
              style: IdeFonts.mono(fontSize: 10.5, color: theme.statusText),
            ),
          ],
          if (tab != null) ...[
            _separator(theme),
            ListenableBuilder(
              listenable: tab.codeController,
              builder: (context, _) {
                final offset = tab.codeController.selection.baseOffset;
                final text = tab.codeController.fullText;
                final safeOffset = offset.clamp(0, text.length);
                final (line, character) = offsetToLineChar(text, safeOffset);
                return Text(
                  'Ln ${line + 1}, Col ${character + 1}',
                  style: IdeFonts.mono(fontSize: 11, color: theme.statusText),
                );
              },
            ),
          ],
          _separator(theme),
          Text(
            'UTF-8',
            style: IdeFonts.mono(fontSize: 11, color: theme.statusText),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _separator(IdeConceptsTheme theme) => Container(
        width: 1,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: theme.hairlineStrong,
      );
}

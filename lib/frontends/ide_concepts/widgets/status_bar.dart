import 'package:flutter/material.dart';

import '../../../editor/tab_model.dart';
import '../../../utils/text_position.dart';
import '../ide_concepts_theme.dart';
import '../language_labels.dart';

class IdeConceptsStatusBar extends StatelessWidget {
  const IdeConceptsStatusBar({
    super.key,
    required this.theme,
    required this.activeTab,
  });

  final IdeConceptsTheme theme;
  final TabModel? activeTab;

  @override
  Widget build(BuildContext context) {
    final tab = activeTab;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: theme.statusBg,
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.accent2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'main',
                style: TextStyle(fontSize: 11, color: theme.statusText),
              ),
            ],
          ),
          if (tab != null) ...[
            const SizedBox(width: 16),
            Text(
              languageLabelForPath(tab.filePath),
              style: TextStyle(fontSize: 11, color: theme.statusText),
            ),
          ],
          const Spacer(),
          if (tab != null)
            ListenableBuilder(
              listenable: tab.codeController,
              builder: (context, _) {
                final offset = tab.codeController.selection.baseOffset;
                final text = tab.codeController.fullText;
                final safeOffset = offset.clamp(0, text.length);
                final (line, character) = offsetToLineChar(text, safeOffset);
                return Text(
                  'Ln ${line + 1}, Col ${character + 1}',
                  style: TextStyle(fontSize: 11, color: theme.statusText),
                );
              },
            ),
          const SizedBox(width: 16),
          Text(
            'UTF-8',
            style: TextStyle(fontSize: 11, color: theme.statusText),
          ),
        ],
      ),
    );
  }
}

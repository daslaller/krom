import 'package:flutter/material.dart';
import 'package:lsp_client/lsp_client.dart';

import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

/// Lightbulb quick-fix menu from LSP `textDocument/codeAction`.
class IdeConceptsCodeActionsMenu extends StatelessWidget {
  const IdeConceptsCodeActionsMenu({
    super.key,
    required this.theme,
    required this.actions,
    required this.onSelect,
    required this.onDismiss,
    this.offset = Offset.zero,
  });

  final IdeConceptsTheme theme;
  final List<LspCodeAction> actions;
  final void Function(LspCodeAction action) onSelect;
  final VoidCallback onDismiss;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Material(
            elevation: 8,
            color: theme.panelBg,
            borderRadius: BorderRadius.circular(6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 280),
              child: actions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No code actions available',
                        style: IdeFonts.mono(color: theme.muted, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: actions.length,
                      itemBuilder: (context, i) {
                        final action = actions[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: theme.syntax['number'] ?? theme.accent2,
                          ),
                          title: Text(
                            action.title,
                            style: IdeFonts.mono(color: theme.text, fontSize: 12.5),
                          ),
                          onTap: () => onSelect(action),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

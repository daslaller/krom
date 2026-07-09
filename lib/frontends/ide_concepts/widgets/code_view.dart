import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../../../editor/hover_tooltip.dart';
import '../../../editor/tab_model.dart';
import '../../../services/lsp_service.dart';
import '../ide_concepts_code_theme.dart';
import '../ide_concepts_theme.dart';

/// Code editing surface for the IDE Concepts frontend. Reuses the same
/// [TabModel.codeController] (and therefore all real editing, LSP and
/// tree-sitter highlighting behavior) as the default frontend — only the
/// gutter/text styling is swapped to match the mockup's palette.
class IdeConceptsCodeView extends StatelessWidget {
  const IdeConceptsCodeView({
    super.key,
    required this.theme,
    required this.tab,
    this.onChanged,
    this.lspService,
  });

  final IdeConceptsTheme theme;
  final TabModel tab;
  final VoidCallback? onChanged;
  final LspService? lspService;

  @override
  Widget build(BuildContext context) {
    final field = CodeTheme(
      data: buildIdeConceptsCodeTheme(theme),
      child: CodeField(
        controller: tab.codeController,
        textStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontFamilyFallback: const ['Cascadia Code', 'Consolas', 'monospace'],
          fontSize: 13.5,
          height: 24 / 13.5,
          color: theme.syntax['plain'] ?? theme.text,
        ),
        gutterStyle: GutterStyle(
          showLineNumbers: true,
          showFoldingHandles: true,
          showErrors: true,
          width: 46,
          margin: 14,
          textStyle: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontFamilyFallback: const [
              'Cascadia Code',
              'Consolas',
              'monospace',
            ],
            fontSize: 13.5,
            color: theme.lineNum,
          ),
          background: theme.editorBg,
        ),
        background: theme.editorBg,
        padding: const EdgeInsets.symmetric(vertical: 18),
        onChanged: onChanged != null ? (_) => onChanged!() : null,
      ),
    );

    if (lspService != null && lspService!.isAvailable) {
      return HoverTooltip(
        lspService: lspService!,
        controller: tab.codeController,
        filePath: tab.filePath,
        child: field,
      );
    }

    return field;
  }
}

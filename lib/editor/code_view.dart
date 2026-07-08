import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../services/lsp_service.dart';
import '../theme/editor_theme.dart';
import '../theme/krom_colors.dart';
import '../theme/typography.dart';
import 'hover_tooltip.dart';
import 'krom_code_controller.dart';
import 'tab_model.dart';

class CodeView extends StatelessWidget {
  const CodeView({
    super.key,
    required this.tab,
    this.onChanged,
    this.lspService,
  });

  final TabModel tab;
  final VoidCallback? onChanged;
  final LspService? lspService;

  @override
  Widget build(BuildContext context) {
    final field = CodeTheme(
      data: kromEditorTheme,
      child: CodeField(
        controller: tab.codeController,
        textStyle: KromTypography.code(),
        gutterStyle: GutterStyle(
          showLineNumbers: true,
          showFoldingHandles: true,
          showErrors: true,
          width: 64,
          textStyle: KromTypography.code(color: KromColors.textDisabled),
          background: KromColors.gutter,
        ),
        background: KromColors.background,
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

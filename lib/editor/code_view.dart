import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/krom_colors.dart';
import '../theme/typography.dart';
import 'tab_model.dart';

class CodeView extends StatelessWidget {
  const CodeView({super.key, required this.tab, this.onChanged});

  final TabModel tab;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: kromEditorTheme,
      child: CodeField(
        controller: tab.codeController,
        textStyle: KromTypography.code(),
        gutterStyle: GutterStyle(
          showLineNumbers: true,
          showFoldingHandles: false,
          showErrors: true,
          width: 64,
          textStyle: KromTypography.code(color: KromColors.textDisabled),
          background: KromColors.gutter,
        ),
        background: KromColors.background,
        onChanged: onChanged != null ? (_) => onChanged!() : null,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../../../editor/hover_tooltip.dart';
import '../../../editor/tab_model.dart';
import '../../../services/ghost_completion_service.dart';
import '../../../services/lsp_service.dart';
import '../../../utils/text_position.dart';
import '../ide_concepts_code_theme.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import 'code_lens_overlay.dart';
import 'ghost_completion_overlay.dart';

class IdeConceptsCodeView extends StatefulWidget {
  const IdeConceptsCodeView({
    super.key,
    required this.theme,
    required this.tab,
    this.focusOn = false,
    this.onChanged,
    this.lspService,
    this.ghostService,
    this.onReferencesTap,
  });

  final IdeConceptsTheme theme;
  final TabModel tab;
  final bool focusOn;
  final VoidCallback? onChanged;
  final LspService? lspService;
  final GhostCompletionService? ghostService;
  final void Function(int line, int character)? onReferencesTap;

  @override
  State<IdeConceptsCodeView> createState() => _IdeConceptsCodeViewState();
}

class _IdeConceptsCodeViewState extends State<IdeConceptsCodeView> {
  static const _lineHeight = 24.0;
  static const _fontSize = 13.5;
  static const _gutterWidth = 60.0;
  static const _horizontalPad = 12.0;
  static const _verticalPad = 18.0;

  @override
  void initState() {
    super.initState();
    widget.tab.codeController.addListener(_rebuild);
    widget.ghostService?.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant IdeConceptsCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      oldWidget.tab.codeController.removeListener(_rebuild);
      widget.tab.codeController.addListener(_rebuild);
    }
    if (oldWidget.ghostService != widget.ghostService) {
      oldWidget.ghostService?.removeListener(_rebuild);
      widget.ghostService?.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.tab.codeController.removeListener(_rebuild);
    widget.ghostService?.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  double get _charWidth {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: IdeFonts.mono(fontSize: _fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  void _handleChanged(String text) {
    widget.onChanged?.call();
    widget.ghostService?.schedule(
      fileText: text,
      cursorOffset:
          widget.tab.codeController.selection.baseOffset.clamp(0, text.length),
      filePath: widget.tab.filePath,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    final ghost = widget.ghostService;
    if (ghost?.suggestion == null) return KeyEventResult.ignored;
    final text = widget.tab.codeController.fullText;
    final offset =
        widget.tab.codeController.selection.baseOffset.clamp(0, text.length);
    acceptGhostSuggestion(
      controller: widget.tab.codeController,
      service: ghost!,
      fileText: text,
      cursorOffset: offset,
    );
    widget.onChanged?.call();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tab = widget.tab;
    final verticalPad = widget.focusOn ? 56.0 : _verticalPad;
    final text = tab.codeController.fullText;
    final offset = tab.codeController.selection.baseOffset.clamp(0, text.length);
    final (line, column) = offsetToLineChar(text, offset);

    final field = CodeTheme(
      data: buildIdeConceptsCodeTheme(theme),
      child: CodeField(
        controller: tab.codeController,
        textStyle: IdeFonts.mono(
          fontSize: _fontSize,
          height: _lineHeight / _fontSize,
          color: theme.syntax['plain'] ?? theme.text,
        ),
        gutterStyle: GutterStyle(
          showLineNumbers: true,
          showFoldingHandles: true,
          showErrors: true,
          width: 46,
          margin: 14,
          textStyle: IdeFonts.mono(fontSize: _fontSize, color: theme.lineNum),
          background: theme.editorBg,
        ),
        background: theme.editorBg,
        padding: EdgeInsets.symmetric(vertical: verticalPad),
        onChanged: widget.onChanged != null ? _handleChanged : null,
      ),
    );

    final editor = widget.lspService != null && widget.lspService!.isAvailable
        ? HoverTooltip(
            lspService: widget.lspService!,
            controller: tab.codeController,
            filePath: tab.filePath,
            child: field,
          )
        : field;

    return ColoredBox(
      color: theme.editorBg,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.focusOn ? 860 : double.infinity,
          ),
          child: Focus(
            onKeyEvent: _onKey,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                editor,
                GhostCompletionOverlay(
                  theme: theme,
                  suggestion: widget.ghostService?.suggestion,
                  line: line,
                  column: column,
                  lineHeight: _lineHeight,
                  charWidth: _charWidth,
                  gutterWidth: _gutterWidth,
                  horizontalPad: _horizontalPad,
                  verticalPad: verticalPad,
                ),
                CodeLensOverlay(
                  theme: theme,
                  lspService: widget.lspService,
                  filePath: tab.filePath,
                  fileText: text,
                  cursorOffset: offset,
                  lineHeight: _lineHeight,
                  gutterWidth: _gutterWidth,
                  horizontalPad: _horizontalPad,
                  verticalPad: verticalPad,
                  onReferencesTap: widget.onReferencesTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

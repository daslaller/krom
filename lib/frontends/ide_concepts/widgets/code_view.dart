import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:lsp_client/lsp_client.dart';

import '../../../editor/hover_tooltip.dart';
import '../../../editor/indent_guides.dart';
import '../../../editor/tab_model.dart';
import '../../../services/lsp_service.dart';
import '../ide_concepts_code_theme.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import 'editor_minimap.dart';
import 'signature_help_popup.dart';

/// Code editing surface with indent guides, minimap, and signature help.
class IdeConceptsCodeView extends StatefulWidget {
  const IdeConceptsCodeView({
    super.key,
    required this.theme,
    required this.tab,
    this.focusOn = false,
    this.onChanged,
    this.lspService,
    this.onSignatureHelp,
  });

  final IdeConceptsTheme theme;
  final TabModel tab;
  final bool focusOn;
  final VoidCallback? onChanged;
  final LspService? lspService;
  final Future<LspSignatureHelp?> Function()? onSignatureHelp;

  @override
  State<IdeConceptsCodeView> createState() => _IdeConceptsCodeViewState();
}

class _IdeConceptsCodeViewState extends State<IdeConceptsCodeView> {
  static const _lineHeight = 24.0;
  static const _fontSize = 13.5;
  static const _gutterWidth = 60.0;
  static const _horizontalPad = 12.0;

  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _viewportExtent = 1;
  double _maxScrollExtent = 1;
  LspSignatureHelp? _signatureHelp;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.tab.codeController.configureBracketColors(
      widget.theme.bracketPairColors,
    );
  }

  @override
  void didUpdateWidget(covariant IdeConceptsCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      widget.tab.codeController.configureBracketColors(
        widget.theme.bracketPairColors,
      );
    }
    if (oldWidget.tab.filePath != widget.tab.filePath) {
      _signatureHelp = null;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = _scrollController.offset;
      _viewportExtent = _scrollController.position.viewportDimension;
      _maxScrollExtent = _scrollController.position.maxScrollExtent;
    });
  }

  double get _charWidth {
    final painter = TextPainter(
      text: TextSpan(
        text: ' ',
        style: IdeFonts.mono(fontSize: _fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  Future<void> _handleChanged(String text) async {
    widget.onChanged?.call();
    final helpFn = widget.onSignatureHelp;
    if (helpFn == null) return;
    final offset = widget.tab.codeController.selection.baseOffset;
    if (offset > 0 && text[offset - 1] == '(') {
      final help = await helpFn();
      if (mounted) setState(() => _signatureHelp = help);
    } else if (_signatureHelp != null) {
      setState(() => _signatureHelp = null);
    }
  }

  void _scrollToFraction(double fraction) {
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo((fraction * max).clamp(0, max));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tab = widget.tab;
    final verticalPad = widget.focusOn ? 56.0 : 18.0;
    final indentDots = IndentGuideAnalyzer.analyze(tab.codeController.fullText);

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

    final scrollFraction = _maxScrollExtent <= 0
        ? 0.0
        : (_scrollOffset / _maxScrollExtent).clamp(0.0, 1.0);
    final viewportFraction = _maxScrollExtent <= 0
        ? 1.0
        : (_viewportExtent / (_viewportExtent + _maxScrollExtent))
            .clamp(0.05, 1.0);

    return ColoredBox(
      color: theme.editorBg,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.focusOn ? 860 : double.infinity,
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification ||
                            notification is ScrollMetricsNotification) {
                          _onScroll();
                        }
                        return false;
                      },
                      child: editor,
                    ),
                  ),
                  EditorMinimap(
                    theme: theme,
                    text: tab.codeController.fullText,
                    highlightSpans: tab.codeController.highlightSpans,
                    scrollFraction: scrollFraction,
                    viewportFraction: viewportFraction,
                    onTapFraction: _scrollToFraction,
                  ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: IndentGuidePainter(
                      dots: indentDots,
                      colors: theme.indentGuideColors,
                      scrollOffset: _scrollOffset,
                      lineHeight: _lineHeight,
                      charWidth: _charWidth,
                      topPadding: verticalPad,
                      leftPadding: _gutterWidth + _horizontalPad,
                    ),
                  ),
                ),
              ),
              if (_signatureHelp != null)
                Positioned(
                  left: _gutterWidth + _horizontalPad,
                  top: verticalPad + 8,
                  child: IdeConceptsSignatureHelpPopup(
                    theme: theme,
                    help: _signatureHelp!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

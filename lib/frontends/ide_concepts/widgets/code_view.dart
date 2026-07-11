import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:lsp_client/lsp_client.dart';

import '../../../editor/hover_tooltip.dart';
import '../../../editor/indent_guides.dart';
import '../../../editor/navigation_pulse.dart';
import '../../../editor/tab_model.dart';
import '../../../services/git_service.dart';
import '../../../services/lsp_service.dart';
import '../ide_concepts_code_theme.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';
import 'editor_minimap.dart';
import 'git_gutter.dart';
import 'signature_help_popup.dart';

/// Code editing surface with indent guides, minimap, git gutters, and motion.
class IdeConceptsCodeView extends StatefulWidget {
  const IdeConceptsCodeView({
    super.key,
    required this.theme,
    required this.tab,
    this.focusOn = false,
    this.onChanged,
    this.lspService,
    this.onSignatureHelp,
    this.navigationPulse,
    this.editorFontSize = 13.5,
    this.editorLineHeight = 24 / 13.5,
    this.diffMarkers = const FileDiffMarkers(),
    this.showBlame = false,
    this.blame = const {},
    this.onBlameHover,
  });

  final IdeConceptsTheme theme;
  final TabModel tab;
  final bool focusOn;
  final VoidCallback? onChanged;
  final LspService? lspService;
  final Future<LspSignatureHelp?> Function()? onSignatureHelp;
  final NavigationPulse? navigationPulse;
  final double editorFontSize;
  final double editorLineHeight;
  final FileDiffMarkers diffMarkers;
  final bool showBlame;
  final Map<int, BlameLine> blame;
  final void Function(int line, BlameLine? info)? onBlameHover;

  @override
  State<IdeConceptsCodeView> createState() => _IdeConceptsCodeViewState();
}

class _IdeConceptsCodeViewState extends State<IdeConceptsCodeView>
    with SingleTickerProviderStateMixin {
  static const _gutterWidth = 60.0;
  static const _horizontalPad = 12.0;

  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _viewportExtent = 1;
  double _maxScrollExtent = 1;
  LspSignatureHelp? _signatureHelp;
  late final AnimationController _pulseController;

  double get _fontSize => widget.editorFontSize;
  double get _lineHeight => widget.editorLineHeight * _fontSize;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: KromMotion.goToDefPulseDuration,
    );
    _scrollController.addListener(_onScroll);
    widget.navigationPulse?.addListener(_onNavigationPulse);
    widget.tab.codeController.configureBracketColors(
      widget.theme.bracketPairColors,
    );
  }

  @override
  void didUpdateWidget(covariant IdeConceptsCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationPulse != widget.navigationPulse) {
      oldWidget.navigationPulse?.removeListener(_onNavigationPulse);
      widget.navigationPulse?.addListener(_onNavigationPulse);
    }
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
    widget.navigationPulse?.removeListener(_onNavigationPulse);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onNavigationPulse() {
    if (widget.navigationPulse?.line != null) {
      _pulseController.forward(from: 0);
      setState(() {});
    }
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

  Widget _buildEditorStack(
    Widget editor,
    IdeConceptsTheme theme,
    TabModel tab,
    double verticalPad,
    List<List<IndentGuideDot>> indentDots,
    int? pulseLine,
  ) {
    final scrollFraction = _maxScrollExtent <= 0
        ? 0.0
        : (_scrollOffset / _maxScrollExtent).clamp(0.0, 1.0);
    final viewportFraction = _maxScrollExtent <= 0
        ? 1.0
        : (_viewportExtent / (_viewportExtent + _maxScrollExtent))
            .clamp(0.05, 1.0);

    return Stack(
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
        if (pulseLine != null)
          Positioned(
            left: 0,
            right: 0,
            top: verticalPad + pulseLine * _lineHeight,
            height: _lineHeight,
            child: FadeTransition(
              opacity: Tween(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeOut,
                ),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x66FFE066)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tab = widget.tab;
    final verticalPad = widget.focusOn ? 56.0 : 18.0;
    final indentDots = IndentGuideAnalyzer.analyze(tab.codeController.fullText);
    final pulseLine = widget.navigationPulse?.line;
    final hasDiff = widget.diffMarkers.addedLines.isNotEmpty ||
        widget.diffMarkers.removedLines.isNotEmpty;

    final field = CodeTheme(
      data: buildIdeConceptsCodeTheme(theme),
      child: CodeField(
        controller: tab.codeController,
        textStyle: IdeFonts.mono(
          fontSize: _fontSize,
          height: widget.editorLineHeight,
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

    final editorStack = _buildEditorStack(
      editor,
      theme,
      tab,
      verticalPad,
      indentDots,
      pulseLine,
    );

    return ColoredBox(
      color: theme.editorBg,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.focusOn ? 860 : double.infinity,
          ),
          child: ListenableBuilder(
            listenable: tab.codeController,
            builder: (context, _) {
              final lineCount =
                  tab.codeController.fullText.split('\n').length;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDiff)
                    GitDiffGutter(
                      theme: theme,
                      lineCount: lineCount,
                      markers: widget.diffMarkers,
                      lineHeight: _lineHeight,
                      topPadding: verticalPad,
                    ),
                  if (widget.showBlame)
                    GitBlameGutter(
                      theme: theme,
                      lineCount: lineCount,
                      blame: widget.blame,
                      lineHeight: _lineHeight,
                      topPadding: verticalPad,
                      onLineHover: widget.onBlameHover,
                    ),
                  Expanded(child: editorStack),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

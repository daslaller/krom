import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../../../editor/hover_tooltip.dart';
import '../../../editor/tab_model.dart';
import '../../../services/lsp_service.dart';
import '../ide_concepts_code_theme.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../../../services/git_service.dart';
import 'git_gutter.dart';

/// Code editing surface with optional focus-mode column constraint.
class IdeConceptsCodeView extends StatelessWidget {
  const IdeConceptsCodeView({
    super.key,
    required this.theme,
    required this.tab,
    this.focusOn = false,
    this.onChanged,
    this.lspService,
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
  final FileDiffMarkers diffMarkers;
  final bool showBlame;
  final Map<int, BlameLine> blame;
  final void Function(int line, BlameLine? info)? onBlameHover;

  @override
  Widget build(BuildContext context) {
    final field = CodeTheme(
      data: buildIdeConceptsCodeTheme(theme),
      child: CodeField(
        controller: tab.codeController,
        textStyle: IdeFonts.mono(
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
          textStyle: IdeFonts.mono(fontSize: 13.5, color: theme.lineNum),
          background: theme.editorBg,
        ),
        background: theme.editorBg,
        padding: EdgeInsets.symmetric(vertical: focusOn ? 56 : 18),
        onChanged: onChanged != null ? (_) => onChanged!() : null,
      ),
    );

    final editor = lspService != null && lspService!.isAvailable
        ? HoverTooltip(
            lspService: lspService!,
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
            maxWidth: focusOn ? 860 : double.infinity,
          ),
          child: ListenableBuilder(listenable: tab.codeController, builder:(c,_){final lines=tab.codeController.fullText.split('\n').length; final rh=13.5*(24/13.5); final vp=focusOn?56.0:18.0; final hd=diffMarkers.addedLines.isNotEmpty||diffMarkers.removedLines.isNotEmpty; return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[if(hd)GitDiffGutter(theme:theme,lineCount:lines,markers:diffMarkers,lineHeight:rh,topPadding:vp),if(showBlame)GitBlameGutter(theme:theme,lineCount:lines,blame:blame,lineHeight:rh,topPadding:vp,onLineHover:onBlameHover),Expanded(child:editor)]);}),
        ),
      ),
    );
  }
}

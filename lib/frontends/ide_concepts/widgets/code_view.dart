import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import '../../../editor/hover_tooltip.dart';
import '../../../editor/navigation_pulse.dart';
import '../../../editor/tab_model.dart';
import '../../../services/lsp_service.dart';
import '../ide_concepts_code_theme.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

class IdeConceptsCodeView extends StatefulWidget {
  const IdeConceptsCodeView({super.key, required this.theme, required this.tab, this.focusOn = false, this.onChanged, this.lspService, this.navigationPulse, this.editorFontSize = 13.5, this.editorLineHeight = 24 / 13.5});
  final IdeConceptsTheme theme; final TabModel tab; final bool focusOn; final VoidCallback? onChanged; final LspService? lspService; final NavigationPulse? navigationPulse; final double editorFontSize, editorLineHeight;
  @override State<IdeConceptsCodeView> createState() => _S();
}
class _S extends State<IdeConceptsCodeView> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(vsync: this, duration: KromMotion.goToDefPulseDuration);
  @override void initState() { super.initState(); widget.navigationPulse?.addListener(_p); }
  @override void dispose() { widget.navigationPulse?.removeListener(_p); _a.dispose(); super.dispose(); }
  void _p() { if (widget.navigationPulse?.line != null) { _a.forward(from: 0); setState(() {}); } }
  @override
  Widget build(BuildContext context) {
    final t = widget.theme; final lh = widget.editorLineHeight; final fs = widget.editorFontSize; final v = widget.focusOn ? 56.0 : 18.0;
    final field = CodeTheme(data: buildIdeConceptsCodeTheme(t), child: CodeField(controller: widget.tab.codeController, textStyle: IdeFonts.mono(fontSize: fs, height: lh/fs, color: t.syntax['plain']??t.text), gutterStyle: GutterStyle(showLineNumbers: true, showFoldingHandles: true, showErrors: true, width: 46, margin: 14, textStyle: IdeFonts.mono(fontSize: fs, color: t.lineNum), background: t.editorBg), background: t.editorBg, padding: EdgeInsets.symmetric(vertical: v), onChanged: widget.onChanged != null ? (_) => widget.onChanged!() : null));
    final ed = widget.lspService?.isAvailable == true ? HoverTooltip(lspService: widget.lspService!, controller: widget.tab.codeController, filePath: widget.tab.filePath, child: field) : field;
    final line = widget.navigationPulse?.line;
    return ColoredBox(color: t.editorBg, child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: widget.focusOn ? 860 : double.infinity), child: Stack(children: [ed, if (line != null) Positioned(left: 0, right: 0, top: v + line * lh, height: lh, child: FadeTransition(opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _a, curve: Curves.easeOut)), child: const DecoratedBox(decoration: BoxDecoration(color: Color(0x66FFE066)))))]))));
  }
}

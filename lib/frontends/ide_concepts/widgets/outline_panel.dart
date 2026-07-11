import 'package:flutter/material.dart';

import '../../../editor/tab_controller.dart';
import '../../../panels/outline/outline_service.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

/// Themed document outline — Ctrl+Shift+O in the IDE Concepts shell.
class IdeConceptsOutlinePanel extends StatefulWidget {
  const IdeConceptsOutlinePanel({
    super.key,
    required this.theme,
    required this.tabController,
  });

  final IdeConceptsTheme theme;
  final KromTabController tabController;

  @override
  State<IdeConceptsOutlinePanel> createState() => _IdeConceptsOutlinePanelState();
}

class _IdeConceptsOutlinePanelState extends State<IdeConceptsOutlinePanel> {
  final _service = OutlineService();
  List<OutlineSymbol> _symbols = const [];
  VoidCallback? _contentListener;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabOrContentChanged);
    _attachContentListener();
    _refresh();
  }

  @override
  void dispose() {
    _detachContentListener();
    widget.tabController.removeListener(_onTabOrContentChanged);
    super.dispose();
  }

  void _onTabOrContentChanged() {
    _detachContentListener();
    _attachContentListener();
    _refresh();
  }

  void _attachContentListener() {
    final controller = widget.tabController.activeTab?.codeController;
    if (controller == null) return;
    _contentListener = _refresh;
    controller.addListener(_contentListener!);
  }

  void _detachContentListener() {
    final listener = _contentListener;
    if (listener == null) return;
    widget.tabController.activeTab?.codeController.removeListener(listener);
    _contentListener = null;
  }

  void _refresh() {
    final tab = widget.tabController.activeTab;
    if (tab == null) {
      if (_symbols.isNotEmpty) setState(() => _symbols = const []);
      return;
    }
    final symbols =
        _service.extract(tab.codeController.fullText, tab.filePath);
    if (symbols.length != _symbols.length ||
        !_symbolsEqual(symbols, _symbols)) {
      setState(() => _symbols = symbols);
    }
  }

  bool _symbolsEqual(List<OutlineSymbol> a, List<OutlineSymbol> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name ||
          a[i].kind != b[i].kind ||
          a[i].line != b[i].line) {
        return false;
      }
    }
    return true;
  }

  void _jumpTo(OutlineSymbol symbol) {
    final tab = widget.tabController.activeTab;
    if (tab == null) return;

    final text = tab.codeController.fullText;
    final offset = _lineOffset(text, symbol.line);
    tab.codeController.selection = TextSelection.collapsed(offset: offset);
    tab.codeController.revealPosition(symbol.line);
  }

  static int _lineOffset(String text, int line) {
    var offset = 0;
    var current = 0;
    while (current < line && offset < text.length) {
      if (text[offset] == '\n') current++;
      offset++;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.panelBg,
        border: Border(left: BorderSide(color: theme.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'OUTLINE',
              style: IdeFonts.mono(
                color: theme.muted,
                fontSize: 11,
                weight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(IdeConceptsTheme theme) {
    if (widget.tabController.activeTab == null) {
      return Center(
        child: Text(
          'No file open',
          style: IdeFonts.mono(color: theme.iconDim, fontSize: 12),
        ),
      );
    }
    if (_symbols.isEmpty) {
      return Center(
        child: Text(
          'No symbols',
          style: IdeFonts.mono(color: theme.iconDim, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _symbols.length,
      itemBuilder: (context, i) => _SymbolRow(
        theme: theme,
        symbol: _symbols[i],
        onTap: () => _jumpTo(_symbols[i]),
      ),
    );
  }
}

class _SymbolRow extends StatefulWidget {
  const _SymbolRow({
    required this.theme,
    required this.symbol,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final OutlineSymbol symbol;
  final VoidCallback onTap;

  @override
  State<_SymbolRow> createState() => _SymbolRowState();
}

class _SymbolRowState extends State<_SymbolRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: _hovered ? theme.rowHover : Colors.transparent,
          child: Row(
            children: [
              _KindIcon(theme: theme, kind: widget.symbol.kind),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.symbol.name,
                  overflow: TextOverflow.ellipsis,
                  style: IdeFonts.mono(
                    color: theme.text,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                '${widget.symbol.line + 1}',
                style: IdeFonts.mono(color: theme.iconDim, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.theme, required this.kind});

  final IdeConceptsTheme theme;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (kind) {
      'class' || 'mixin' || 'extension' => ('C', theme.accent),
      'enum' => ('E', theme.syntax['function'] ?? theme.accent2),
      'interface' => ('I', theme.syntax['string'] ?? theme.accent2),
      'method' => ('M', theme.syntax['number'] ?? theme.accent2),
      _ => ('F', theme.muted),
    };
    return SizedBox(
      width: 16,
      child: Text(
        label,
        style: IdeFonts.mono(
          color: color,
          fontSize: 11,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../editor/tab_controller.dart';
import '../../theme/krom_colors.dart';
import '../../theme/typography.dart';
import 'outline_service.dart';

class OutlinePanel extends StatefulWidget {
  const OutlinePanel({super.key, required this.tabController});

  final KromTabController tabController;

  @override
  State<OutlinePanel> createState() => _OutlinePanelState();
}

class _OutlinePanelState extends State<OutlinePanel> {
  final _service = OutlineService();
  List<OutlineSymbol> _symbols = const [];

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    _refresh();
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() => _refresh();

  void _refresh() {
    final tab = widget.tabController.activeTab;
    if (tab == null) {
      setState(() => _symbols = const []);
      return;
    }
    final symbols = _service.extract(tab.codeController.fullText, tab.filePath);
    setState(() => _symbols = symbols);
  }

  void _jumpTo(OutlineSymbol symbol) {
    final tab = widget.tabController.activeTab;
    if (tab == null) return;

    final text = tab.codeController.fullText;
    final offset = _lineOffset(text, symbol.line);
    tab.codeController.selection = TextSelection.collapsed(offset: offset);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text(
            'OUTLINE',
            style: KromTypography.ui(
              color: KromColors.textSecondary,
              fontSize: 11,
              weight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (widget.tabController.activeTab == null) {
      return Center(
        child: Text(
          'No file open',
          style: KromTypography.ui(color: KromColors.textDisabled),
        ),
      );
    }
    if (_symbols.isEmpty) {
      return Center(
        child: Text(
          'No symbols',
          style: KromTypography.ui(color: KromColors.textDisabled),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _symbols.length,
      itemBuilder: (context, i) => _SymbolRow(
        symbol: _symbols[i],
        onTap: () => _jumpTo(_symbols[i]),
      ),
    );
  }
}

class _SymbolRow extends StatefulWidget {
  const _SymbolRow({required this.symbol, required this.onTap});

  final OutlineSymbol symbol;
  final VoidCallback onTap;

  @override
  State<_SymbolRow> createState() => _SymbolRowState();
}

class _SymbolRowState extends State<_SymbolRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: _hovered ? KromColors.surfaceHover : Colors.transparent,
          child: Row(
            children: [
              _KindIcon(kind: widget.symbol.kind),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.symbol.name,
                  overflow: TextOverflow.ellipsis,
                  style: KromTypography.ui(
                    color: KromColors.text,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Text(
                '${widget.symbol.line + 1}',
                style: KromTypography.ui(
                  color: KromColors.textDisabled,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (kind) {
      'class' || 'mixin' || 'extension' => ('C', KromColors.accent),
      'enum' => ('E', const Color(0xFF9CDCFE)),
      'interface' => ('I', const Color(0xFFB5CEA8)),
      'method' => ('M', const Color(0xFFDCDCAA)),
      _ => ('F', KromColors.textSecondary),
    };
    return SizedBox(
      width: 16,
      child: Text(
        label,
        style: KromTypography.ui(
          color: color,
          fontSize: 11,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

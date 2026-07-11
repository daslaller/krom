import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lsp_client/lsp_client.dart';

import '../../../editor/tab_controller.dart';
import '../../../panels/outline/outline_service.dart';
import '../../../services/lsp_service.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

class OutlineNode {
  const OutlineNode({
    required this.name,
    required this.kind,
    required this.line,
    required this.depth,
    this.detail,
  });

  final String name;
  final String kind;
  final int line;
  final int depth;
  final String? detail;
}

/// Themed document outline — `Ctrl+Shift+O` in the IDE Concepts shell.
///
/// Prefers LSP `documentSymbol` (hierarchical); falls back to regex extraction.
class IdeConceptsOutlinePanel extends StatefulWidget {
  const IdeConceptsOutlinePanel({
    super.key,
    required this.theme,
    required this.tabController,
    this.lspService,
  });

  final IdeConceptsTheme theme;
  final KromTabController tabController;
  final LspService? lspService;

  @override
  State<IdeConceptsOutlinePanel> createState() =>
      _IdeConceptsOutlinePanelState();
}

class _IdeConceptsOutlinePanelState extends State<IdeConceptsOutlinePanel> {
  final _regexService = OutlineService();
  List<OutlineNode> _nodes = const [];
  VoidCallback? _contentListener;
  Timer? _refreshDebounce;
  bool _useLsp = false;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabOrContentChanged);
    _attachContentListener();
    _refresh();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _detachContentListener();
    widget.tabController.removeListener(_onTabOrContentChanged);
    super.dispose();
  }

  void _onTabOrContentChanged() {
    _detachContentListener();
    _attachContentListener();
    _scheduleRefresh();
  }

  void _attachContentListener() {
    final controller = widget.tabController.activeTab?.codeController;
    if (controller == null) return;
    _contentListener = _scheduleRefresh;
    controller.addListener(_contentListener!);
  }

  void _detachContentListener() {
    final listener = _contentListener;
    if (listener == null) return;
    widget.tabController.activeTab?.codeController.removeListener(listener);
    _contentListener = null;
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), _refresh);
  }

  Future<void> _refresh() async {
    final tab = widget.tabController.activeTab;
    if (tab == null) {
      if (_nodes.isNotEmpty) setState(() => _nodes = const []);
      return;
    }

    final lsp = widget.lspService;
    if (lsp != null && lsp.isAvailable) {
      final symbols = await lsp.getDocumentSymbols(tab.filePath);
      if (!mounted) return;
      if (symbols.isNotEmpty) {
        final nodes = _flattenLsp(symbols);
        if (!_nodesEqual(nodes, _nodes)) {
          setState(() {
            _nodes = nodes;
            _useLsp = true;
          });
        }
        return;
      }
    }

    final regexSymbols =
        _regexService.extract(tab.codeController.fullText, tab.filePath);
    final nodes = regexSymbols
        .map(
          (s) => OutlineNode(
            name: s.name,
            kind: s.kind,
            line: s.line,
            depth: 0,
          ),
        )
        .toList();
    if (!mounted) return;
    if (!_nodesEqual(nodes, _nodes)) {
      setState(() {
        _nodes = nodes;
        _useLsp = false;
      });
    }
  }

  List<OutlineNode> _flattenLsp(List<LspDocumentSymbol> symbols, [int depth = 0]) {
    final out = <OutlineNode>[];
    for (final s in symbols) {
      out.add(
        OutlineNode(
          name: s.name,
          kind: _kindLabel(s.kind),
          line: s.range.start.line,
          depth: depth,
          detail: s.detail,
        ),
      );
      if (s.children.isNotEmpty) {
        out.addAll(_flattenLsp(s.children, depth + 1));
      }
    }
    return out;
  }

  static String _kindLabel(int kind) => switch (kind) {
        5 => 'class',
        6 => 'method',
        8 => 'field',
        10 => 'enum',
        11 => 'interface',
        12 => 'function',
        23 => 'class',
        _ => 'function',
      };

  bool _nodesEqual(List<OutlineNode> a, List<OutlineNode> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name ||
          a[i].kind != b[i].kind ||
          a[i].line != b[i].line ||
          a[i].depth != b[i].depth) {
        return false;
      }
    }
    return true;
  }

  void _jumpTo(OutlineNode node) {
    final tab = widget.tabController.activeTab;
    if (tab == null) return;
    tab.codeController.revealPosition(node.line);
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
            child: Row(
              children: [
                Text(
                  'OUTLINE',
                  style: IdeFonts.mono(
                    color: theme.muted,
                    fontSize: 11,
                    weight: FontWeight.w600,
                  ),
                ),
                if (_useLsp) ...[
                  const SizedBox(width: 8),
                  Text(
                    'LSP',
                    style: IdeFonts.mono(
                      color: theme.accent2,
                      fontSize: 9,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
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
    if (_nodes.isEmpty) {
      return Center(
        child: Text(
          'No symbols',
          style: IdeFonts.mono(color: theme.iconDim, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _nodes.length,
      itemBuilder: (context, i) => _SymbolRow(
        theme: theme,
        node: _nodes[i],
        onTap: () => _jumpTo(_nodes[i]),
      ),
    );
  }
}

class _SymbolRow extends StatefulWidget {
  const _SymbolRow({
    required this.theme,
    required this.node,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final OutlineNode node;
  final VoidCallback onTap;

  @override
  State<_SymbolRow> createState() => _SymbolRowState();
}

class _SymbolRowState extends State<_SymbolRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final node = widget.node;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KromMotion.hoverDuration,
          curve: KromMotion.hoverCurve,
          height: 28,
          padding: EdgeInsets.only(left: 16 + node.depth * 12, right: 16),
          color: _hovered ? theme.rowHover : Colors.transparent,
          child: Row(
            children: [
              _KindIcon(theme: theme, kind: node.kind),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  overflow: TextOverflow.ellipsis,
                  style: IdeFonts.mono(
                    color: theme.text,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                '${node.line + 1}',
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

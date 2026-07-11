import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../services/workspace_search_service.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

/// Workspace search panel — `Ctrl+Shift+F`.
class IdeConceptsWorkspaceSearchPanel extends StatefulWidget {
  const IdeConceptsWorkspaceSearchPanel({
    super.key,
    required this.theme,
    required this.rootPath,
    required this.onOpenMatch,
    this.onClose,
  });

  final IdeConceptsTheme theme;
  final String? rootPath;
  final void Function(WorkspaceSearchMatch match) onOpenMatch;
  final VoidCallback? onClose;

  @override
  State<IdeConceptsWorkspaceSearchPanel> createState() =>
      _IdeConceptsWorkspaceSearchPanelState();
}

class _IdeConceptsWorkspaceSearchPanelState
    extends State<IdeConceptsWorkspaceSearchPanel> {
  final _queryController = TextEditingController();
  final _searchService = WorkspaceSearchService();
  List<WorkspaceSearchMatch> _matches = const [];
  bool _searching = false;
  bool _caseSensitive = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final root = widget.rootPath;
    if (root == null) return;
    setState(() => _searching = true);
    final results = await _searchService.search(
      rootPath: root,
      query: _queryController.text,
      caseSensitive: _caseSensitive,
    );
    if (!mounted) return;
    setState(() {
      _matches = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.panelBg,
        border: Border(top: BorderSide(color: theme.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Text(
                  'SEARCH',
                  style: IdeFonts.mono(
                    color: theme.muted,
                    fontSize: 11,
                    weight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.onClose != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: theme.iconDim),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: IdeFonts.mono(color: theme.text, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search workspace…',
                      hintStyle: IdeFonts.mono(color: theme.iconDim, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.hairlineStrong),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.hairline),
                      ),
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                _ToggleChip(
                  theme: theme,
                  label: 'Aa',
                  active: _caseSensitive,
                  onTap: () {
                    setState(() => _caseSensitive = !_caseSensitive);
                    _runSearch();
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.search, size: 18, color: theme.accent),
                  onPressed: _runSearch,
                  tooltip: 'Search',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Text(
              _searching
                  ? 'Searching…'
                  : '${_matches.length} result${_matches.length == 1 ? '' : 's'}',
              style: IdeFonts.mono(color: theme.iconDim, fontSize: 11),
            ),
          ),
          Expanded(child: _buildResults(theme)),
        ],
      ),
    );
  }

  Widget _buildResults(IdeConceptsTheme theme) {
    if (_matches.isEmpty) {
      return Center(
        child: Text(
          'No results',
          style: IdeFonts.mono(color: theme.iconDim, fontSize: 12),
        ),
      );
    }

    final grouped = <String, List<WorkspaceSearchMatch>>{};
    for (final m in _matches) {
      grouped.putIfAbsent(m.filePath, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: Text(
              p.basename(entry.key),
              style: IdeFonts.mono(
                color: theme.accent,
                fontSize: 12,
                weight: FontWeight.w600,
              ),
            ),
          ),
          for (final match in entry.value)
            _MatchRow(
              theme: theme,
              match: match,
              onTap: () => widget.onOpenMatch(match),
            ),
        ],
      ],
    );
  }
}

class _MatchRow extends StatefulWidget {
  const _MatchRow({
    required this.theme,
    required this.match,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final WorkspaceSearchMatch match;
  final VoidCallback onTap;

  @override
  State<_MatchRow> createState() => _MatchRowState();
}

class _MatchRowState extends State<_MatchRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final match = widget.match;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KromMotion.hoverDuration,
          curve: KromMotion.hoverCurve,
          color: _hovered ? theme.rowHover : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(24, 4, 12, 4),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '${match.line + 1}',
                  style: IdeFonts.mono(color: theme.iconDim, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  match.text,
                  overflow: TextOverflow.ellipsis,
                  style: IdeFonts.mono(color: theme.text, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.theme,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.rowActive : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.hairline),
        ),
        child: Text(
          label,
          style: IdeFonts.mono(
            color: active ? theme.accent : theme.iconDim,
            fontSize: 12,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

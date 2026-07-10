import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../panels/file_tree/file_tree_node.dart';
import '../../../panels/file_tree/file_tree_service.dart';
import '../ide_concepts_theme.dart';

/// File explorer sidebar. Reuses [FileTreeService]/[FileTreeNode] for real
/// directory data; visual treatment matches the mockup:
///  - dots are always colored by extension, but small + grey unless the
///    file is the one currently open in the active tab.
///  - extension text is always colored by extension (never dimmed), so a
///    given filetype reads the same color everywhere.
class IdeConceptsSidebar extends StatefulWidget {
  const IdeConceptsSidebar({
    super.key,
    required this.theme,
    required this.rootPath,
    required this.activeFilePath,
    required this.onFileSelected,
  });

  final IdeConceptsTheme theme;
  final String? rootPath;
  final String? activeFilePath;
  final void Function(String path) onFileSelected;

  @override
  State<IdeConceptsSidebar> createState() => _IdeConceptsSidebarState();
}

class _IdeConceptsSidebarState extends State<IdeConceptsSidebar> {
  final _service = FileTreeService();
  FileTreeNode? _root;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void didUpdateWidget(IdeConceptsSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootPath != widget.rootPath) _loadTree();
  }

  Future<void> _loadTree() async {
    if (widget.rootPath == null) return;
    setState(() => _loading = true);
    _root = await _service.buildTree(widget.rootPath!);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      width: 208,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.sidebarBg,
        border: Border(right: BorderSide(color: theme.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Explorer',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.08 * 10.5,
                color: theme.muted,
              ),
            ),
          ),
          Expanded(child: _buildBody(theme)),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.hairline)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: theme.accent2,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'main · clean',
                  style: TextStyle(fontSize: 11.5, color: theme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(IdeConceptsTheme theme) {
    if (widget.rootPath == null) {
      return Center(
        child: Text(
          'No folder open',
          style: TextStyle(fontSize: 12.5, color: theme.iconDim),
        ),
      );
    }
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: theme.iconDim,
          ),
        ),
      );
    }
    final root = _root;
    if (root == null) return const SizedBox.shrink();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final child in root.children)
          _NodeRow(
            node: child,
            depth: 0,
            theme: theme,
            activeFilePath: widget.activeFilePath,
            onFileSelected: widget.onFileSelected,
          ),
      ],
    );
  }
}

class _NodeRow extends StatefulWidget {
  const _NodeRow({
    required this.node,
    required this.depth,
    required this.theme,
    required this.activeFilePath,
    required this.onFileSelected,
  });

  final FileTreeNode node;
  final int depth;
  final IdeConceptsTheme theme;
  final String? activeFilePath;
  final void Function(String path) onFileSelected;

  @override
  State<_NodeRow> createState() => _NodeRowState();
}

class _NodeRowState extends State<_NodeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final theme = widget.theme;
    final isActive = !node.isDirectory && node.path == widget.activeFilePath;

    final ext = node.isDirectory ? null : p.extension(node.name);
    final hasExt = ext != null && ext.isNotEmpty;
    final base = hasExt
        ? node.name.substring(0, node.name.length - ext.length)
        : node.name;
    final extText = hasExt ? ext : '';
    final extColor = hasExt
        ? theme.colorForExtension(ext.substring(1))
        : theme.muted;

    final dotColor = isActive
        ? (hasExt ? theme.colorForExtension(ext.substring(1)) : theme.accent)
        : theme.iconDim;
    final dotSize = isActive ? 6.0 : 3.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (node.isDirectory) {
                setState(() => node.isExpanded = !node.isExpanded);
              } else {
                widget.onFileSelected(node.path);
              }
            },
            child: Container(
              padding: EdgeInsets.only(
                left: 16.0 + widget.depth * 14,
                right: 16,
                top: 6,
                bottom: 6,
              ),
              color: isActive
                  ? theme.rowActive
                  : (_hovered ? theme.rowHover : Colors.transparent),
              child: Row(
                children: [
                  if (node.isDirectory)
                    Icon(
                      node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 14,
                      color: theme.iconDim,
                    )
                  else
                    SizedBox(
                      width: 12,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: dotColor.withValues(alpha: 0.13),
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: base,
                            style: TextStyle(
                              fontSize: 13,
                              color: isActive ? theme.text : theme.muted,
                            ),
                          ),
                          TextSpan(
                            text: extText,
                            style: TextStyle(fontSize: 13, color: extColor),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          for (final child in node.children)
            _NodeRow(
              node: child,
              depth: widget.depth + 1,
              theme: theme,
              activeFilePath: widget.activeFilePath,
              onFileSelected: widget.onFileSelected,
            ),
      ],
    );
  }
}

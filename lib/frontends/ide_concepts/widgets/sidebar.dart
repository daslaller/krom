import 'package:flutter/material.dart';

import '../../../services/git_service.dart';
import '../../../panels/file_tree/file_tree_node.dart';
import '../../../panels/file_tree/file_tree_service.dart';
import '../file_label.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

/// File explorer with Tacet-style type tags and git footer.
class IdeConceptsSidebar extends StatefulWidget {
  const IdeConceptsSidebar({
    super.key,
    required this.theme,
    required this.rootPath,
    required this.activeFilePath,
    required this.gitStatus,
    required this.onFileSelected,
  });

  final IdeConceptsTheme theme;
  final String? rootPath;
  final String? activeFilePath;
  final GitStatus gitStatus;
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
      width: 236,
      decoration: BoxDecoration(
        color: theme.sidebarBg,
        border: Border(right: BorderSide(color: theme.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'krom',
                  style: IdeFonts.mono(
                    fontSize: 12,
                    weight: FontWeight.w600,
                    color: theme.text,
                  ),
                ),
                Text(
                  'explorer',
                  style: IdeFonts.mono(fontSize: 10, color: theme.iconDim),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(theme)),
          _GitFooter(theme: theme, gitStatus: widget.gitStatus),
        ],
      ),
    );
  }

  Widget _buildBody(IdeConceptsTheme theme) {
    if (widget.rootPath == null) {
      return Center(
        child: Text(
          'No folder open',
          style: IdeFonts.mono(fontSize: 12.5, color: theme.iconDim),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

class _GitFooter extends StatelessWidget {
  const _GitFooter({required this.theme, required this.gitStatus});

  final IdeConceptsTheme theme;
  final GitStatus gitStatus;

  @override
  Widget build(BuildContext context) {
    if (!gitStatus.isRepo) return const SizedBox.shrink();

    final changesLabel = gitStatus.modifiedCount == 0
        ? 'clean'
        : '${gitStatus.modifiedCount} modified';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.hairline)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'branch',
                style: IdeFonts.mono(fontSize: 10.5, color: theme.iconDim),
              ),
              Text(
                gitStatus.branch ?? '—',
                style: IdeFonts.mono(fontSize: 10.5, color: theme.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'changes',
                style: IdeFonts.mono(fontSize: 10.5, color: theme.iconDim),
              ),
              Text(
                changesLabel,
                style: IdeFonts.mono(
                  fontSize: 10.5,
                  color: gitStatus.modifiedCount > 0
                      ? theme.accent2
                      : theme.muted,
                ),
              ),
            ],
          ),
        ],
      ),
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
    final parts = FileLabelParts.fromFileName(node.name);
    final extColor = parts.extKey != null
        ? theme.colorForExtension(parts.extKey)
        : theme.muted;

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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(left: widget.depth * 12.0),
              padding: EdgeInsets.fromLTRB(
                node.isDirectory ? 8 : 21,
                5,
                8,
                5,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.rowActive
                    : (_hovered ? theme.rowHover : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (node.isDirectory)
                    Text(
                      node.isExpanded ? '▼' : '▶',
                      style: IdeFonts.mono(fontSize: 8, color: theme.iconDim),
                    )
                  else ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isActive ? theme.accent : theme.iconDim,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (parts.tag.isNotEmpty)
                      SizedBox(
                        width: 22,
                        child: Text(
                          parts.tag,
                          style: IdeFonts.mono(
                            fontSize: 9,
                            color: extColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                  if (node.isDirectory) const SizedBox(width: 7),
                  Expanded(
                    child: node.isDirectory
                        ? Text(
                            node.name,
                            style: IdeFonts.mono(
                              fontSize: 12,
                              weight: FontWeight.w500,
                              color: theme.muted,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: parts.base,
                                  style: IdeFonts.mono(
                                    fontSize: 12.5,
                                    color: isActive ? theme.text : theme.muted,
                                  ),
                                ),
                                if (parts.ext.isNotEmpty)
                                  TextSpan(
                                    text: parts.ext,
                                    style: IdeFonts.mono(
                                      fontSize: 12.5,
                                      color: extColor,
                                    ),
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

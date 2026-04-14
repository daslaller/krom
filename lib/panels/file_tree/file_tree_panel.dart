import 'package:flutter/material.dart';
import '../../theme/krom_colors.dart';
import '../../theme/typography.dart';
import 'file_tree_node.dart';
import 'file_tree_service.dart';

class FileTreePanel extends StatefulWidget {
  const FileTreePanel({
    super.key,
    required this.rootPath,
    required this.onFileSelected,
  });

  final String? rootPath;
  final void Function(String path) onFileSelected;

  @override
  State<FileTreePanel> createState() => _FileTreePanelState();
}

class _FileTreePanelState extends State<FileTreePanel> {
  final _service = FileTreeService();
  FileTreeNode? _root;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  @override
  void didUpdateWidget(FileTreePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootPath != widget.rootPath) _loadTree();
  }

  Future<void> _loadTree() async {
    if (widget.rootPath == null) return;
    setState(() => _loading = true);
    _root = await _service.buildTree(widget.rootPath!);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rootPath == null) {
      return Center(
        child: Text(
          'No folder open',
          style: KromTypography.ui(color: KromColors.textDisabled),
        ),
      );
    }
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: KromColors.textDisabled,
          ),
        ),
      );
    }
    if (_root == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text(
            _root!.name.toUpperCase(),
            style: KromTypography.ui(
              color: KromColors.textSecondary,
              fontSize: 11,
              weight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final child in _root!.children)
                _NodeWidget(
                  node: child,
                  depth: 0,
                  onFileSelected: widget.onFileSelected,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NodeWidget extends StatefulWidget {
  const _NodeWidget({
    required this.node,
    required this.depth,
    required this.onFileSelected,
  });

  final FileTreeNode node;
  final int depth;
  final void Function(String path) onFileSelected;

  @override
  State<_NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<_NodeWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () {
              if (node.isDirectory) {
                setState(() => node.isExpanded = !node.isExpanded);
              } else {
                widget.onFileSelected(node.path);
              }
            },
            child: Container(
              height: 30,
              padding: EdgeInsets.only(left: 16.0 + widget.depth * 18),
              color: _hovered
                  ? KromColors.surfaceHover
                  : Colors.transparent,
              child: Row(
                children: [
                  if (node.isDirectory)
                    Icon(
                      node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: KromColors.textSecondary,
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      node.name,
                      overflow: TextOverflow.ellipsis,
                      style: KromTypography.ui(
                        color: KromColors.text,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          for (final child in node.children)
            _NodeWidget(
              node: child,
              depth: widget.depth + 1,
              onFileSelected: widget.onFileSelected,
            ),
      ],
    );
  }
}

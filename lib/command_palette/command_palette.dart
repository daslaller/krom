import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../theme/krom_colors.dart';
import '../theme/typography.dart';
import 'command_palette_controller.dart';
import 'palette_item.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({
    super.key,
    required this.controller,
    required this.rootPath,
    required this.onFileSelected,
    required this.onDismiss,
  });

  final CommandPaletteController controller;
  final String? rootPath;
  final void Function(String path) onFileSelected;
  final VoidCallback onDismiss;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.controller.moveUp();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.controller.moveDown();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      final item = widget.controller.confirm();
      if (item is PaletteFileItem) {
        widget.onFileSelected(item.path);
        widget.onDismiss();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
    }
  }

  String _relativePath(String path) {
    final root = widget.rootPath;
    if (root != null && path.startsWith(root)) {
      return path.substring(root.length + 1).replaceAll('\\', '/');
    }
    return p.basename(path);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onDismiss,
          child: Container(color: Colors.black45),
        ),
        Align(
          alignment: const Alignment(0, -0.55),
          child: SizedBox(
            width: 560,
            child: Material(
              color: KromColors.surface,
              borderRadius: BorderRadius.circular(10),
              elevation: 24,
              shadowColor: Colors.black54,
              child: KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: _handleKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearchField(),
                    _buildResults(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _textController,
        onChanged: widget.controller.updateQuery,
        style: KromTypography.ui(color: KromColors.text, fontSize: 14.5),
        cursorColor: KromColors.accent,
        decoration: InputDecoration(
          hintText: 'Search files...',
          hintStyle: KromTypography.ui(
            color: KromColors.textDisabled,
            fontSize: 14.5,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.search,
              size: 20,
              color: KromColors.textSecondary,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          filled: true,
          fillColor: KromColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = widget.controller.items;
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No files found',
              style: KromTypography.ui(color: KromColors.textDisabled),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is! PaletteFileItem) return const SizedBox.shrink();
              final isSelected = index == widget.controller.selectedIndex;
              return GestureDetector(
                onTap: () {
                  widget.onFileSelected(item.path);
                  widget.onDismiss();
                },
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KromColors.surfaceActive
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _relativePath(item.path),
                    overflow: TextOverflow.ellipsis,
                    style: KromTypography.ui(
                      color: isSelected
                          ? KromColors.text
                          : KromColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

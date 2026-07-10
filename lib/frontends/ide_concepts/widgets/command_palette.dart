import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../command_palette/command_palette_controller.dart';
import '../ide_concepts_theme.dart';

/// Command palette styled to match the Beautiful IDE v2 mockup.
class IdeConceptsCommandPalette extends StatefulWidget {
  const IdeConceptsCommandPalette({
    super.key,
    required this.theme,
    required this.controller,
    required this.rootPath,
    required this.onFileSelected,
    required this.onDismiss,
  });

  final IdeConceptsTheme theme;
  final CommandPaletteController controller;
  final String? rootPath;
  final void Function(String path) onFileSelected;
  final VoidCallback onDismiss;

  @override
  State<IdeConceptsCommandPalette> createState() =>
      _IdeConceptsCommandPaletteState();
}

class _IdeConceptsCommandPaletteState extends State<IdeConceptsCommandPalette> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
      final path = widget.controller.confirm();
      if (path != null) {
        widget.onFileSelected(path);
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
    final theme = widget.theme;
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onDismiss,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: theme.veil),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.35),
          child: SizedBox(
            width: 600,
            child: Material(
              color: Colors.transparent,
              child: KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: _handleKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.panelBg,
                    border: Border.all(color: theme.hairlineStrong),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x73000000),
                        blurRadius: 70,
                        offset: Offset(0, 24),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _textController,
                        autofocus: true,
                        onChanged: widget.controller.updateQuery,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontFamilyFallback: const [
                            'Cascadia Code',
                            'Consolas',
                            'monospace',
                          ],
                          fontSize: 14,
                          color: theme.text,
                        ),
                        cursorColor: theme.accent,
                        decoration: InputDecoration(
                          hintText: 'Type a command',
                          hintStyle: TextStyle(color: theme.muted),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      Divider(height: 1, color: theme.hairline),
                      _buildResults(theme),
                      Divider(height: 1, color: theme.hairline),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '↑↓ navigate',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.muted,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '↵ run',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.muted,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'esc close',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(IdeConceptsTheme theme) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final paths = widget.controller.filteredPaths;
        if (paths.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'No matching commands',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.muted),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(6),
            itemCount: paths.length,
            itemBuilder: (context, index) {
              final isSelected = index == widget.controller.selectedIndex;
              final path = paths[index];
              return GestureDetector(
                onTap: () {
                  widget.onFileSelected(path);
                  widget.onDismiss();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.rowActive : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 15,
                        decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Opacity(
                          opacity: isSelected ? 1 : 0,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _relativePath(path),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: theme.text),
                        ),
                      ),
                      Text(
                        p.extension(path).replaceFirst('.', ''),
                        style: TextStyle(fontSize: 11, color: theme.muted),
                      ),
                    ],
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

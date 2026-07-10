import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../command_palette/command_palette_controller.dart';
import '../../../command_palette/palette_item.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

/// Command palette with commands, recent files, and fuzzy file search.
class IdeConceptsCommandPalette extends StatefulWidget {
  const IdeConceptsCommandPalette({
    super.key,
    required this.theme,
    required this.controller,
    required this.onCommand,
    required this.onFileSelected,
    required this.onDismiss,
  });

  final IdeConceptsTheme theme;
  final CommandPaletteController controller;
  final void Function(String commandId) onCommand;
  final void Function(String path) onFileSelected;
  final VoidCallback onDismiss;

  @override
  State<IdeConceptsCommandPalette> createState() =>
      _IdeConceptsCommandPaletteState();
}

class _IdeConceptsCommandPaletteState extends State<IdeConceptsCommandPalette>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

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
    _anim.dispose();
    super.dispose();
  }

  void _confirm() {
    final item = widget.controller.confirm();
    if (item == null) return;
    if (item is PaletteCommandItem) {
      widget.onCommand(item.id);
    } else if (item is PaletteFileItem) {
      widget.onFileSelected(item.path);
    }
    widget.onDismiss();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.controller.moveUp();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.controller.moveDown();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _confirm();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
    }
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
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: _anim,
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
                            style: IdeFonts.mono(fontSize: 14, color: theme.text),
                            cursorColor: theme.accent,
                            decoration: InputDecoration(
                              hintText: 'Type a command or file name',
                              hintStyle: IdeFonts.mono(color: theme.muted),
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
                                  style: IdeFonts.mono(
                                    fontSize: 10.5,
                                    color: theme.muted,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '↵ run',
                                  style: IdeFonts.mono(
                                    fontSize: 10.5,
                                    color: theme.muted,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'esc close',
                                  style: IdeFonts.mono(
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
          ),
        ),
      ],
    );
  }

  Widget _buildResults(IdeConceptsTheme theme) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = widget.controller.items;
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'No matching commands or files',
              textAlign: TextAlign.center,
              style: IdeFonts.mono(fontSize: 12, color: theme.muted),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(6),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = index == widget.controller.selectedIndex;
              return MouseRegion(
                onEnter: (_) => widget.controller.setSelectedIndex(index),
                child: GestureDetector(
                  onTap: () {
                    widget.controller.setSelectedIndex(index);
                    _confirm();
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
                            item.label,
                            overflow: TextOverflow.ellipsis,
                            style: IdeFonts.mono(
                              fontSize: 12.5,
                              color: theme.text,
                            ),
                          ),
                        ),
                        if (item.hint.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.hairline),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.hint,
                              style: IdeFonts.mono(
                                fontSize: 10.5,
                                color: theme.iconDim,
                              ),
                            ),
                          ),
                      ],
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

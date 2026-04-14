import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../command_palette/command_palette.dart';
import '../command_palette/command_palette_controller.dart';
import '../panels/file_tree/file_tree_service.dart';
import '../panels/panel_controller.dart';
import '../panels/panel_host.dart';
import '../services/file_service.dart';
import '../theme/krom_colors.dart';
import '../theme/typography.dart';
import 'code_view.dart';
import 'tab_bar.dart';
import 'tab_controller.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _tabController = KromTabController();
  final _panelController = PanelController();
  final _paletteController = CommandPaletteController();
  final _fileService = FileService();
  final _treeService = FileTreeService();
  final _focusNode = FocusNode();

  // Structural selection stack — Shift+Alt+→ pushes, Shift+Alt+← pops.
  final List<TextSelection> _selectionStack = [];

  String? _rootPath;
  bool _showPalette = false;

  @override
  void initState() {
    super.initState();
    // Clear the selection stack whenever the active tab changes.
    _tabController.addListener(_onTabChanged);
    _openFolder(Directory.current.path);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _panelController.dispose();
    _paletteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() => _selectionStack.clear();

  Future<void> _openFolder(String path) async {
    _rootPath = path;
    final files = await _treeService.allFilePaths(path);
    _paletteController.setFiles(files, path);
    setState(() {});
  }

  Future<void> _openFile(String path) async {
    try {
      final content = await _fileService.readFile(path);
      _tabController.openFile(path, content);
    } catch (_) {}
  }

  Future<void> _saveActiveFile() async {
    final tab = _tabController.activeTab;
    if (tab == null || !tab.isDirty) return;
    final content = tab.codeController.fullText;
    await _fileService.writeFile(tab.filePath, content);
    tab.content = content;
    _tabController.markClean(_tabController.activeIndex);
  }

  void _togglePalette() {
    setState(() {
      _showPalette = !_showPalette;
      if (_showPalette) {
        _paletteController.updateQuery('');
      }
    });
  }

  void _onEditorChanged() {
    _tabController.markDirty(_tabController.activeIndex);
  }

  // ---------------------------------------------------------------------------
  // Structural selection — Shift+Alt+→ / Shift+Alt+←
  // ---------------------------------------------------------------------------

  void _expandSelection() {
    final tab = _tabController.activeTab;
    if (tab == null) return;
    final controller = tab.codeController;
    final text = controller.fullText;
    final current = controller.selection;
    if (!current.isValid) return;

    final next = _findEnclosingBrackets(text, current);
    if (next == null) return;

    _selectionStack.add(current);
    controller.selection = next;
  }

  void _shrinkSelection() {
    if (_selectionStack.isEmpty) return;
    final tab = _tabController.activeTab;
    if (tab == null) return;
    tab.codeController.selection = _selectionStack.removeLast();
  }

  /// Finds the smallest bracket pair `()`, `[]`, `{}` that fully encloses
  /// [selection]. Returns the selection inside those brackets on the first
  /// call; if [selection] already equals that inner range, returns the range
  /// inclusive of the brackets themselves.
  static TextSelection? _findEnclosingBrackets(
    String text,
    TextSelection selection,
  ) {
    const opens = '({[';
    const closes = ')}]';

    final start = selection.start;
    final end = selection.end;

    // Walk backwards from start to find the nearest unmatched opening bracket.
    var depth = 0;
    for (var i = start - 1; i >= 0; i--) {
      final c = text[i];
      final closeIdx = closes.indexOf(c);
      if (closeIdx >= 0) {
        depth++;
        continue;
      }
      final openIdx = opens.indexOf(c);
      if (openIdx < 0) continue;

      if (depth > 0) {
        depth--;
        continue;
      }

      // Found an unmatched opening bracket at i. Scan forward for its match.
      final matchClose = closes[openIdx];
      var inner = 0;
      for (var j = i + 1; j < text.length; j++) {
        if (text[j] == text[i]) {
          inner++;
        } else if (text[j] == matchClose) {
          if (inner > 0) {
            inner--;
            continue;
          }
          // j is the closing bracket. Offer inner range first, then outer.
          final innerSel = TextSelection(baseOffset: i + 1, extentOffset: j);
          if (selection.start == i + 1 && selection.end == j) {
            // Already selecting inside — expand to include brackets.
            return TextSelection(baseOffset: i, extentOffset: j + 1);
          }
          // Does the closing bracket come after (or at) the current end?
          if (j >= end) return innerSel;
          break;
        }
      }
      break;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            const _PaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            const _FileTreeIntent(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true, shift: true):
            const _OutlineIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.keyW, control: true):
            const _CloseTabIntent(),
        const SingleActivator(LogicalKeyboardKey.tab, control: true):
            const _NextTabIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const _EscapeIntent(),
        const SingleActivator(
          LogicalKeyboardKey.arrowRight,
          shift: true,
          alt: true,
        ): const _ExpandSelectionIntent(),
        const SingleActivator(
          LogicalKeyboardKey.arrowLeft,
          shift: true,
          alt: true,
        ): const _ShrinkSelectionIntent(),
      },
      child: Actions(
        actions: {
          _PaletteIntent: CallbackAction<_PaletteIntent>(
            onInvoke: (_) => _togglePalette(),
          ),
          _FileTreeIntent: CallbackAction<_FileTreeIntent>(
            onInvoke: (_) => _panelController.toggle(PanelType.fileTree),
          ),
          _OutlineIntent: CallbackAction<_OutlineIntent>(
            onInvoke: (_) => _panelController.toggle(PanelType.outline),
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) => _saveActiveFile(),
          ),
          _CloseTabIntent: CallbackAction<_CloseTabIntent>(
            onInvoke: (_) =>
                _tabController.closeTab(_tabController.activeIndex),
          ),
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) => _tabController.nextTab(),
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              if (_showPalette) {
                setState(() => _showPalette = false);
              } else {
                _panelController.close();
              }
              return null;
            },
          ),
          _ExpandSelectionIntent: CallbackAction<_ExpandSelectionIntent>(
            onInvoke: (_) {
              _expandSelection();
              return null;
            },
          ),
          _ShrinkSelectionIntent: CallbackAction<_ShrinkSelectionIntent>(
            onInvoke: (_) {
              _shrinkSelection();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  children: [
                    KromTabBar(controller: _tabController),
                    Expanded(
                      child: Row(
                        children: [
                          PanelHost(
                            panelController: _panelController,
                            tabController: _tabController,
                            rootPath: _rootPath,
                            onFileSelected: _openFile,
                          ),
                          Expanded(child: _buildEditorArea()),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_showPalette)
                  CommandPalette(
                    controller: _paletteController,
                    rootPath: _rootPath,
                    onFileSelected: _openFile,
                    onDismiss: () => setState(() => _showPalette = false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorArea() {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        final tab = _tabController.activeTab;
        if (tab == null) return _buildEmptyState();
        return CodeView(
          key: ValueKey(tab.filePath),
          tab: tab,
          onChanged: _onEditorChanged,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Krom',
            style: KromTypography.ui(
              color: KromColors.textDisabled,
              fontSize: 40,
              weight: FontWeight.w300,
              height: 1,
            ),
          ),
          const SizedBox(height: 32),
          _EmptyStateAction(
            label: 'Open File',
            shortcut: 'Ctrl+P',
            onTap: _togglePalette,
          ),
          const SizedBox(height: 8),
          _EmptyStateAction(
            label: 'Toggle File Tree',
            shortcut: 'Ctrl+B',
            onTap: () => _panelController.toggle(PanelType.fileTree),
          ),
          const SizedBox(height: 8),
          _EmptyStateAction(
            label: 'Toggle Outline',
            shortcut: 'Ctrl+Shift+O',
            onTap: () => _panelController.toggle(PanelType.outline),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateAction extends StatefulWidget {
  const _EmptyStateAction({
    required this.label,
    required this.shortcut,
    required this.onTap,
  });

  final String label;
  final String shortcut;
  final VoidCallback onTap;

  @override
  State<_EmptyStateAction> createState() => _EmptyStateActionState();
}

class _EmptyStateActionState extends State<_EmptyStateAction> {
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
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? KromColors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: KromTypography.ui(
                  color: KromColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                widget.shortcut,
                style: KromTypography.ui(
                  color: KromColors.textDisabled,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteIntent extends Intent {
  const _PaletteIntent();
}

class _FileTreeIntent extends Intent {
  const _FileTreeIntent();
}

class _OutlineIntent extends Intent {
  const _OutlineIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _ExpandSelectionIntent extends Intent {
  const _ExpandSelectionIntent();
}

class _ShrinkSelectionIntent extends Intent {
  const _ShrinkSelectionIntent();
}

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

  String? _rootPath;
  bool _showPalette = false;

  @override
  void initState() {
    super.initState();
    _openFolder(Directory.current.path);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _panelController.dispose();
    _paletteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            const _PaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            const _FileTreeIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.keyW, control: true):
            const _CloseTabIntent(),
        const SingleActivator(LogicalKeyboardKey.tab, control: true):
            const _NextTabIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const _EscapeIntent(),
      },
      child: Actions(
        actions: {
          _PaletteIntent: CallbackAction<_PaletteIntent>(
            onInvoke: (_) => _togglePalette(),
          ),
          _FileTreeIntent: CallbackAction<_FileTreeIntent>(
            onInvoke: (_) => _panelController.toggle(PanelType.fileTree),
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

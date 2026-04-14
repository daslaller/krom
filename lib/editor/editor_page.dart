import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../command_palette/command_palette.dart';
import '../command_palette/command_palette_controller.dart';
import '../panels/file_tree/file_tree_service.dart';
import '../panels/panel_controller.dart';
import '../panels/panel_host.dart';
import '../services/file_service.dart';
import '../services/lsp_service.dart';
import '../services/settings_service.dart';
import '../theme/krom_colors.dart';
import '../theme/typography.dart';
import 'code_view.dart';
import 'krom_analyzer.dart';
import 'krom_autocompleter.dart';
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
  final _settings = SettingsService();
  late final _lspService = LspService(_settings);
  final _focusNode = FocusNode();

  // Per-file LSP helpers; disposed when their tab closes.
  final Map<String, KromAnalyzer> _analyzers = {};
  final Map<String, KromAutocompleter> _autocompleters = {};

  String? _rootPath;
  bool _showPalette = false;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) => _openFolder(Directory.current.path));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _panelController.dispose();
    _paletteController.dispose();
    _focusNode.dispose();
    for (final a in _analyzers.values) {
      a.dispose();
    }
    for (final ac in _autocompleters.values) {
      ac.dispose();
    }
    _lspService.dispose();
    super.dispose();
  }

  Future<void> _openFolder(String path) async {
    _rootPath = path;
    final files = await _treeService.allFilePaths(path);
    _paletteController.setFiles(files, path);
    setState(() {});
    // Start the language server for the workspace root.
    _lspService.initialize(path);
  }

  Future<void> _openFile(String path) async {
    // If already open just switch to it.
    final existing = _tabController.tabs.indexWhere((t) => t.filePath == path);
    if (existing != -1) {
      _tabController.setActive(existing);
      return;
    }

    try {
      final content = await _fileService.readFile(path);
      _tabController.openFile(path, content);
      _wireLsp(path, content);
    } catch (_) {}
  }

  /// Attaches KromAnalyzer + KromAutocompleter to the tab for [path].
  void _wireLsp(String path, String content) {
    final languageId = LspService.languageIdFromPath(path);
    if (languageId == null) return;

    final tab = _tabController.tabs.firstWhere((t) => t.filePath == path);

    final analyzer = KromAnalyzer(
      lspService: _lspService,
      filePath: path,
      onNewDiagnostics: () => tab.codeController.analyzeCode(),
    );
    _analyzers[path] = analyzer;
    tab.codeController.analyzer = analyzer;

    final autocompleter = KromAutocompleter(
      lspService: _lspService,
      filePath: path,
    );
    _autocompleters[path] = autocompleter;

    _lspService.openDocument(path, languageId, content);
  }

  void _closeLsp(String path) {
    _analyzers.remove(path)?.dispose();
    _autocompleters.remove(path)?.dispose();
    final languageId = LspService.languageIdFromPath(path);
    if (languageId != null) {
      _lspService.closeDocument(path, languageId);
    }
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
      if (_showPalette) _paletteController.updateQuery('');
    });
  }

  void _onEditorChanged() {
    final tab = _tabController.activeTab;
    if (tab == null) return;
    _tabController.markDirty(_tabController.activeIndex);

    final languageId = LspService.languageIdFromPath(tab.filePath);
    if (languageId != null) {
      _lspService.scheduleChange(
        tab.filePath,
        languageId,
        tab.codeController.fullText,
      );
    }
    _autocompleters[tab.filePath]?.onChanged(tab.codeController);
  }

  void _closeActiveTab() {
    final idx = _tabController.activeIndex;
    if (idx < 0) return;
    final path = _tabController.tabs[idx].filePath;
    _tabController.closeTab(idx);
    _closeLsp(path);
  }

  Future<void> _goToDefinition() async {
    final tab = _tabController.activeTab;
    if (tab == null) return;

    final offset = tab.codeController.selection.baseOffset;
    if (offset < 0) return;

    final text = tab.codeController.fullText;
    final (line, character) = _offsetToLineChar(text, offset);

    final locations =
        await _lspService.getDefinition(tab.filePath, line, character);
    if (locations.isEmpty) return;

    final loc = locations.first;
    // Convert the file URI returned by the LSP server back to a local path.
    final targetPath = Uri.parse(loc.uri).toFilePath();
    await _openFile(targetPath);
    // TODO(phase2): scroll to loc.range.start.line after open
  }

  static (int line, int character) _offsetToLineChar(String text, int offset) {
    var line = 0;
    var lineStart = 0;
    final end = offset.clamp(0, text.length);
    for (var i = 0; i < end; i++) {
      if (text[i] == '\n') {
        line++;
        lineStart = i + 1;
      }
    }
    return (line, end - lineStart);
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
        const SingleActivator(LogicalKeyboardKey.f12):
            const _GoToDefinitionIntent(),
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
            onInvoke: (_) => _closeActiveTab(),
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
          _GoToDefinitionIntent: CallbackAction<_GoToDefinitionIntent>(
            onInvoke: (_) => _goToDefinition(),
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

class _GoToDefinitionIntent extends Intent {
  const _GoToDefinitionIntent();
}

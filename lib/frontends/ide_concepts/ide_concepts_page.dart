import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../command_palette/command_palette.dart';
import '../../command_palette/command_palette_controller.dart';
import '../../editor/krom_analyzer.dart';
import '../../editor/krom_autocompleter.dart';
import '../../editor/tab_controller.dart';
import '../../panels/file_tree/file_tree_service.dart';
import '../../services/file_service.dart';
import '../../services/lsp_service.dart';
import '../../services/parser_service.dart';
import '../../services/settings_service.dart';
import '../../utils/text_position.dart';
import 'ide_concepts_theme.dart';
import 'widgets/code_view.dart';
import 'widgets/sidebar.dart';
import 'widgets/status_bar.dart';
import 'widgets/tab_bar.dart';
import 'widgets/title_bar.dart';

/// The "IDE Concepts" frontend — a full recreation of the Claude Design
/// mockup (Midnight Indigo dark / Paper Light light), wired to Krom's real
/// file tree, tab, LSP and tree-sitter services rather than mock data.
///
/// This is one of several frontends being evaluated for Krom; it lives on
/// its own branch so it can be compared against others before one is
/// picked as the default (see lib/main.dart on this branch).
class IdeConceptsPage extends StatefulWidget {
  const IdeConceptsPage({super.key});

  @override
  State<IdeConceptsPage> createState() => _IdeConceptsPageState();
}

class _IdeConceptsPageState extends State<IdeConceptsPage> {
  final _tabController = KromTabController();
  final _paletteController = CommandPaletteController();
  final _fileService = FileService();
  final _treeService = FileTreeService();
  final _settings = SettingsService();
  late final _lspService = LspService(_settings);
  late final _parserService = ParserService(_settings);
  final _focusNode = FocusNode();

  final Map<String, KromAnalyzer> _analyzers = {};
  final Map<String, KromAutocompleter> _autocompleters = {};

  String? _rootPath;
  bool _showPalette = false;
  bool _showSidebar = true;
  bool _useParser = true;
  bool _isDark = true;

  IdeConceptsTheme get _theme =>
      _isDark ? IdeConceptsTheme.midnightIndigo : IdeConceptsTheme.paperLight;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) async {
      _useParser = _settings.useTreeSitter;
      await _parserService.initialize();
      _openFolder(Directory.current.path);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paletteController.dispose();
    _focusNode.dispose();
    for (final a in _analyzers.values) {
      a.dispose();
    }
    for (final ac in _autocompleters.values) {
      ac.dispose();
    }
    _lspService.dispose();
    _parserService.dispose();
    super.dispose();
  }

  Future<void> _openFolder(String path) async {
    _rootPath = path;
    final files = await _treeService.allFilePaths(path);
    _paletteController.setFiles(files, path);
    if (mounted) setState(() {});
    await _lspService.initialize(path);
  }

  Future<void> _openFile(
    String path, {
    int? revealLine,
    int? revealCharacter,
  }) async {
    final existing = _tabController.tabs.indexWhere((t) => t.filePath == path);
    if (existing != -1) {
      _tabController.setActive(existing);
      if (revealLine != null) {
        _tabController.activeTab?.codeController.revealPosition(
          revealLine,
          character: revealCharacter ?? 0,
        );
      }
      return;
    }

    try {
      final content = await _fileService.readFile(path);
      _tabController.openFile(path, content, useParser: _useParser);
      _wireLsp(path, content);
      _wireParser(path, content);
      if (revealLine != null) {
        _tabController.activeTab?.codeController.revealPosition(
          revealLine,
          character: revealCharacter ?? 0,
        );
      }
    } catch (_) {}
  }

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

  void _wireParser(String path, String content) {
    final languageId = ParserService.languageIdFromPath(path);
    final tab = _tabController.tabs.firstWhere((t) => t.filePath == path);
    final available =
        languageId != null && _parserService.hasLanguage(languageId);
    tab.codeController.setParserAvailable(available);
    if (!available) return;

    _parserService.onHighlights(path, tab.codeController.setHighlightSpans);
    _parserService.openDocument(path, languageId, content);
  }

  void _closeParser(String path) {
    _parserService.removeHighlightsListener(path);
    _parserService.closeDocument(path);
  }

  void _closeLsp(String path) {
    _analyzers.remove(path)?.dispose();
    _autocompleters.remove(path)?.dispose();
    final languageId = LspService.languageIdFromPath(path);
    if (languageId != null) {
      _lspService.closeDocument(path, languageId);
    }
    _closeParser(path);
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

    final parserLanguageId = ParserService.languageIdFromPath(tab.filePath);
    if (parserLanguageId != null &&
        _parserService.hasLanguage(parserLanguageId)) {
      _parserService.scheduleUpdate(tab.filePath, tab.codeController.fullText);
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
    final (line, character) = offsetToLineChar(text, offset);
    final locations = await _lspService.getDefinition(
      tab.filePath,
      line,
      character,
    );
    if (locations.isEmpty) return;
    final loc = locations.first;
    final targetPath = Uri.parse(loc.uri).toFilePath();
    await _openFile(
      targetPath,
      revealLine: loc.range.start.line,
      revealCharacter: loc.range.start.character,
    );
  }

  Future<void> _findReferences() async {
    final tab = _tabController.activeTab;
    if (tab == null) return;
    final offset = tab.codeController.selection.baseOffset;
    if (offset < 0) return;
    final text = tab.codeController.fullText;
    final (line, character) = offsetToLineChar(text, offset);
    final locations = await _lspService.getReferences(
      tab.filePath,
      line,
      character,
    );
    if (locations.isEmpty) return;
    final loc = locations.first;
    final targetPath = Uri.parse(loc.uri).toFilePath();
    await _openFile(
      targetPath,
      revealLine: loc.range.start.line,
      revealCharacter: loc.range.start.character,
    );
  }

  Future<void> _formatDocument() async {
    final tab = _tabController.activeTab;
    if (tab == null) return;
    final text = tab.codeController.fullText;
    final formatted = await _lspService.formatDocumentText(tab.filePath, text);
    if (formatted == null || formatted == text) return;
    tab.codeController.text = formatted;
    _tabController.markDirty(_tabController.activeIndex);
    final languageId = LspService.languageIdFromPath(tab.filePath);
    if (languageId != null) {
      _lspService.scheduleChange(tab.filePath, languageId, formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
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
        const SingleActivator(LogicalKeyboardKey.escape): const _EscapeIntent(),
        const SingleActivator(LogicalKeyboardKey.f12):
            const _GoToDefinitionIntent(),
        const SingleActivator(LogicalKeyboardKey.f12, shift: true):
            const _FindReferencesIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, alt: true, shift: true):
            const _FormatIntent(),
      },
      child: Actions(
        actions: {
          _PaletteIntent: CallbackAction<_PaletteIntent>(
            onInvoke: (_) => _togglePalette(),
          ),
          _FileTreeIntent: CallbackAction<_FileTreeIntent>(
            onInvoke: (_) => setState(() => _showSidebar = !_showSidebar),
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
              }
              return null;
            },
          ),
          _GoToDefinitionIntent: CallbackAction<_GoToDefinitionIntent>(
            onInvoke: (_) => _goToDefinition(),
          ),
          _FindReferencesIntent: CallbackAction<_FindReferencesIntent>(
            onInvoke: (_) => _findReferences(),
          ),
          _FormatIntent: CallbackAction<_FormatIntent>(
            onInvoke: (_) => _formatDocument(),
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            backgroundColor: theme.editorBg,
            body: Stack(
              children: [
                Column(
                  children: [
                    IdeConceptsTitleBar(
                      theme: theme,
                      label: _rootPath != null
                          ? _rootPath!.split(Platform.pathSeparator).last
                          : 'Krom',
                      isDark: _isDark,
                      onToggleTheme: () => setState(() => _isDark = !_isDark),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (_showSidebar)
                            IdeConceptsSidebar(
                              theme: theme,
                              rootPath: _rootPath,
                              activeFilePath:
                                  _tabController.activeTab?.filePath,
                              onFileSelected: _openFile,
                            ),
                          Expanded(
                            child: Column(
                              children: [
                                IdeConceptsTabBar(
                                  theme: theme,
                                  controller: _tabController,
                                ),
                                Expanded(child: _buildEditorArea(theme)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _tabController,
                      builder: (context, _) => IdeConceptsStatusBar(
                        theme: theme,
                        activeTab: _tabController.activeTab,
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

  Widget _buildEditorArea(IdeConceptsTheme theme) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        final tab = _tabController.activeTab;
        if (tab == null) return _buildEmptyState(theme);
        return IdeConceptsCodeView(
          key: ValueKey(tab.filePath),
          theme: theme,
          tab: tab,
          lspService: _lspService,
          onChanged: _onEditorChanged,
        );
      },
    );
  }

  Widget _buildEmptyState(IdeConceptsTheme theme) {
    return Container(
      color: theme.editorBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Krom',
              style: TextStyle(
                color: theme.iconDim,
                fontSize: 40,
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
            const SizedBox(height: 32),
            _EmptyStateAction(
              theme: theme,
              label: 'Open File',
              shortcut: 'Ctrl+P',
              onTap: _togglePalette,
            ),
            const SizedBox(height: 8),
            _EmptyStateAction(
              theme: theme,
              label: 'Toggle File Tree',
              shortcut: 'Ctrl+B',
              onTap: () => setState(() => _showSidebar = !_showSidebar),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateAction extends StatefulWidget {
  const _EmptyStateAction({
    required this.theme,
    required this.label,
    required this.shortcut,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
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
    final theme = widget.theme;
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
            color: _hovered ? theme.rowActive : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
              Text(
                widget.shortcut,
                style: TextStyle(color: theme.iconDim, fontSize: 12),
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

class _FindReferencesIntent extends Intent {
  const _FindReferencesIntent();
}

class _FormatIntent extends Intent {
  const _FormatIntent();
}

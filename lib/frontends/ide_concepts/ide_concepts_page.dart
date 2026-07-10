import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../command_palette/palette_item.dart';
import '../../services/settings_service.dart';
import '../../editor/editor_session.dart';
import '../../utils/text_position.dart';
import 'go_to_line_dialog.dart';
import 'ide_concepts_theme.dart';
import 'ide_fonts.dart';
import 'widgets/code_view.dart';
import 'widgets/command_palette.dart';
import 'widgets/sidebar.dart';
import 'widgets/status_bar.dart';
import 'widgets/tab_bar.dart';
import 'widgets/title_bar.dart';

class IdeConceptsPage extends StatefulWidget {
  const IdeConceptsPage({
    super.key,
    required this.settings,
    required this.isDark,
    required this.onToggleTheme,
  });

  final SettingsService settings;
  final bool isDark;
  final Future<void> Function() onToggleTheme;

  @override
  State<IdeConceptsPage> createState() => _IdeConceptsPageState();
}

class _IdeConceptsPageState extends State<IdeConceptsPage> {
  late final EditorSession _session;
  final _focusNode = FocusNode();

  bool _showPalette = false;
  bool _showSidebar = true;
  bool _focusOn = false;

  IdeConceptsTheme get _theme => widget.isDark
      ? IdeConceptsTheme.midnightIndigo
      : IdeConceptsTheme.paperLight;

  @override
  void initState() {
    super.initState();
    _session = EditorSession(settings: widget.settings);
    _session.addListener(_onSessionChanged);
    _registerPaletteCommands();
    _session.initialize();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  void _registerPaletteCommands() {
    _session.paletteController.setCommands([
      const PaletteCommandItem(
        id: 'toggle-focus',
        label: 'Toggle Focus Mode',
        hint: 'view',
      ),
      const PaletteCommandItem(
        id: 'toggle-sidebar',
        label: 'Toggle Sidebar',
        hint: 'Ctrl+B',
      ),
      const PaletteCommandItem(
        id: 'toggle-theme',
        label: 'Switch Theme',
        hint: 'theme',
      ),
      const PaletteCommandItem(
        id: 'save-file',
        label: 'Save File',
        hint: 'Ctrl+S',
      ),
      const PaletteCommandItem(
        id: 'save-all',
        label: 'Save All',
        hint: 'Ctrl+Shift+S',
      ),
      const PaletteCommandItem(
        id: 'go-to-line',
        label: 'Go to Line…',
        hint: 'Ctrl+G',
      ),
      const PaletteCommandItem(
        id: 'format-document',
        label: 'Format Document',
        hint: 'Alt+Shift+F',
      ),
      const PaletteCommandItem(
        id: 'go-to-definition',
        label: 'Go to Definition',
        hint: 'F12',
      ),
      const PaletteCommandItem(
        id: 'find-references',
        label: 'Find References',
        hint: 'Shift+F12',
      ),
      const PaletteCommandItem(
        id: 'toggle-autosave',
        label: 'Toggle Autosave',
        hint: 'settings',
      ),
    ]);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _workspaceName =>
      _session.rootPath?.split(Platform.pathSeparator).last ?? 'Krom';

  String get _activePath {
    final tab = _session.tabController.activeTab;
    if (tab == null) return '';
    final root = _session.rootPath;
    if (root != null && tab.filePath.startsWith(root)) {
      return tab.filePath.substring(root.length + 1).replaceAll('\\', '/');
    }
    return p.basename(tab.filePath);
  }

  void _togglePalette() {
    setState(() {
      _showPalette = !_showPalette;
      if (_showPalette) _session.paletteController.updateQuery('');
    });
  }

  void _toggleFocus() => setState(() => _focusOn = !_focusOn);

  Future<void> _runPaletteCommand(String id) async {
    switch (id) {
      case 'toggle-focus':
        _toggleFocus();
      case 'toggle-sidebar':
        setState(() => _showSidebar = !_showSidebar);
      case 'toggle-theme':
        await widget.onToggleTheme();
      case 'save-file':
        await _session.saveActiveFile();
      case 'save-all':
        await _session.saveAllDirty();
      case 'go-to-line':
        await _promptGoToLine();
      case 'format-document':
        await _session.formatDocument();
      case 'go-to-definition':
        await _session.goToDefinition();
      case 'find-references':
        await _session.findReferences();
      case 'toggle-autosave':
        await widget.settings.setAutosave(!widget.settings.autosave);
        setState(() {});
    }
  }

  Future<void> _promptGoToLine() async {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    final offset = tab.codeController.selection.baseOffset;
    final text = tab.codeController.fullText;
    final safeOffset = offset.clamp(0, text.length);
    final (line, _) = offsetToLineChar(text, safeOffset);
    final target = await showGoToLineDialog(
      context,
      _theme,
      currentLine: line + 1,
    );
    if (target != null) _session.goToLine(target);
  }

  void _closeActiveTab() {
    _session.closeActiveTab();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            const _PaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            const _PaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            const _SidebarIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _SaveIntent(),
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ): const _SaveAllIntent(),
        const SingleActivator(LogicalKeyboardKey.keyW, control: true):
            const _CloseTabIntent(),
        const SingleActivator(LogicalKeyboardKey.tab, control: true):
            const _NextTabIntent(),
        const SingleActivator(
          LogicalKeyboardKey.tab,
          control: true,
          shift: true,
        ): const _PrevTabIntent(),
        const SingleActivator(LogicalKeyboardKey.keyG, control: true):
            const _GoToLineIntent(),
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
          _SidebarIntent: CallbackAction<_SidebarIntent>(
            onInvoke: (_) => setState(() => _showSidebar = !_showSidebar),
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) => _session.saveActiveFile(),
          ),
          _SaveAllIntent: CallbackAction<_SaveAllIntent>(
            onInvoke: (_) => _session.saveAllDirty(),
          ),
          _CloseTabIntent: CallbackAction<_CloseTabIntent>(
            onInvoke: (_) => _closeActiveTab(),
          ),
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) => _session.tabController.nextTab(),
          ),
          _PrevTabIntent: CallbackAction<_PrevTabIntent>(
            onInvoke: (_) => _session.tabController.previousTab(),
          ),
          _GoToLineIntent: CallbackAction<_GoToLineIntent>(
            onInvoke: (_) => _promptGoToLine(),
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              if (_showPalette) {
                setState(() => _showPalette = false);
              } else if (_focusOn) {
                setState(() => _focusOn = false);
              }
              return null;
            },
          ),
          _GoToDefinitionIntent: CallbackAction<_GoToDefinitionIntent>(
            onInvoke: (_) => _session.goToDefinition(),
          ),
          _FindReferencesIntent: CallbackAction<_FindReferencesIntent>(
            onInvoke: (_) => _session.findReferences(),
          ),
          _FormatIntent: CallbackAction<_FormatIntent>(
            onInvoke: (_) => _session.formatDocument(),
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
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      offset: _focusOn ? const Offset(0, -0.15) : Offset.zero,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 280),
                        opacity: _focusOn ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: _focusOn,
                          child: IdeConceptsTitleBar(
                            theme: theme,
                            workspaceName: _workspaceName,
                            activePath: _activePath,
                            isDark: widget.isDark,
                            focusOn: _focusOn,
                            onToggleFocus: _toggleFocus,
                            onOpenPalette: _togglePalette,
                            onToggleTheme: () => widget.onToggleTheme(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            width: _showSidebar && !_focusOn ? 236 : 0,
                            child: _showSidebar && !_focusOn
                                ? IdeConceptsSidebar(
                                    theme: theme,
                                    rootPath: _session.rootPath,
                                    activeFilePath: _session
                                        .tabController.activeTab?.filePath,
                                    gitStatus: _session.gitStatus,
                                    onFileSelected: _session.openFile,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                AnimatedSlide(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  offset: _focusOn
                                      ? const Offset(0, -0.15)
                                      : Offset.zero,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 280),
                                    opacity: _focusOn ? 0 : 1,
                                    child: IgnorePointer(
                                      ignoring: _focusOn,
                                      child: IdeConceptsTabBar(
                                        theme: theme,
                                        controller: _session.tabController,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(child: _buildEditorArea(theme)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _session.tabController,
                      builder: (context, _) => IdeConceptsStatusBar(
                        theme: theme,
                        activeTab: _session.tabController.activeTab,
                        focusOn: _focusOn,
                        autosaveOn: widget.settings.autosave,
                        onExitFocus: _toggleFocus,
                      ),
                    ),
                  ],
                ),
                if (_showPalette)
                  IdeConceptsCommandPalette(
                    theme: theme,
                    controller: _session.paletteController,
                    onCommand: _runPaletteCommand,
                    onFileSelected: _session.openFile,
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
      listenable: _session.tabController,
      builder: (context, _) {
        final tab = _session.tabController.activeTab;
        if (tab == null) return _buildEmptyState(theme);
        return IdeConceptsCodeView(
          key: ValueKey(tab.filePath),
          theme: theme,
          tab: tab,
          focusOn: _focusOn,
          lspService: _session.lspService,
          onChanged: _session.onEditorChanged,
        );
      },
    );
  }

  Widget _buildEmptyState(IdeConceptsTheme theme) {
    return Container(
      color: theme.editorBg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Krom',
                style: IdeFonts.mono(
                  color: theme.iconDim,
                  fontSize: 40,
                  weight: FontWeight.w300,
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
                label: 'Toggle Sidebar',
                shortcut: 'Ctrl+B',
                onTap: () => setState(() => _showSidebar = !_showSidebar),
              ),
              const SizedBox(height: 8),
              _EmptyStateAction(
                theme: theme,
                label: 'Focus Mode',
                shortcut: 'palette',
                onTap: _toggleFocus,
              ),
            ],
          ),
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
                style: IdeFonts.mono(color: theme.muted, fontSize: 14),
              ),
              Text(
                widget.shortcut,
                style: IdeFonts.mono(color: theme.iconDim, fontSize: 12),
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

class _SidebarIntent extends Intent {
  const _SidebarIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _SaveAllIntent extends Intent {
  const _SaveAllIntent();
}

class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PrevTabIntent extends Intent {
  const _PrevTabIntent();
}

class _GoToLineIntent extends Intent {
  const _GoToLineIntent();
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

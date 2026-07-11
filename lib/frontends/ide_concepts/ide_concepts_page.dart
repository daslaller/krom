import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../command_palette/palette_item.dart';
import 'package:lsp_client/lsp_client.dart';
import '../../editor/find_replace.dart';
import '../../editor/multi_cursor.dart';
import '../../editor/structural_selection.dart';
import '../../services/problems_collector.dart';
import '../../services/workspace_search_service.dart';
import '../../services/settings_service.dart';
import '../../editor/editor_session.dart';
import '../../utils/text_position.dart';
import 'go_to_line_dialog.dart';
import 'ide_concepts_theme.dart';
import 'ide_concepts_themes.dart';
import 'ide_fonts.dart';
import 'krom_motion.dart';
import 'rename_dialog.dart';
import 'widgets/code_view.dart';
import 'widgets/command_palette.dart';
import 'widgets/find_replace_bar.dart';
import 'widgets/outline_panel.dart';
import 'widgets/sidebar.dart';
import 'widgets/status_bar.dart';
import 'widgets/code_actions_menu.dart';
import 'widgets/problems_panel.dart';
import 'widgets/split_editor.dart';
import 'widgets/tab_bar.dart';
import 'widgets/workspace_search_panel.dart';
import 'widgets/theme_picker.dart';
import 'widgets/title_bar.dart';

class IdeConceptsPage extends StatefulWidget {
  const IdeConceptsPage({
    super.key,
    required this.settings,
    required this.themeId,
    required this.onCycleTheme,
    required this.onSetTheme,
  });

  final SettingsService settings;
  final String themeId;
  final Future<void> Function() onCycleTheme;
  final Future<void> Function(String themeId) onSetTheme;

  @override
  State<IdeConceptsPage> createState() => _IdeConceptsPageState();
}

class _IdeConceptsPageState extends State<IdeConceptsPage> {
  late final EditorSession _session;
  final _focusNode = FocusNode();
  late final StructuralSelection _structuralSelection;
  final _findReplace = FindReplaceController();

  bool _showPalette = false;
  bool _showSidebar = true;
  bool _showOutline = false;
  bool _showFindBar = false;
  bool _findReplaceMode = false;
  bool _showThemePicker = false;
  bool _showWorkspaceSearch = false;
  bool _showProblems = false;
  bool _showCodeActions = false;
  bool _focusOn = false;
  SplitDirection _splitDirection = SplitDirection.none;
  int? _secondaryTabIndex;
  List<LspCodeAction> _codeActions = const [];
  String _initialFindQuery = '';

  IdeConceptsTheme get _theme => IdeConceptsThemes.resolve(widget.themeId);

  @override
  void initState() {
    super.initState();
    _session = EditorSession(settings: widget.settings);
    _structuralSelection = StructuralSelection(parserService: _session.parserService);
    _session.addListener(_onSessionChanged);
    _session.tabController.addListener(_onTabChanged);
    _registerPaletteCommands();
    _session.initialize();
  }

  void _onTabChanged() => _structuralSelection.clear();

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  void _registerPaletteCommands() {
    _session.paletteController.setCommands([
      const PaletteCommandItem(
        id: 'pick-theme',
        label: 'Pick Theme…',
        hint: 'appearance',
      ),
      const PaletteCommandItem(
        id: 'find-in-file',
        label: 'Find in File',
        hint: 'Ctrl+F',
      ),
      const PaletteCommandItem(
        id: 'replace-in-file',
        label: 'Replace in File',
        hint: 'Ctrl+H',
      ),
      const PaletteCommandItem(
        id: 'rename-symbol',
        label: 'Rename Symbol',
        hint: 'F2',
      ),
      const PaletteCommandItem(
        id: 'toggle-outline',
        label: 'Toggle Outline',
        hint: 'Ctrl+Shift+O',
      ),
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
        id: 'cycle-theme',
        label: 'Cycle Theme',
        hint: 'theme',
      ),
      ...IdeConceptsThemes.all.map(
        (entry) => PaletteCommandItem(
          id: 'theme:${entry.id}',
          label: 'Theme: ${entry.theme.name}',
          hint: 'appearance',
        ),
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
        id: 'workspace-search', label: 'Workspace Search', hint: 'Ctrl+Shift+F'),
      const PaletteCommandItem(id: 'toggle-problems', label: 'Toggle Problems', hint: 'Ctrl+Shift+M'),
      const PaletteCommandItem(id: 'code-actions', label: 'Code Actions', hint: 'Ctrl+.'),
      const PaletteCommandItem(id: 'split-horizontal', label: 'Split Editor Horizontal', hint: 'view'),
      const PaletteCommandItem(id: 'split-vertical', label: 'Split Editor Vertical', hint: 'view'),
      const PaletteCommandItem(id: 'unsplit', label: 'Close Split Editor', hint: 'view'),
      const PaletteCommandItem(
        id: 'toggle-autosave',
        label: 'Toggle Autosave',
        hint: 'settings',
      ),
    ]);
  }

  @override
  void dispose() {
    _session.tabController.removeListener(_onTabChanged);
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    _focusNode.dispose();
    _findReplace.dispose();
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

  void _toggleOutline() => setState(() => _showOutline = !_showOutline);

  void _openFind({bool replace = false}) {
    final tab = _session.tabController.activeTab;
    var query = '';
    if (tab != null) {
      final sel = tab.codeController.selection;
      if (sel.isValid && !sel.isCollapsed) {
        final selected = tab.codeController.fullText
            .substring(sel.start, sel.end.clamp(0, tab.codeController.fullText.length));
        if (selected.isNotEmpty && !selected.contains('\n') && selected.length < 80) {
          query = selected;
        }
      }
    }
    setState(() {
      _findReplaceMode = replace;
      _showFindBar = true;
      _initialFindQuery = query;
      if (query.isNotEmpty) _findReplace.setQuery(query);
    });
    _refreshFind();
  }

  void _closeFindBar() => setState(() => _showFindBar = false);

  void _selectCurrentMatch() {
    final tab = _session.tabController.activeTab;
    final match = _findReplace.currentMatch;
    if (tab == null || match == null) return;
    tab.codeController.selection =
        TextSelection(baseOffset: match.start, extentOffset: match.end);
  }

  void _refreshFind() {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    _findReplace.findIn(
      tab.codeController.fullText,
      startFrom: tab.codeController.selection.start,
    );
    _selectCurrentMatch();
    setState(() {});
  }

  void _findNext() {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    _findReplace.findIn(tab.codeController.fullText);
    _findReplace.next();
    _selectCurrentMatch();
    setState(() {});
  }

  void _findPrevious() {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    _findReplace.findIn(tab.codeController.fullText);
    _findReplace.previous();
    _selectCurrentMatch();
    setState(() {});
  }

  void _replaceCurrent() {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    final updated = _findReplace.replaceCurrent(tab.codeController.fullText);
    if (updated != null) {
      tab.codeController.text = updated;
      _session.onEditorChanged();
      _selectCurrentMatch();
      setState(() {});
    }
  }

  void _replaceAll() {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    final updated = _findReplace.replaceAll(tab.codeController.fullText);
    if (updated != null) {
      tab.codeController.text = updated;
      _session.onEditorChanged();
      setState(() {});
    }
  }

  Future<void> _promptRename() async {
    final placeholder = await _session.prepareRenamePlaceholder();
    if (!mounted) return;
    final newName = await showRenameDialog(
      context,
      _theme,
      initialName: placeholder,
    );
    if (newName != null) await _session.renameSymbol(newName);
  }

  void _openThemePicker() => setState(() => _showThemePicker = true);

  Future<void> _runPaletteCommand(String id) async {
    switch (id) {
      case 'pick-theme':
        _openThemePicker();
      case 'find-in-file':
        _openFind();
      case 'replace-in-file':
        _openFind(replace: true);
      case 'rename-symbol':
        await _promptRename();
      case 'toggle-outline':
        _toggleOutline();
      case 'toggle-focus':
        _toggleFocus();
      case 'toggle-sidebar':
        setState(() => _showSidebar = !_showSidebar);
      case 'cycle-theme':
        await widget.onCycleTheme();
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
      case 'find-references': await _session.findReferences();
      case 'workspace-search': setState(() => _showWorkspaceSearch = !_showWorkspaceSearch);
      case 'toggle-problems': setState(() => _showProblems = !_showProblems);
      case 'code-actions': await _showCodeActionsMenu();
      case 'split-horizontal': setState(() => _splitDirection = SplitDirection.horizontal);
      case 'split-vertical': setState(() => _splitDirection = SplitDirection.vertical);
      case 'unsplit': setState(() { _splitDirection = SplitDirection.none; _secondaryTabIndex = null; });
      case 'toggle-autosave':
        await widget.settings.setAutosave(!widget.settings.autosave);
        setState(() {});
      default:
        if (id.startsWith('theme:')) {
          await widget.onSetTheme(id.substring('theme:'.length));
        }
    }
  }

  Future<void> _expandSelection() async {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    await _structuralSelection.expand(tab.codeController);
  }

  void _shrinkSelection() {
    final tab = _session.tabController.activeTab;
    if (tab == null) return;
    _structuralSelection.shrink(tab.codeController);
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

  
  void _toggleWorkspaceSearch() => setState(() => _showWorkspaceSearch = !_showWorkspaceSearch);
  void _toggleProblems() => setState(() => _showProblems = !_showProblems);
  void _addNextOccurrence() { final t=_session.tabController.activeTab; if(t==null)return; MultiCursorController(t.codeController).addNextOccurrence(); setState((){}); }
  void _selectAllOccurrences() { final t=_session.tabController.activeTab; if(t==null)return; MultiCursorController(t.codeController).selectAllOccurrences(); setState((){}); }
  Future<void> _showCodeActionsMenu() async { final a=await _session.getCodeActions(); if(!mounted)return; setState((){ _codeActions=a; _showCodeActions=true; }); }
  Future<void> _applyCodeAction(LspCodeAction action) async { setState(()=>_showCodeActions=false); if(action.edit!=null) await _session.applyWorkspaceEdit(action.edit!); }
  void _openProblem(ProblemEntry e) => _session.openFile(e.filePath, revealLine: e.line);
  void _openSearchMatch(WorkspaceSearchMatch m) => _session.openFile(m.path, revealLine: m.line-1);
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
        const SingleActivator(LogicalKeyboardKey.keyO, control: true, shift: true):
            const _OutlineIntent(),
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
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const _FindIntent(),
        const SingleActivator(LogicalKeyboardKey.keyH, control: true):
            const _ReplaceIntent(),
        const SingleActivator(LogicalKeyboardKey.f2): const _RenameIntent(),
        const SingleActivator(LogicalKeyboardKey.f3): const _FindNextIntent(),
        const SingleActivator(LogicalKeyboardKey.f3, shift: true):
            const _FindPrevIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const _EscapeIntent(),
        const SingleActivator(LogicalKeyboardKey.f12):
            const _GoToDefinitionIntent(),
        const SingleActivator(LogicalKeyboardKey.f12, shift: true):
            const _FindReferencesIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, alt: true, shift: true):
            const _FormatIntent(),
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
        const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true): const _WorkspaceSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyM, control: true, shift: true): const _ProblemsIntent(),
        const SingleActivator(LogicalKeyboardKey.period, control: true): const _CodeActionsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): const _AddSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyL, control: true, shift: true): const _SelectAllOccurrencesIntent(),
      },
      child: Actions(
        actions: {
          _PaletteIntent: CallbackAction<_PaletteIntent>(
            onInvoke: (_) => _togglePalette(),
          ),
          _SidebarIntent: CallbackAction<_SidebarIntent>(
            onInvoke: (_) => setState(() => _showSidebar = !_showSidebar),
          ),
          _OutlineIntent: CallbackAction<_OutlineIntent>(
            onInvoke: (_) => _toggleOutline(),
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
          _FindIntent: CallbackAction<_FindIntent>(
            onInvoke: (_) => _openFind(),
          ),
          _ReplaceIntent: CallbackAction<_ReplaceIntent>(
            onInvoke: (_) => _openFind(replace: true),
          ),
          _RenameIntent: CallbackAction<_RenameIntent>(
            onInvoke: (_) {
              _promptRename();
              return null;
            },
          ),
          _FindNextIntent: CallbackAction<_FindNextIntent>(
            onInvoke: (_) {
              if (!_showFindBar) _openFind();
              _findNext();
              return null;
            },
          ),
          _FindPrevIntent: CallbackAction<_FindPrevIntent>(
            onInvoke: (_) {
              if (!_showFindBar) _openFind();
              _findPrevious();
              return null;
            },
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              if (_showPalette) {
                setState(() => _showPalette = false);
              } else if (_showCodeActions) IdeConceptsCodeActionsMenu(theme: theme, actions: _codeActions, onSelect: _applyCodeAction, onDismiss: () => setState(() => _showCodeActions = false)),
                if (_showThemePicker) {
                setState(() => _showThemePicker = false);
              } else if (_showFindBar) { _closeFindBar(); } else if (_showCodeActions) { setState(() => _showCodeActions = false); } else if (_showWorkspaceSearch) { setState(() => _showWorkspaceSearch = false); } else if (_showProblems) { setState(() => _showProblems = false); } else if (_showOutline) {
                setState(() => _showOutline = false);
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
          _ExpandSelectionIntent: CallbackAction<_ExpandSelectionIntent>(
            onInvoke: (_) {
              _expandSelection();
              return null;
            },
          ),
          _ShrinkSelectionIntent: CallbackAction<_ShrinkSelectionIntent>(onInvoke: (_){_shrinkSelection();return null;}),
          _WorkspaceSearchIntent: CallbackAction<_WorkspaceSearchIntent>(onInvoke: (_){_toggleWorkspaceSearch();return null;}),
          _ProblemsIntent: CallbackAction<_ProblemsIntent>(onInvoke: (_){_toggleProblems();return null;}),
          _CodeActionsIntent: CallbackAction<_CodeActionsIntent>(onInvoke: (_){_showCodeActionsMenu();return null;}),
          _AddSelectionIntent: CallbackAction<_AddSelectionIntent>(onInvoke: (_){_addNextOccurrence();return null;}),
          _SelectAllOccurrencesIntent: CallbackAction<_SelectAllOccurrencesIntent>(onInvoke: (_){_selectAllOccurrences();return null;}),
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
                            focusOn: _focusOn,
                            onToggleFocus: _toggleFocus,
                            onOpenPalette: _togglePalette,
                            onToggleTheme: () => widget.onCycleTheme(),
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
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _buildEditorArea(theme)),
                                          AnimatedContainer(
                                            duration: KromMotion.panelDuration,
                                            curve: KromMotion.panelCurve,
                                            width: _showOutline && !_focusOn
                                                ? 240
                                                : 0,
                                            child: _showOutline && !_focusOn
                                                ? IdeConceptsOutlinePanel(
                                                    theme: theme,
                                                    tabController:
                                                        _session.tabController,
                                                    lspService:
                                                        _session.lspService,
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      ),
                                      if ((_showWorkspaceSearch || _showProblems) && !_focusOn) Positioned(left:0,right:0,bottom:0,child:Column(mainAxisSize:MainAxisSize.min,children:[if(_showWorkspaceSearch)SizedBox(height:220,child:IdeConceptsWorkspaceSearchPanel(theme:theme,rootPath:_session.rootPath,onOpenMatch:_openSearchMatch,onClose:()=>setState(()=>_showWorkspaceSearch=false))),if(_showProblems)SizedBox(height:220,child:IdeConceptsProblemsPanel(theme:theme,collector:_session.problemsCollector,onOpenProblem:_openProblem,onClose:()=>setState(()=>_showProblems=false))),])),
                                      if (_showFindBar && !_focusOn)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: ListenableBuilder(
                                            listenable: _findReplace,
                                            builder: (context, _) =>
                                                IdeConceptsFindReplaceBar(
                                              key: ValueKey(_initialFindQuery),
                                              theme: theme,
                                              controller: _findReplace,
                                              showReplace: _findReplaceMode,
                                              initialFind: _initialFindQuery,
                                              onFind: _refreshFind,
                                              onNext: _findNext,
                                              onPrevious: _findPrevious,
                                              onReplace: _replaceCurrent,
                                              onReplaceAll: _replaceAll,
                                              onClose: _closeFindBar,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
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
                        errorCount: _session.problemsCollector.errorCount,
                        warningCount: _session.problemsCollector.warningCount,
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
                if (_showCodeActions) IdeConceptsCodeActionsMenu(theme: theme, actions: _codeActions, onSelect: _applyCodeAction, onDismiss: () => setState(() => _showCodeActions = false)),
                if (_showThemePicker)
                  IdeConceptsThemePicker(
                    theme: theme,
                    activeThemeId: widget.themeId,
                    onSelect: (id) async {
                      await widget.onSetTheme(id);
                      if (mounted) setState(() => _showThemePicker = false);
                    },
                    onDismiss: () => setState(() => _showThemePicker = false),
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
        if (_splitDirection != SplitDirection.none) { return SplitEditorView(theme: theme, tabController: _session.tabController, direction: _splitDirection, focusOn: _focusOn, lspService: _session.lspService, onChanged: _session.onEditorChanged, onSignatureHelp: _session.getSignatureHelp, secondaryIndex: _secondaryTabIndex); }
        return IdeConceptsCodeView(key: ValueKey(tab.filePath), theme: theme, tab: tab, focusOn: _focusOn, lspService: _session.lspService, onChanged: _session.onEditorChanged, onSignatureHelp: _session.getSignatureHelp);
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
                label: 'Toggle Outline',
                shortcut: 'Ctrl+Shift+O',
                onTap: _toggleOutline,
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
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: IdeFonts.mono(color: theme.muted, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
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

class _OutlineIntent extends Intent {
  const _OutlineIntent();
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

class _FindIntent extends Intent {
  const _FindIntent();
}

class _ReplaceIntent extends Intent {
  const _ReplaceIntent();
}

class _RenameIntent extends Intent {
  const _RenameIntent();
}

class _FindNextIntent extends Intent {
  const _FindNextIntent();
}

class _FindPrevIntent extends Intent {
  const _FindPrevIntent();
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

class _ExpandSelectionIntent extends Intent {
  const _ExpandSelectionIntent();
}

class _ShrinkSelectionIntent extends Intent { const _ShrinkSelectionIntent(); }
class _WorkspaceSearchIntent extends Intent { const _WorkspaceSearchIntent(); }
class _ProblemsIntent extends Intent { const _ProblemsIntent(); }
class _CodeActionsIntent extends Intent { const _CodeActionsIntent(); }
class _AddSelectionIntent extends Intent { const _AddSelectionIntent(); }
class _SelectAllOccurrencesIntent extends Intent { const _SelectAllOccurrencesIntent(); }

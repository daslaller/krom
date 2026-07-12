import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lsp_client/lsp_client.dart';
import 'package:path/path.dart' as p;

import '../command_palette/command_palette_controller.dart';
import '../command_palette/palette_item.dart';
import '../extensions/extension_manifest.dart';
import '../panels/file_tree/file_tree_service.dart';
import '../services/file_service.dart';
import '../services/file_watcher_service.dart';
import '../services/ghost_completion_service.dart';
import '../services/git_service.dart';
import '../services/live_share_service.dart';
import '../services/lsp_service.dart';
import '../services/parser_service.dart';
import '../services/problems_collector.dart';
import '../services/settings_service.dart';
import '../utils/text_position.dart';
import 'krom_analyzer.dart';
import 'krom_autocompleter.dart';
import 'navigation_pulse.dart';
import 'tab_controller.dart';

/// Shared editor backend: tabs, LSP, parser, saves, and navigation.
///
/// Frontends (IDE Concepts, legacy shell) render UI; this class owns behavior.
class EditorSession extends ChangeNotifier {
  EditorSession({SettingsService? settings})
      : settings = settings ?? SettingsService(),
        tabController = KromTabController(),
        paletteController = CommandPaletteController(),
        fileService = FileService(),
        treeService = FileTreeService(),
        gitService = GitService(),
        fileWatcher = FileWatcherService() {
    lspService = LspService(this.settings);
    parserService = ParserService(this.settings);
    ghostCompletionService =
        GhostCompletionService(settings: this.settings);
    liveShareService = LiveShareService();
    fileWatcher.onExternalChange = _onExternalFileChange;
  }

  final SettingsService settings;
  final KromTabController tabController;
  final CommandPaletteController paletteController;
  final FileService fileService;
  final FileTreeService treeService;
  final GitService gitService;
  final FileWatcherService fileWatcher;
  late final LspService lspService;
  late final ParserService parserService;
  final ProblemsCollector problemsCollector = ProblemsCollector();
  late final GhostCompletionService ghostCompletionService;
  late final LiveShareService liveShareService;

  final Map<String, KromAnalyzer> _analyzers = {};
  final Map<String, KromAutocompleter> _autocompleters = {};
  final Map<String, FileDiffMarkers> _diffByPath = {};
  final Map<String, Map<int, BlameLine>> _blameByPath = {};
  final Set<String> _pendingExternalChanges = {};
  final List<ExtensionManifest> _extensions = [];

  String? rootPath;
  GitStatus gitStatus = const GitStatus();
  bool useParser = true;
  final NavigationPulse navigationPulse = NavigationPulse();
  bool showBlame = false;
  BlameLine? hoveredBlame;
  Timer? _autosaveTimer;
  Timer? _gitRefreshTimer;
  FileDiffMarkers diffForPath(String p) => _diffByPath[p] ?? const FileDiffMarkers();
  Map<int, BlameLine> blameForPath(String p) => _blameByPath[p] ?? {};
  Set<String> get pendingExternalChanges => Set.unmodifiable(_pendingExternalChanges);
  List<PaletteCommandItem> extensionPaletteCommands() { final o=<PaletteCommandItem>[]; for(final e in _extensions){for(final c in e.commands){o.add(PaletteCommandItem(id:c.paletteId(e.id),label:c.label,hint:c.hint??e.name));}} return o; }
  Future<void> runExtensionCommand(String id) async { if(!id.startsWith('ext:'))return; final p=id.split(':'); if(p.length<3)return; for(final e in _extensions){if(e.id!=p[1])continue; for(final c in e.commands){if(c.id==p.sublist(2).join(':')) await ExtensionLoader.runCommandAction(e,c);}} }
  Future<void> refreshGitDecorations() async { _diffByPath.clear(); if(rootPath==null)return; for(final t in tabController.tabs){final m=await gitService.diffMarkers(rootPath,t.filePath); if(!m.isEmpty)_diffByPath[t.filePath]=m;} if(showBlame){_blameByPath.clear(); for(final t in tabController.tabs)_blameByPath[t.filePath]=await gitService.blame(rootPath,t.filePath);} notifyListeners(); }
  Future<void> toggleBlame() async { showBlame=!showBlame; if(showBlame) await refreshGitDecorations(); else {_blameByPath.clear(); hoveredBlame=null;} notifyListeners(); }
  void setHoveredBlame(BlameLine? l){if(hoveredBlame==l)return; hoveredBlame=l; notifyListeners();}
  Future<bool> stageActiveFile() async { final t=tabController.activeTab; if(t==null||rootPath==null)return false; final ok=await gitService.stageFile(rootPath,t.filePath); if(ok){await refreshGitStatus(); await refreshGitDecorations();} return ok; }
  void _scheduleGitRefresh(){_gitRefreshTimer?.cancel(); _gitRefreshTimer=Timer(const Duration(milliseconds:500),(){refreshGitDecorations(); refreshGitStatus();});}
  void _onExternalFileChange(Set<String> paths){for(final path in paths){final i=tabController.tabs.indexWhere((t)=>t.filePath==path); if(i>=0&&!tabController.tabs[i].isDirty)_pendingExternalChanges.add(path);} if(_pendingExternalChanges.isNotEmpty)notifyListeners();}
  void dismissExternalChange(String path){_pendingExternalChanges.remove(path); notifyListeners();}
  Future<void> reloadFileFromDisk(String path) async {_pendingExternalChanges.remove(path); final i=tabController.tabs.indexWhere((t)=>t.filePath==path); if(i<0)return; try{final c=await fileService.readFile(path); final t=tabController.tabs[i]; t.codeController.text=c; t.content=c; tabController.markClean(i); final lid=LspService.languageIdFromPath(path); if(lid!=null)lspService.scheduleChange(path,lid,c); await refreshGitDecorations(); notifyListeners();}catch(_){}}
  String relativePath(String path){final r=rootPath; if(r!=null&&path.startsWith(r))return path.substring(r.length+1).replaceAll('\\','/'); return p.basename(path);}

  Future<void> initialize() async {
    final cwd=Directory.current.path;
    await settings.load(workspaceRoot: cwd);
    useParser = settings.useTreeSitter;
    await parserService.initialize();
    _extensions.addAll(await ExtensionLoader.loadAll());
    await openFolder(cwd);
  }

  Future<void> openFolder(String path) async {
    rootPath = path;
    await settings.loadProjectOverrides(path);
    useParser = settings.useTreeSitter;
    final files = await treeService.allFilePaths(path);
    paletteController.setFiles(files, path);
    gitStatus = await gitService.status(path);
    fileWatcher.watch(path);
    notifyListeners();
    await lspService.initialize(path);
    await refreshGitDecorations();
  }

  Future<void> refreshGitStatus() async {
    gitStatus = await gitService.status(rootPath);
    notifyListeners();
  }

  Future<void> openFile(
    String path, {
    int? revealLine,
    int? revealCharacter,
  }) async {
    final existing = tabController.tabs.indexWhere((t) => t.filePath == path);
    if (existing != -1) {
      tabController.setActive(existing);
      if (revealLine != null) {
        tabController.activeTab?.codeController.revealPosition(
          revealLine,
          character: revealCharacter ?? 0,
        );
        navigationPulse.pulse(revealLine);
      }
      paletteController.noteRecentFile(path);
      notifyListeners();
      return;
    }

    try {
      final content = await fileService.readFile(path);
      tabController.openFile(path, content, useParser: useParser);
      _wireLsp(path, content);
      _wireParser(path, content);
      paletteController.noteRecentFile(path);
      if (revealLine != null) {
        tabController.activeTab?.codeController.revealPosition(
          revealLine,
          character: revealCharacter ?? 0,
        );
        navigationPulse.pulse(revealLine);
      }
      _scheduleGitRefresh();
      if(showBlame)_blameByPath[path]=await gitService.blame(rootPath,path);
      notifyListeners();
    } catch (_) {}
  }

  void _wireLsp(String path, String content) {
    final languageId = LspService.languageIdFromPath(path);
    if (languageId == null) return;

    final tab = tabController.tabs.firstWhere((t) => t.filePath == path);

    final analyzer = KromAnalyzer(
      lspService: lspService,
      filePath: path,
      problemsCollector: problemsCollector,
      onNewDiagnostics: () => tab.codeController.analyzeCode(),
    );
    _analyzers[path] = analyzer;
    tab.codeController.analyzer = analyzer;

    final autocompleter = KromAutocompleter(
      lspService: lspService,
      filePath: path,
    );
    _autocompleters[path] = autocompleter;

    lspService.openDocument(path, languageId, content);
  }

  void _wireParser(String path, String content) {
    final languageId = ParserService.languageIdFromPath(path);
    final tab = tabController.tabs.firstWhere((t) => t.filePath == path);
    final available =
        languageId != null && parserService.hasLanguage(languageId);
    tab.codeController.setParserAvailable(available);
    if (!available) return;

    parserService.onHighlights(path, tab.codeController.setHighlightSpans);
    parserService.openDocument(path, languageId, content);
  }

  void _closeParser(String path) {
    parserService.removeHighlightsListener(path);
    parserService.closeDocument(path);
  }

  void _closeLsp(String path) {
    _analyzers.remove(path)?.dispose();
    _autocompleters.remove(path)?.dispose();
    problemsCollector.remove(path);
    final languageId = LspService.languageIdFromPath(path);
    if (languageId != null) {
      lspService.closeDocument(path, languageId);
    }
    _closeParser(path);
    _diffByPath.remove(path);
    _blameByPath.remove(path);
  }

  Future<void> saveFileAt(int index) async {
    if (index < 0 || index >= tabController.tabs.length) return;
    final tab = tabController.tabs[index];
    if (!tab.isDirty) return;
    final content = tab.codeController.fullText;
    await fileService.writeFile(tab.filePath, content);
    tab.content = content;
    tabController.markClean(index);
    await refreshGitStatus();
    _scheduleGitRefresh();
    notifyListeners();
  }

  Future<void> saveActiveFile() => saveFileAt(tabController.activeIndex);

  Future<void> saveAllDirty() async {
    for (var i = 0; i < tabController.tabs.length; i++) {
      if (tabController.tabs[i].isDirty) {
        await saveFileAt(i);
      }
    }
  }

  void onEditorChanged() {
    final tab = tabController.activeTab;
    if (tab == null) return;
    tabController.markDirty(tabController.activeIndex);

    final languageId = LspService.languageIdFromPath(tab.filePath);
    if (languageId != null) {
      lspService.scheduleChange(
        tab.filePath,
        languageId,
        tab.codeController.fullText,
      );
    }

    final parserLanguageId = ParserService.languageIdFromPath(tab.filePath);
    if (parserLanguageId != null &&
        parserService.hasLanguage(parserLanguageId)) {
      parserService.scheduleUpdate(tab.filePath, tab.codeController.fullText);
    }
    _autocompleters[tab.filePath]?.onChanged(tab.codeController);

    if (settings.autosave) {
      _autosaveTimer?.cancel();
      _autosaveTimer = Timer(const Duration(seconds: 2), saveActiveFile);
    }
    _scheduleGitRefresh();
    notifyListeners();
  }

  void closeTabAt(int index) {
    if (index < 0 || index >= tabController.tabs.length) return;
    final path = tabController.tabs[index].filePath;
    tabController.closeTab(index);
    _closeLsp(path);
    _pendingExternalChanges.remove(path);
    notifyListeners();
  }

  void closeActiveTab() => closeTabAt(tabController.activeIndex);

  Future<void> goToDefinition() async {
    final tab = tabController.activeTab;
    if (tab == null) return;
    final offset = tab.codeController.selection.baseOffset;
    if (offset < 0) return;
    final text = tab.codeController.fullText;
    final (line, character) = offsetToLineChar(text, offset);
    final locations = await lspService.getDefinition(
      tab.filePath,
      line,
      character,
    );
    if (locations.isEmpty) return;
    final loc = locations.first;
    await openFile(
      Uri.parse(loc.uri).toFilePath(),
      revealLine: loc.range.start.line,
      revealCharacter: loc.range.start.character,
    );
  }

  Future<void> findReferences() async {
    final tab = tabController.activeTab;
    if (tab == null) return;
    final offset = tab.codeController.selection.baseOffset;
    if (offset < 0) return;
    final text = tab.codeController.fullText;
    final (line, character) = offsetToLineChar(text, offset);
    await openReferencesAt(line, character);
  }

  Future<void> openReferencesAt(int line, int character) async {
    final tab = tabController.activeTab;
    if (tab == null) return;
    final locations = await lspService.getReferences(
      tab.filePath,
      line,
      character,
    );
    if (locations.isEmpty) return;
    final loc = locations.first;
    await openFile(
      Uri.parse(loc.uri).toFilePath(),
      revealLine: loc.range.start.line,
      revealCharacter: loc.range.start.character,
    );
  }

  Future<void> formatDocument() async {
    final tab = tabController.activeTab;
    if (tab == null) return;
    final text = tab.codeController.fullText;
    final formatted = await lspService.formatDocumentText(tab.filePath, text);
    if (formatted == null || formatted == text) return;
    tab.codeController.text = formatted;
    tabController.markDirty(tabController.activeIndex);
    final languageId = LspService.languageIdFromPath(tab.filePath);
    if (languageId != null) {
      lspService.scheduleChange(tab.filePath, languageId, formatted);
    }
    notifyListeners();
  }

  void goToLine(int line) {
    final tab = tabController.activeTab;
    if (tab == null) return;
    final clamped = line.clamp(0, 1 << 20);
    tab.codeController.revealPosition(clamped);
    navigationPulse.pulse(clamped);
    notifyListeners();
  }

  /// Applies an LSP workspace edit to open tabs and files on disk.
  Future<void> applyWorkspaceEdit(LspWorkspaceEdit edit) async {
    for (final entry in edit.changes.entries) {
      final path = Uri.parse(entry.key).toFilePath();
      final edits = entry.value;
      final index = tabController.tabs.indexWhere((t) => t.filePath == path);
      if (index >= 0) {
        final tab = tabController.tabs[index];
        final updated = applyTextEdits(tab.codeController.fullText, edits);
        if (updated != tab.codeController.fullText) {
          tab.codeController.text = updated;
          tabController.markDirty(index);
          final languageId = LspService.languageIdFromPath(path);
          if (languageId != null) {
            lspService.scheduleChange(path, languageId, updated);
          }
        }
      } else {
        try {
          final content = await fileService.readFile(path);
          final updated = applyTextEdits(content, edits);
          if (updated != content) {
            await fileService.writeFile(path, updated);
          }
        } catch (_) {}
      }
    }
    await refreshGitStatus();
    _scheduleGitRefresh();
    notifyListeners();
  }

  /// Renames the symbol at the cursor via LSP. Returns false if rename failed.
  Future<bool> renameSymbol(String newName) async {
    final tab = tabController.activeTab;
    if (tab == null || newName.isEmpty) return false;
    final offset = tab.codeController.selection.baseOffset;
    if (offset < 0) return false;
    final text = tab.codeController.fullText;
    final (line, character) = offsetToLineChar(text, offset);
    final edit = await lspService.rename(
      tab.filePath,
      line,
      character,
      newName,
    );
    if (edit == null) return false;
    await applyWorkspaceEdit(edit);
    return true;
  }

  /// Returns the placeholder name for rename at cursor, or null.
  Future<String?> prepareRenamePlaceholder() async {
    final tab = tabController.activeTab;
    if (tab == null) return null;
    final offset = tab.codeController.selection.baseOffset;
    if (offset < 0) return null;
    final text = tab.codeController.fullText;
    final (line, character) = offsetToLineChar(text, offset);
    final prepared = await lspService.prepareRename(
      tab.filePath,
      line,
      character,
    );
    return prepared?.placeholder;
  }
  Future<List<LspCodeAction>> getCodeActions() async { final tab=tabController.activeTab; if(tab==null)return const[]; final sel=tab.codeController.selection; if(!sel.isValid)return const[]; final text=tab.codeController.fullText; final (a,b)=offsetToLineChar(text,sel.start); final (c,d)=offsetToLineChar(text,sel.end); return lspService.getCodeActions(tab.filePath,a,b,c,d); }
  Future<LspSignatureHelp?> getSignatureHelp() async { final tab=tabController.activeTab; if(tab==null)return null; final off=tab.codeController.selection.baseOffset; if(off<0)return null; final text=tab.codeController.fullText; final (l,ch)=offsetToLineChar(text,off); return lspService.getSignatureHelp(tab.filePath,l,ch); }
  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _gitRefreshTimer?.cancel();
    fileWatcher.dispose();
    tabController.dispose();
    paletteController.dispose();
    ghostCompletionService.dispose();
    liveShareService.dispose();
    for (final a in _analyzers.values) {
      a.dispose();
    }
    for (final ac in _autocompleters.values) {
      ac.dispose();
    }
    lspService.dispose();
    parserService.dispose();
    super.dispose();
  }
}

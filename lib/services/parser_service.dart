import 'dart:async';

import 'package:parser_client/parser_client.dart';
import 'package:path/path.dart' as p;

import 'settings_service.dart';

/// Bridges the parser_client package and the Flutter editor.
///
/// Spawns krom-parser as a subprocess and manages per-file parse state
/// for syntax highlighting and structural queries.
class ParserService {
  ParserService(this._settings);

  final SettingsService _settings;

  ParserClient? _client;
  final Map<String, Timer> _changeDebounces = {};
  final Map<String, String> _pendingContent = {};
  final Map<String, void Function(List<ParserHighlightSpan>)> _highlightListeners =
      {};

  bool get isAvailable => _client != null;

  bool hasLanguage(String languageId) =>
      _client?.hasLanguage(languageId) ?? false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final cmd = _settings.parserCommand;
    if (cmd.isEmpty) return;

    try {
      _client = await ParserClient.start(command: cmd);
      await _client!.listLanguages();
    } catch (_) {
      _client = null;
    }
  }

  Future<void> dispose() async {
    for (final timer in _changeDebounces.values) {
      timer.cancel();
    }
    _changeDebounces.clear();
    _pendingContent.clear();
    _highlightListeners.clear();
    await _client?.shutdown();
    _client = null;
  }

  // ── Highlight listeners ───────────────────────────────────────────────────

  void onHighlights(
    String filePath,
    void Function(List<ParserHighlightSpan> spans) listener,
  ) {
    _highlightListeners[filePath] = listener;
  }

  void removeHighlightsListener(String filePath) {
    _highlightListeners.remove(filePath);
  }

  // ── Document lifecycle ────────────────────────────────────────────────────

  Future<void> openDocument(
    String filePath,
    String languageId,
    String content,
  ) async {
    final client = _client;
    if (client == null || !client.hasLanguage(languageId)) return;

    final result = await client.parseFile(
      fileId: filePath,
      languageId: languageId,
      content: content,
    );
    if (!result.success) return;

    await _publishHighlights(filePath);
  }

  void scheduleUpdate(String filePath, String content) {
    _pendingContent[filePath] = content;
    _changeDebounces[filePath]?.cancel();
    _changeDebounces[filePath] = Timer(
      const Duration(milliseconds: 150),
      () => _flushUpdate(filePath),
    );
  }

  Future<void> closeDocument(String filePath) async {
    _changeDebounces.remove(filePath)?.cancel();
    _pendingContent.remove(filePath);
    _highlightListeners.remove(filePath);
    await _client?.closeFile(fileId: filePath);
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<ParserSymbolInfo>> getStructure(String filePath) async {
    final client = _client;
    if (client == null) return const [];
    return client.getStructure(fileId: filePath);
  }

  Future<ParserNodeInfo?> getNodeAtPosition(
    String filePath,
    int line,
    int column,
  ) async {
    final client = _client;
    if (client == null) return null;
    return client.getNodeAtPosition(
      fileId: filePath,
      line: line,
      column: column,
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _flushUpdate(String filePath) async {
    final content = _pendingContent[filePath];
    final client = _client;
    if (content == null || client == null) return;

    final result = await client.updateFile(fileId: filePath, content: content);
    if (!result.success) return;

    await _publishHighlights(filePath);
  }

  Future<void> _publishHighlights(String filePath) async {
    final client = _client;
    final listener = _highlightListeners[filePath];
    if (client == null || listener == null) return;

    final result = await client.getHighlights(fileId: filePath);
    listener(result.spans);
  }

  /// Maps file extension to parser language ID.
  static String? languageIdFromPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return _extToLanguageId[ext];
  }

  static const _extToLanguageId = <String, String>{
    '.py': 'python',
  };
}

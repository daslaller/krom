import 'dart:async';

import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:lsp_client/lsp_client.dart';
import 'package:path/path.dart' as p;

import 'settings_service.dart';

/// Bridges the LSP client package and the Flutter editor.
///
/// Manages one [LspClient] per configured language server and exposes
/// per-file diagnostics as streams of flutter_code_editor [Issue] lists.
class LspService {
  LspService(this._settings);

  final SettingsService _settings;

  final Map<String, LspClient> _clients = {};

  // file URI string → broadcast StreamController<List<Issue>>
  final Map<String, StreamController<List<Issue>>> _diagStreams = {};

  // file path → current document version
  final Map<String, int> _versions = {};

  // Pending debounced change per file
  final Map<String, Timer> _changeDebounces = {};
  final Map<String, String> _pendingContent = {};
  final Map<String, String> _pendingLanguageId = {};

  bool get isAvailable => _clients.isNotEmpty;

  Iterable<String> get activeLanguages => _clients.keys;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize(String workspaceRoot) async {
    final rootUri = Uri.directory(workspaceRoot).toString();
    final languageIds = _settings.configuredLanguageIds();

    for (final languageId in languageIds) {
      if (_clients.containsKey(languageId)) continue;

      final cmd = _settings.serverCommand(languageId);
      if (cmd.isEmpty) continue;

      try {
        final client = await LspClient.start(
          serverCommand: cmd,
          rootUri: rootUri,
        );
        client.diagnostics.listen(_onDiagnostics);
        _clients[languageId] = client;
      } catch (_) {
        // Language server not available — degrade gracefully.
      }
    }
  }

  Future<void> dispose() async {
    for (final timer in _changeDebounces.values) {
      timer.cancel();
    }
    _changeDebounces.clear();
    for (final sc in _diagStreams.values) {
      await sc.close();
    }
    _diagStreams.clear();
    for (final client in _clients.values) {
      await client.shutdown();
    }
    _clients.clear();
  }

  // ── Document lifecycle ────────────────────────────────────────────────────

  Future<void> openDocument(
    String filePath,
    String languageId,
    String content,
  ) async {
    final client = _clientFor(languageId);
    if (client == null) return;

    _versions[filePath] = 1;
    _ensureStream(filePath);

    await client.openDocument(
      uri: Uri.file(filePath),
      languageId: languageId,
      text: content,
      version: 1,
    );
  }

  /// Debounced (300 ms) change notification — call on every keystroke.
  void scheduleChange(String filePath, String languageId, String content) {
    _pendingContent[filePath] = content;
    _pendingLanguageId[filePath] = languageId;
    _changeDebounces[filePath]?.cancel();
    _changeDebounces[filePath] = Timer(
      const Duration(milliseconds: 300),
      () => _flushChange(filePath),
    );
  }

  Future<void> closeDocument(String filePath, String languageId) async {
    _changeDebounces.remove(filePath)?.cancel();
    _pendingContent.remove(filePath);
    _pendingLanguageId.remove(filePath);

    final client = _clientFor(languageId);
    if (client != null) {
      await client.closeDocument(uri: Uri.file(filePath));
    }
    final uri = _toUri(filePath);
    await _diagStreams[uri]?.close();
    _diagStreams.remove(uri);
    _versions.remove(filePath);
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Stream<List<Issue>> diagnosticsFor(String filePath) =>
      _ensureStream(filePath).stream;

  Future<List<LspCompletionItem>> getCompletions(
    String filePath,
    int line,
    int character,
  ) async {
    final client = _clientForPath(filePath);
    if (client == null) return const [];
    return client.getCompletions(
      uri: Uri.file(filePath),
      line: line,
      character: character,
    );
  }

  Future<LspHover?> getHover(
    String filePath,
    int line,
    int character,
  ) async {
    final client = _clientForPath(filePath);
    if (client == null) return null;
    return client.getHover(
      uri: Uri.file(filePath),
      line: line,
      character: character,
    );
  }

  Future<List<LspLocation>> getDefinition(
    String filePath,
    int line,
    int character,
  ) async {
    final client = _clientForPath(filePath);
    if (client == null) return const [];
    return client.getDefinition(
      uri: Uri.file(filePath),
      line: line,
      character: character,
    );
  }

  Future<List<LspLocation>> getReferences(
    String filePath,
    int line,
    int character,
  ) async {
    final client = _clientForPath(filePath);
    if (client == null) return const [];
    return client.getReferences(
      uri: Uri.file(filePath),
      line: line,
      character: character,
    );
  }

  Future<String?> formatDocumentText(String filePath, String text) async {
    final client = _clientForPath(filePath);
    if (client == null) return null;

    // Ensure server has latest content before formatting.
    final languageId = languageIdFromPath(filePath);
    if (languageId == null) return null;

    final version = (_versions[filePath] ?? 1) + 1;
    _versions[filePath] = version;
    await client.changeDocument(
      uri: Uri.file(filePath),
      text: text,
      version: version,
    );

    final edits = await client.formatDocument(uri: Uri.file(filePath));
    if (edits.isEmpty) return text;
    return applyTextEdits(text, edits);
  }

  Future<List<LspDocumentSymbol>> getDocumentSymbols(String filePath) async {
    final client = _clientForPath(filePath);
    if (client == null) return const [];
    return client.getDocumentSymbols(uri: Uri.file(filePath));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _flushChange(String path) {
    final content = _pendingContent[path];
    final languageId = _pendingLanguageId[path];
    if (content == null || languageId == null) return;

    final client = _clientFor(languageId);
    if (client == null) return;

    final version = (_versions[path] ?? 1) + 1;
    _versions[path] = version;
    client.changeDocument(
      uri: Uri.file(path),
      text: content,
      version: version,
    );
  }

  void _onDiagnostics(LspDiagnosticsParams params) {
    final sc = _diagStreams[params.uri];
    if (sc == null || sc.isClosed) return;
    sc.add(params.diagnostics.map(_toIssue).toList());
  }

  Issue _toIssue(LspDiagnostic d) => Issue(
        line: d.range.start.line,
        message: d.message,
        type: switch (d.severity) {
          LspDiagnosticSeverity.error => IssueType.error,
          LspDiagnosticSeverity.warning => IssueType.warning,
          _ => IssueType.info,
        },
      );

  LspClient? _clientFor(String languageId) => _clients[languageId];

  LspClient? _clientForPath(String filePath) =>
      _clientFor(languageIdFromPath(filePath) ?? '');

  StreamController<List<Issue>> _ensureStream(String filePath) {
    final uri = _toUri(filePath);
    return _diagStreams.putIfAbsent(uri, () => StreamController.broadcast());
  }

  String _toUri(String filePath) => Uri.file(filePath).toString();

  /// Maps file extension to LSP language ID.
  static String? languageIdFromPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return _extToLanguageId[ext];
  }

  static const _extToLanguageId = <String, String>{
    '.dart': 'dart',
    '.py': 'python',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.jsx': 'javascript',
    '.tsx': 'typescript',
    '.go': 'go',
    '.java': 'java',
    '.kt': 'kotlin',
    '.cs': 'csharp',
    '.cpp': 'cpp',
    '.c': 'c',
    '.h': 'cpp',
    '.rs': 'rust',
    '.rb': 'ruby',
    '.swift': 'swift',
    '.php': 'php',
    '.html': 'html',
    '.css': 'css',
    '.json': 'json',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.sh': 'shellscript',
    '.md': 'markdown',
    '.sql': 'sql',
    '.lua': 'lua',
  };
}

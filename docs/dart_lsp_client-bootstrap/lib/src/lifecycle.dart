import 'dart:async';
import 'dart:io';

import 'completion.dart';
import 'definition.dart';
import 'diagnostics.dart';
import 'formatting.dart';
import 'hover.dart';
import 'references.dart';
import 'rename.dart';
import 'symbols.dart';
import 'text_sync.dart';
import 'transport.dart';

export 'completion.dart';
export 'definition.dart';
export 'diagnostics.dart';
export 'formatting.dart';
export 'hover.dart';
export 'references.dart';
export 'rename.dart';
export 'symbols.dart';
export 'text_sync.dart';

/// Full LSP client: lifecycle, text sync, diagnostics, completion, hover, definition.
///
/// Usage:
/// ```dart
/// final client = await LspClient.start(
///   serverCommand: ['dart', 'language-server', '--protocol=lsp'],
///   rootUri: Uri.directory('/path/to/project').toString(),
/// );
/// client.diagnostics.listen((params) { ... });
/// await client.openDocument(uri: ..., languageId: 'dart', text: source);
/// ```
class LspClient {
  LspClient._(this._transport) {
    _transport.messages.listen(_route);
  }

  final LspTransport _transport;
  int _nextId = 1;
  final Map<int, Completer<Map<String, dynamic>?>> _pending = {};
  final StreamController<LspDiagnosticsParams> _diagnostics =
      StreamController.broadcast();

  /// Sync kind negotiated during initialize (defaults to full).
  TextDocumentSyncKind syncKind = TextDocumentSyncKind.full;

  /// Last known document text per URI (for incremental sync).
  final Map<String, String> _documentTexts = {};

  /// Server-pushed diagnostic notifications.
  Stream<LspDiagnosticsParams> get diagnostics => _diagnostics.stream;

  // ── Factory ───────────────────────────────────────────────────────────────

  /// Spawns the language server and completes the initialize handshake.
  static Future<LspClient> start({
    required List<String> serverCommand,
    required String rootUri,
  }) async {
    final transport = await LspTransport.start(serverCommand);
    final client = LspClient._(transport);
    await client._initialize(rootUri);
    return client;
  }

  // ── Text sync ─────────────────────────────────────────────────────────────

  Future<void> openDocument({
    required Uri uri,
    required String languageId,
    required String text,
    int version = 1,
  }) async {
    _documentTexts[uri.toString()] = text;
    _notify('textDocument/didOpen', {
      'textDocument': {
        'uri': uri.toString(),
        'languageId': languageId,
        'version': version,
        'text': text,
      },
    });
  }

  Future<void> changeDocument({
    required Uri uri,
    required String text,
    required int version,
  }) async {
    final uriStr = uri.toString();
    if (syncKind == TextDocumentSyncKind.incremental) {
      final oldText = _documentTexts[uriStr] ?? '';
      final change = computeTextChange(oldText, text);
      _documentTexts[uriStr] = text;
      _notify('textDocument/didChange', {
        'textDocument': {'uri': uriStr, 'version': version},
        'contentChanges': [change.toJson()],
      });
      return;
    }

    _documentTexts[uriStr] = text;
    _notify('textDocument/didChange', {
      'textDocument': {'uri': uri.toString(), 'version': version},
      'contentChanges': [
        {'text': text},
      ],
    });
  }

  Future<void> closeDocument({required Uri uri}) async {
    _documentTexts.remove(uri.toString());
    _notify('textDocument/didClose', {
      'textDocument': {'uri': uri.toString()},
    });
  }

  // ── Completion ────────────────────────────────────────────────────────────

  Future<List<LspCompletionItem>> getCompletions({
    required Uri uri,
    required int line,
    required int character,
  }) async {
    final response = await _request('textDocument/completion', {
      'textDocument': {'uri': uri.toString()},
      'position': {'line': line, 'character': character},
    });
    if (response == null) return const [];

    final result = response['result'];
    if (result == null) return const [];

    // result is either a list or a CompletionList object with an 'items' field.
    final items =
        result is Map ? result['items'] as List? : result as List?;
    if (items == null) return const [];

    return items
        .map((i) => LspCompletionItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  // ── Hover ─────────────────────────────────────────────────────────────────

  Future<LspHover?> getHover({
    required Uri uri,
    required int line,
    required int character,
  }) async {
    final response = await _request('textDocument/hover', {
      'textDocument': {'uri': uri.toString()},
      'position': {'line': line, 'character': character},
    });
    final result = response?['result'];
    if (result == null) return null;
    return LspHover.fromJson(result as Map<String, dynamic>);
  }

  // ── Definition ────────────────────────────────────────────────────────────

  Future<List<LspLocation>> getDefinition({
    required Uri uri,
    required int line,
    required int character,
  }) async {
    final response = await _request('textDocument/definition', {
      'textDocument': {'uri': uri.toString()},
      'position': {'line': line, 'character': character},
    });
    final result = response?['result'];
    if (result == null) return const [];

    if (result is List) {
      return result
          .map((l) => LspLocation.fromJson(l as Map<String, dynamic>))
          .toList();
    }
    // Some servers return a single location object.
    return [LspLocation.fromJson(result as Map<String, dynamic>)];
  }

  // ── References ────────────────────────────────────────────────────────────

  Future<List<LspLocation>> getReferences({
    required Uri uri,
    required int line,
    required int character,
    bool includeDeclaration = true,
  }) async {
    final response = await _request('textDocument/references', {
      'textDocument': {'uri': uri.toString()},
      'position': {'line': line, 'character': character},
      'context': {'includeDeclaration': includeDeclaration},
    });
    return LspReferenceResult.parseResult(response?['result']);
  }

  // ── Formatting ──────────────────────────────────────────────────────────

  Future<List<LspTextEdit>> formatDocument({required Uri uri}) async {
    final response = await _request('textDocument/formatting', {
      'textDocument': {'uri': uri.toString()},
      'options': {
        'tabSize': 2,
        'insertSpaces': true,
      },
    });
    return LspTextEdit.parseResult(response?['result']);
  }

  // ── Rename ────────────────────────────────────────────────────────────────

  Future<LspPrepareRenameResult?> prepareRename({
    required Uri uri,
    required int line,
    required int character,
  }) async {
    final response = await _request('textDocument/prepareRename', {
      'textDocument': {'uri': uri.toString()},
      'position': {'line': line, 'character': character},
    });
    return LspPrepareRenameResult.parseResult(response?['result']);
  }

  Future<LspWorkspaceEdit?> rename({
    required Uri uri,
    required int line,
    required int character,
    required String newName,
  }) async {
    final response = await _request('textDocument/rename', {
      'textDocument': {'uri': uri.toString()},
      'position': {'line': line, 'character': character},
      'newName': newName,
    });
    final result = response?['result'];
    if (result == null) return null;
    return LspWorkspaceEdit.fromJson(result as Map<String, dynamic>);
  }

  // ── Symbols ───────────────────────────────────────────────────────────────

  Future<List<LspDocumentSymbol>> getDocumentSymbols({
    required Uri uri,
  }) async {
    final response = await _request('textDocument/documentSymbol', {
      'textDocument': {'uri': uri.toString()},
    });
    return LspDocumentSymbol.parseResult(response?['result']);
  }

  Future<List<LspWorkspaceSymbol>> getWorkspaceSymbols({
    required String query,
  }) async {
    final response = await _request('workspace/symbol', {'query': query});
    return LspWorkspaceSymbol.parseResult(response?['result']);
  }

  // ── Shutdown ──────────────────────────────────────────────────────────────

  Future<void> shutdown() async {
    await _request('shutdown', null);
    _notify('exit', null);
    _documentTexts.clear();
    // Cancel all pending requests before disposing.
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete(null);
    }
    _pending.clear();
    await _transport.dispose();
    if (!_diagnostics.isClosed) await _diagnostics.close();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _initialize(String rootUri) async {
    final response = await _request('initialize', {
      'processId': pid,
      'rootUri': rootUri,
      'capabilities': {
        'textDocument': {
          'synchronization': {
            'openClose': true,
            'change': TextDocumentSyncKind.incremental.value,
            'save': true,
          },
          'completion': {
            'completionItem': {
              'snippetSupport': true,
              'documentationFormat': ['plaintext', 'markdown'],
            },
          },
          'hover': {
            'contentFormat': ['plaintext', 'markdown'],
          },
          'definition': {'linkSupport': true},
          'references': {},
          'documentSymbol': {'hierarchicalDocumentSymbolSupport': true},
          'rename': {'prepareSupport': true},
          'formatting': {},
          'publishDiagnostics': {},
        },
        'workspace': {
          'symbol': {'dynamicRegistration': false},
          'applyEdit': true,
        },
      },
    });

  // Negotiate sync kind from server capabilities.
    final result = response?['result'] as Map<String, dynamic>?;
    final serverCaps = result?['capabilities'] as Map<String, dynamic>?;
    final textDocSync = serverCaps?['textDocumentSync'];
    if (textDocSync is int) {
      syncKind = TextDocumentSyncKind.values.firstWhere(
        (k) => k.value == textDocSync,
        orElse: () => TextDocumentSyncKind.full,
      );
    } else if (textDocSync is Map) {
      final change = textDocSync['change'] as int?;
      syncKind = TextDocumentSyncKind.values.firstWhere(
        (k) => k.value == change,
        orElse: () => TextDocumentSyncKind.full,
      );
    }

    _notify('initialized', {});
  }

  Future<Map<String, dynamic>?> _request(
    String method,
    Map<String, dynamic>? params,
  ) {
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>?>();
    _pending[id] = completer;
    _transport.send({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    });
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(id);
        return null;
      },
    );
  }

  void _notify(String method, Map<String, dynamic>? params) {
    _transport.send({
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
    });
  }

  void _route(Map<String, dynamic> msg) {
    final id = msg['id'];
    final method = msg['method'] as String?;

    if (id != null && _pending.containsKey(id)) {
      _pending.remove(id)?.complete(msg);
      return;
    }

    if (method == 'textDocument/publishDiagnostics') {
      final params = msg['params'] as Map<String, dynamic>?;
      if (params != null && !_diagnostics.isClosed) {
        _diagnostics.add(LspDiagnosticsParams.fromJson(params));
      }
    }
    // window/logMessage, $/progress, etc. are silently ignored.
  }
}

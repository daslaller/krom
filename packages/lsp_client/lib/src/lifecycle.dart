import 'dart:async';
import 'dart:io';

import 'completion.dart';
import 'definition.dart';
import 'diagnostics.dart';
import 'hover.dart';
import 'transport.dart';

export 'completion.dart';
export 'definition.dart';
export 'diagnostics.dart';
export 'hover.dart';

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
    _notify('textDocument/didChange', {
      'textDocument': {'uri': uri.toString(), 'version': version},
      'contentChanges': [
        {'text': text},
      ],
    });
  }

  Future<void> closeDocument({required Uri uri}) async {
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

  // ── Shutdown ──────────────────────────────────────────────────────────────

  Future<void> shutdown() async {
    await _request('shutdown', null);
    _notify('exit', null);
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
    await _request('initialize', {
      'processId': pid,
      'rootUri': rootUri,
      'capabilities': {
        'textDocument': {
          'synchronization': {
            'openClose': true,
            'change': 1, // TextDocumentSyncKind.Full
          },
          'completion': {
            'completionItem': {'snippetSupport': false},
          },
          'hover': {
            'contentFormat': ['plaintext', 'markdown'],
          },
          'definition': {'linkSupport': false},
          'publishDiagnostics': {},
        },
      },
    });
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

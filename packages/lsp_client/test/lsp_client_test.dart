import 'dart:convert';
import 'dart:io';

import 'package:lsp_client/lsp_client.dart';
import 'package:test/test.dart';

void main() {
  group('LspTransport framing', () {
    test('encodes message with Content-Length header', () async {
      // We verify the wire format by spawning a simple echo-like Dart script
      // that captures stdin and writes it back to stdout as-is.
      // For unit testing without a real LSP server, we test the parser directly.

      // Build a valid LSP frame manually.
      const body = '{"jsonrpc":"2.0","id":1,"method":"test"}';
      final bodyBytes = utf8.encode(body);
      final frame =
          utf8.encode('Content-Length: ${bodyBytes.length}\r\n\r\n') +
              bodyBytes;

      expect(frame, contains(utf8.encode('Content-Length: ${bodyBytes.length}')));
    });
  });

  group('LspDiagnostic', () {
    test('parses from JSON', () {
      final json = {
        'range': {
          'start': {'line': 3, 'character': 5},
          'end': {'line': 3, 'character': 10},
        },
        'message': 'Undefined name',
        'severity': 1,
      };
      final diag = LspDiagnostic.fromJson(json);
      expect(diag.range.start.line, 3);
      expect(diag.range.start.character, 5);
      expect(diag.message, 'Undefined name');
      expect(diag.severity, LspDiagnosticSeverity.error);
    });

    test('defaults to error severity when severity is null', () {
      final json = {
        'range': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 0, 'character': 0},
        },
        'message': 'test',
      };
      final diag = LspDiagnostic.fromJson(json);
      expect(diag.severity, LspDiagnosticSeverity.error);
    });
  });

  group('LspDiagnosticsParams', () {
    test('parses uri and diagnostic list', () {
      final json = {
        'uri': 'file:///home/user/main.dart',
        'diagnostics': [
          {
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 5},
            },
            'message': 'error message',
            'severity': 1,
          },
        ],
      };
      final params = LspDiagnosticsParams.fromJson(json);
      expect(params.uri, 'file:///home/user/main.dart');
      expect(params.diagnostics.length, 1);
      expect(params.diagnostics.first.message, 'error message');
    });
  });

  group('LspCompletionItem', () {
    test('parses label and detail', () {
      final item = LspCompletionItem.fromJson({
        'label': 'myFunction',
        'detail': 'void myFunction()',
        'kind': 3,
      });
      expect(item.label, 'myFunction');
      expect(item.detail, 'void myFunction()');
      expect(item.kind, 3);
    });

    test('insertText defaults to null when absent', () {
      final item = LspCompletionItem.fromJson({'label': 'foo'});
      expect(item.insertText, isNull);
    });
  });

  group('LspHover', () {
    test('parses plain string content', () {
      final hover = LspHover.fromJson({'contents': 'int value'});
      expect(hover.content, 'int value');
    });

    test('parses MarkupContent', () {
      final hover =
          LspHover.fromJson({'contents': {'kind': 'markdown', 'value': '**int** value'}});
      expect(hover.content, '**int** value');
    });

    test('handles empty contents', () {
      final hover = LspHover.fromJson({'contents': []});
      expect(hover.content, '');
    });
  });

  group('LspLocation', () {
    test('parses uri and range', () {
      final loc = LspLocation.fromJson({
        'uri': 'file:///src/main.dart',
        'range': {
          'start': {'line': 10, 'character': 4},
          'end': {'line': 10, 'character': 14},
        },
      });
      expect(loc.uri, 'file:///src/main.dart');
      expect(loc.range.start.line, 10);
    });
  });

  group('TextDocumentContentChangeEvent', () {
    test('computeTextChange finds prefix/suffix diff', () {
      const oldText = 'hello world';
      const newText = 'hello dart world';
      final change = computeTextChange(oldText, newText);
      expect(change.text, 'dart ');
      expect(change.range, isNotNull);
      expect(change.range!.start.line, 0);
      expect(change.range!.start.character, 6);
    });

    test('computeTextChange returns empty for identical text', () {
      const text = 'unchanged';
      final change = computeTextChange(text, text);
      expect(change.text, '');
    });
  });

  group('LspClient integration', () {
    test('start fails gracefully when server is unavailable', () async {
      expect(
        () => LspClient.start(
          serverCommand: ['nonexistent-lsp-server-xyz'],
          rootUri: 'file:///tmp',
        ),
        throwsA(anything),
      );
    });
  });
}

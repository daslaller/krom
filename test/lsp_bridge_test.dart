import 'dart:async';

import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krom/editor/krom_analyzer.dart';
import 'package:krom/services/lsp_service.dart';
import 'package:krom/services/settings_service.dart';
import 'package:lsp_client/lsp_client.dart';

// ---------------------------------------------------------------------------
// Fake LspService that lets tests push diagnostics without a real LSP server.
// ---------------------------------------------------------------------------

class _FakeLspService extends LspService {
  // SettingsService with no file to load — serverCommand() falls back to
  // built-in defaults, but we never call initialize(), so no process is
  // spawned.
  _FakeLspService() : super(SettingsService());

  final _streams = <String, StreamController<List<Issue>>>{};

  @override
  Stream<List<Issue>> diagnosticsFor(String filePath) {
    final uri = Uri.file(filePath).toString();
    return (_streams.putIfAbsent(uri, () => StreamController.broadcast()))
        .stream;
  }

  void pushDiagnostics(String filePath, List<Issue> issues) {
    final uri = Uri.file(filePath).toString();
    _streams[uri]?.add(issues);
  }

  @override
  Future<void> dispose() async {
    for (final sc in _streams.values) {
      await sc.close();
    }
    _streams.clear();
  }
}

// ---------------------------------------------------------------------------
// KromAnalyzer tests
// ---------------------------------------------------------------------------

void main() {
  group('KromAnalyzer', () {
    test('returns empty list before any diagnostics arrive', () async {
      final service = _FakeLspService();
      int callCount = 0;

      final analyzer = KromAnalyzer(
        lspService: service,
        filePath: '/project/main.dart',
        onNewDiagnostics: () => callCount++,
      );

      final result = await analyzer.analyze(Code(text: 'void main() {}'));
      expect(result.issues, isEmpty);
      expect(callCount, 0);

      analyzer.dispose();
      await service.dispose();
    });

    test('returns issues after push and fires onNewDiagnostics', () async {
      final service = _FakeLspService();
      int callCount = 0;

      final analyzer = KromAnalyzer(
        lspService: service,
        filePath: '/project/main.dart',
        onNewDiagnostics: () => callCount++,
      );

      service.pushDiagnostics('/project/main.dart', [
        const Issue(line: 5, message: 'Undefined name', type: IssueType.error),
        const Issue(line: 8, message: 'Unused var', type: IssueType.warning),
      ]);

      await Future<void>.delayed(Duration.zero); // Let the stream event fire.

      expect(callCount, 1);

      final result = await analyzer.analyze(Code(text: ''));
      expect(result.issues.length, 2);
      expect(result.issues[0].line, 5);
      expect(result.issues[0].type, IssueType.error);
      expect(result.issues[1].line, 8);
      expect(result.issues[1].type, IssueType.warning);

      analyzer.dispose();
      await service.dispose();
    });

    test('dispose cancels subscription — no callbacks after dispose', () async {
      final service = _FakeLspService();
      int callCount = 0;

      final analyzer = KromAnalyzer(
        lspService: service,
        filePath: '/project/main.dart',
        onNewDiagnostics: () => callCount++,
      );

      analyzer.dispose();

      service.pushDiagnostics('/project/main.dart', [
        const Issue(line: 1, message: 'error', type: IssueType.error),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(callCount, 0);
      await service.dispose();
    });

    test('subsequent pushes replace previous issues', () async {
      final service = _FakeLspService();

      final analyzer = KromAnalyzer(
        lspService: service,
        filePath: '/project/main.dart',
        onNewDiagnostics: () {},
      );

      service.pushDiagnostics('/project/main.dart', [
        const Issue(line: 1, message: 'first', type: IssueType.error),
      ]);
      await Future<void>.delayed(Duration.zero);

      service.pushDiagnostics('/project/main.dart', []);
      await Future<void>.delayed(Duration.zero);

      final result = await analyzer.analyze(Code(text: ''));
      expect(result.issues, isEmpty);

      analyzer.dispose();
      await service.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // LspDiagnostic JSON parsing + severity mapping
  // ---------------------------------------------------------------------------

  group('LspDiagnostic', () {
    LspDiagnostic diag(int severity) => LspDiagnostic.fromJson({
          'range': {
            'start': {'line': 0, 'character': 0},
            'end': {'line': 0, 'character': 1},
          },
          'message': 'msg',
          'severity': severity,
        });

    test('severity 1 → error', () {
      expect(diag(1).severity, LspDiagnosticSeverity.error);
    });

    test('severity 2 → warning', () {
      expect(diag(2).severity, LspDiagnosticSeverity.warning);
    });

    test('severity 3 → information', () {
      expect(diag(3).severity, LspDiagnosticSeverity.information);
    });

    test('severity 4 → hint', () {
      expect(diag(4).severity, LspDiagnosticSeverity.hint);
    });

    test('null severity defaults to error', () {
      final d = LspDiagnostic.fromJson({
        'range': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 0, 'character': 1},
        },
        'message': 'msg',
      });
      expect(d.severity, LspDiagnosticSeverity.error);
    });
  });
}

import 'dart:async';

import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../services/lsp_service.dart';

/// Bridges LSP diagnostics into flutter_code_editor's [AbstractAnalyzer].
///
/// Caches the latest [Issue] list from the LSP server. When new diagnostics
/// arrive, [onNewDiagnostics] is called so the host can trigger
/// [CodeController.analyzeCode] and redraw squigglies.
class KromAnalyzer extends AbstractAnalyzer {
  KromAnalyzer({
    required LspService lspService,
    required String filePath,
    required void Function() onNewDiagnostics,
  }) {
    _sub = lspService.diagnosticsFor(filePath).listen((issues) {
      _issues = issues;
      onNewDiagnostics();
    });
  }

  List<Issue> _issues = const [];
  StreamSubscription<List<Issue>>? _sub;

  @override
  Future<AnalysisResult> analyze(Code code) async =>
      AnalysisResult(issues: _issues);

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}

/// LSP diagnostic protocol types.

/// A position (zero-based line and character) in a text document.
class LspPosition {
  const LspPosition({required this.line, required this.character});

  final int line;
  final int character;

  factory LspPosition.fromJson(Map<String, dynamic> json) => LspPosition(
        line: (json['line'] as num).toInt(),
        character: (json['character'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {'line': line, 'character': character};
}

/// A range in a text document.
class LspRange {
  const LspRange({required this.start, required this.end});

  final LspPosition start;
  final LspPosition end;

  factory LspRange.fromJson(Map<String, dynamic> json) => LspRange(
        start: LspPosition.fromJson(json['start'] as Map<String, dynamic>),
        end: LspPosition.fromJson(json['end'] as Map<String, dynamic>),
      );
}

/// Diagnostic severity as defined by LSP (1=error, 2=warning, 3=info, 4=hint).
enum LspDiagnosticSeverity { error, warning, information, hint }

LspDiagnosticSeverity _severityFromCode(int? code) => switch (code) {
      1 => LspDiagnosticSeverity.error,
      2 => LspDiagnosticSeverity.warning,
      3 => LspDiagnosticSeverity.information,
      4 => LspDiagnosticSeverity.hint,
      _ => LspDiagnosticSeverity.error,
    };

/// A single diagnostic item from the server.
class LspDiagnostic {
  const LspDiagnostic({
    required this.range,
    required this.message,
    required this.severity,
  });

  final LspRange range;
  final String message;
  final LspDiagnosticSeverity severity;

  factory LspDiagnostic.fromJson(Map<String, dynamic> json) => LspDiagnostic(
        range: LspRange.fromJson(json['range'] as Map<String, dynamic>),
        message: json['message'] as String,
        severity: _severityFromCode(json['severity'] as int?),
      );
}

/// Parameters of a `textDocument/publishDiagnostics` notification.
class LspDiagnosticsParams {
  const LspDiagnosticsParams({
    required this.uri,
    required this.diagnostics,
  });

  final String uri;
  final List<LspDiagnostic> diagnostics;

  factory LspDiagnosticsParams.fromJson(Map<String, dynamic> json) =>
      LspDiagnosticsParams(
        uri: json['uri'] as String,
        diagnostics: (json['diagnostics'] as List)
            .map((d) => LspDiagnostic.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

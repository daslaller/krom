import 'definition.dart';
import 'diagnostics.dart';

/// A symbol returned by `textDocument/documentSymbol`.
class LspDocumentSymbol {
  const LspDocumentSymbol({
    required this.name,
    required this.kind,
    required this.range,
    this.detail,
    this.children = const [],
  });

  final String name;
  final int kind;
  final LspRange range;
  final String? detail;
  final List<LspDocumentSymbol> children;

  factory LspDocumentSymbol.fromJson(Map<String, dynamic> json) {
    final selectionRange = json['selectionRange'] as Map<String, dynamic>?;
    final rangeJson = json['range'] as Map<String, dynamic>?;
    return LspDocumentSymbol(
      name: json['name'] as String,
      kind: (json['kind'] as num?)?.toInt() ?? 0,
      range: LspRange.fromJson(
        rangeJson ?? selectionRange ?? {'start': {'line': 0, 'character': 0}, 'end': {'line': 0, 'character': 0}},
      ),
      detail: json['detail'] as String?,
      children: (json['children'] as List?)
              ?.map((c) => LspDocumentSymbol.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  static List<LspDocumentSymbol> parseResult(dynamic result) {
    if (result == null) return const [];
    if (result is! List) return const [];
    return result.map((s) {
      if (s is Map<String, dynamic>) {
        return LspDocumentSymbol.fromJson(s);
      }
      return const LspDocumentSymbol(
        name: '',
        kind: 0,
        range: LspRange(
          start: LspPosition(line: 0, character: 0),
          end: LspPosition(line: 0, character: 0),
        ),
      );
    }).where((s) => s.name.isNotEmpty).toList();
  }
}

/// A symbol returned by `workspace/symbol`.
class LspWorkspaceSymbol {
  const LspWorkspaceSymbol({
    required this.name,
    required this.kind,
    required this.location,
  });

  final String name;
  final int kind;
  final LspLocation location;

  factory LspWorkspaceSymbol.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    if (loc != null) {
      return LspWorkspaceSymbol(
        name: json['name'] as String,
        kind: (json['kind'] as num?)?.toInt() ?? 0,
        location: LspLocation.fromJson(loc),
      );
    }
    // SymbolInformation format.
    return LspWorkspaceSymbol(
      name: json['name'] as String,
      kind: (json['kind'] as num?)?.toInt() ?? 0,
      location: LspLocation(
        uri: json['location']?['uri'] as String? ?? '',
        range: LspRange.fromJson(
          json['location']?['range'] as Map<String, dynamic>? ??
              {'start': {'line': 0, 'character': 0}, 'end': {'line': 0, 'character': 0}},
        ),
      ),
    );
  }

  static List<LspWorkspaceSymbol> parseResult(dynamic result) {
    if (result == null) return const [];
    if (result is! List) return const [];
    return result
        .map((s) => LspWorkspaceSymbol.fromJson(s as Map<String, dynamic>))
        .toList();
  }
}

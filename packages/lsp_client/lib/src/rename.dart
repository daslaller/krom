import 'diagnostics.dart';
import 'formatting.dart';

/// Result of a `textDocument/rename` request.
class LspWorkspaceEdit {
  const LspWorkspaceEdit({required this.changes});

  /// URI → list of text edits for that document.
  final Map<String, List<LspTextEdit>> changes;

  factory LspWorkspaceEdit.fromJson(Map<String, dynamic> json) {
    final raw = json['changes'] as Map<String, dynamic>? ?? {};
    return LspWorkspaceEdit(
      changes: raw.map(
        (uri, edits) => MapEntry(
          uri,
          (edits as List)
              .map((e) => LspTextEdit.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }
}

/// Result of a `textDocument/prepareRename` request.
class LspPrepareRenameResult {
  const LspPrepareRenameResult({required this.range, this.placeholder});

  final LspRange range;
  final String? placeholder;

  static LspPrepareRenameResult? parseResult(dynamic result) {
    if (result == null) return null;
    if (result is! Map<String, dynamic>) return null;
    if (result.containsKey('range')) {
      return LspPrepareRenameResult(
        range: LspRange.fromJson(result['range'] as Map<String, dynamic>),
        placeholder: result['placeholder'] as String?,
      );
    }
    return null;
  }
}

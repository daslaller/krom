/// LSP completion protocol types.

/// A single completion item from a `textDocument/completion` response.
class LspCompletionItem {
  const LspCompletionItem({
    required this.label,
    this.detail,
    this.kind,
    this.insertText,
  });

  /// The label shown in the completion list.
  final String label;

  /// Optional detail (e.g. type signature).
  final String? detail;

  /// Completion item kind (1=text, 2=method, 3=function, 6=variable, etc.).
  final int? kind;

  /// Text to insert; defaults to [label] if absent.
  final String? insertText;

  factory LspCompletionItem.fromJson(Map<String, dynamic> json) =>
      LspCompletionItem(
        label: json['label'] as String,
        detail: json['detail'] as String?,
        kind: json['kind'] as int?,
        insertText: json['insertText'] as String?,
      );
}

/// LSP hover protocol types.

/// Result of a `textDocument/hover` request.
class LspHover {
  const LspHover({required this.content});

  /// Plain-text hover content (markdown stripped for simplicity).
  final String content;

  factory LspHover.fromJson(Map<String, dynamic> json) {
    final contents = json['contents'];
    final text = switch (contents) {
      String s => s,
      Map<String, dynamic> m => (m['value'] as String?) ?? '',
      List<dynamic> l when l.isNotEmpty =>
        l.first is String ? l.first as String : ((l.first as Map)['value'] as String? ?? ''),
      _ => '',
    };
    return LspHover(content: text);
  }
}

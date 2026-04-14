import 'diagnostics.dart';

/// LSP definition / navigation protocol types.

/// A location (file URI + range) returned by `textDocument/definition`.
class LspLocation {
  const LspLocation({required this.uri, required this.range});

  final String uri;
  final LspRange range;

  factory LspLocation.fromJson(Map<String, dynamic> json) => LspLocation(
        uri: json['uri'] as String,
        range: LspRange.fromJson(json['range'] as Map<String, dynamic>),
      );
}

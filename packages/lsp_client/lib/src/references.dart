import 'definition.dart';

/// Result of a `textDocument/references` request.
class LspReferenceResult {
  const LspReferenceResult({required this.locations});

  final List<LspLocation> locations;

  static List<LspLocation> parseResult(dynamic result) {
    if (result == null) return const [];
    if (result is! List) return const [];
    return result
        .map((l) => LspLocation.fromJson(l as Map<String, dynamic>))
        .toList();
  }
}

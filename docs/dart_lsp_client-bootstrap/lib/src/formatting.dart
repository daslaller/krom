import 'diagnostics.dart';

/// A single text edit returned by formatting requests.
class LspTextEdit {
  const LspTextEdit({required this.range, required this.newText});

  final LspRange range;
  final String newText;

  factory LspTextEdit.fromJson(Map<String, dynamic> json) => LspTextEdit(
        range: LspRange.fromJson(json['range'] as Map<String, dynamic>),
        newText: json['newText'] as String,
      );

  static List<LspTextEdit> parseResult(dynamic result) {
    if (result == null) return const [];
    if (result is! List) return const [];
    return result
        .map((e) => LspTextEdit.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Applies [edits] to [text] in reverse offset order so ranges stay valid.
String applyTextEdits(String text, List<LspTextEdit> edits) {
  if (edits.isEmpty) return text;

  final sorted = [...edits]..sort((a, b) {
      final aStart = _positionOffset(text, a.range.start);
      final bStart = _positionOffset(text, b.range.start);
      return bStart.compareTo(aStart);
    });

  var result = text;
  for (final edit in sorted) {
    final start = _positionOffset(result, edit.range.start);
    final end = _positionOffset(result, edit.range.end);
    result = result.replaceRange(start, end, edit.newText);
  }
  return result;
}

int _positionOffset(String text, LspPosition pos) {
  var offset = 0;
  var line = 0;
  for (var i = 0; i < text.length && line < pos.line; i++) {
    if (text[i] == '\n') line++;
    offset = i + 1;
  }
  if (pos.line == 0) return pos.character.clamp(0, text.length);

  var lineStart = 0;
  line = 0;
  for (var i = 0; i < text.length; i++) {
    if (line == pos.line) {
      lineStart = i;
      break;
    }
    if (text[i] == '\n') line++;
  }
  return (lineStart + pos.character).clamp(0, text.length);
}

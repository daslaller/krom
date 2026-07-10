import 'diagnostics.dart';

/// Text document synchronization types for LSP `textDocument/didChange`.
///
/// [TextDocumentSyncKind] values:
///   0 = None, 1 = Full, 2 = Incremental

enum TextDocumentSyncKind {
  none(0),
  full(1),
  incremental(2);

  const TextDocumentSyncKind(this.value);
  final int value;
}

/// A single content change in a `textDocument/didChange` notification.
///
/// When [range] is null the entire document is replaced with [text] (full sync).
/// When [range] is set, [text] replaces only that region (incremental sync).
class TextDocumentContentChangeEvent {
  const TextDocumentContentChangeEvent({
    this.range,
    required this.text,
  });

  final LspRange? range;
  final String text;

  Map<String, dynamic> toJson() => {
        if (range != null) 'range': _rangeToJson(range!),
        'text': text,
      };

  static Map<String, dynamic> _rangeToJson(LspRange range) => {
        'start': range.start.toJson(),
        'end': range.end.toJson(),
      };
}

/// Computes the minimal incremental change between [oldText] and [newText].
///
/// Returns a single [TextDocumentContentChangeEvent] with a range covering
/// only the changed region, or a full-replacement event when the texts are
/// completely different.
TextDocumentContentChangeEvent computeTextChange(
  String oldText,
  String newText,
) {
  if (oldText == newText) {
    return const TextDocumentContentChangeEvent(text: '');
  }

  var prefixLen = 0;
  final minLen = oldText.length < newText.length ? oldText.length : newText.length;
  while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
    prefixLen++;
  }

  var oldSuffix = oldText.length;
  var newSuffix = newText.length;
  while (oldSuffix > prefixLen &&
      newSuffix > prefixLen &&
      oldText[oldSuffix - 1] == newText[newSuffix - 1]) {
    oldSuffix--;
    newSuffix--;
  }

  final range = _offsetRange(oldText, prefixLen, oldSuffix);
  return TextDocumentContentChangeEvent(
    range: range,
    text: newText.substring(prefixLen, newSuffix),
  );
}

LspRange _offsetRange(String text, int start, int end) => LspRange(
      start: _offsetToPosition(text, start),
      end: _offsetToPosition(text, end),
    );

LspPosition _offsetToPosition(String text, int offset) {
  var line = 0;
  var lineStart = 0;
  final end = offset.clamp(0, text.length);
  for (var i = 0; i < end; i++) {
    if (text[i] == '\n') {
      line++;
      lineStart = i + 1;
    }
  }
  return LspPosition(line: line, character: end - lineStart);
}

/// Text position helpers shared by the editor and services.

/// Offset of the start of [line] (0-based) in [text].
int lineStartOffset(String text, int line) {
  if (line <= 0) return 0;
  var currentLine = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '\n') {
      currentLine++;
      if (currentLine == line) return i + 1;
    }
  }
  return text.length;
}

/// Converts (line, character) to a flat text offset.
int positionToOffset(String text, int line, int character) =>
    lineStartOffset(text, line) + character;

/// Converts a flat offset to (line, character).
(int line, int character) offsetToLineChar(String text, int offset) {
  var line = 0;
  var lineStart = 0;
  final end = offset.clamp(0, text.length);
  for (var i = 0; i < end; i++) {
    if (text[i] == '\n') {
      line++;
      lineStart = i + 1;
    }
  }
  return (line, end - lineStart);
}

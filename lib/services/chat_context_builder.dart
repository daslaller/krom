import '../editor/editor_session.dart';
import '../editor/krom_analyzer.dart';
import '../utils/text_position.dart';

class ChatContextBuilder {
  static String build(EditorSession session) {
    final tab = session.tabController.activeTab;
    if (tab == null) return 'No file open.';

    final buffer = StringBuffer()..writeln('File: ${tab.filePath}');
    final text = tab.codeController.fullText;
    final sel = tab.codeController.selection;

    if (sel.isValid && !sel.isCollapsed) {
      final start = sel.start.clamp(0, text.length);
      final end = sel.end.clamp(0, text.length);
      buffer
        ..writeln('Selection (${end - start} chars):')
        ..writeln(text.substring(start, end));
    } else if (sel.isValid) {
      final offset = sel.baseOffset.clamp(0, text.length);
      final (line, col) = offsetToLineChar(text, offset);
      buffer.writeln('Cursor: line ${line + 1}, column ${col + 1}');
    }

    final analyzer = tab.codeController.analyzer;
    if (analyzer is KromAnalyzer) {
      final issues = analyzer.lastIssues;
      if (issues.isNotEmpty) {
        buffer.writeln('Diagnostics (${issues.length}):');
        for (final issue in issues.take(8)) {
          buffer.writeln(
            '  L${issue.line + 1}: [${issue.type.name}] ${issue.message}',
          );
        }
      }
    }

    return buffer.toString().trim();
  }
}

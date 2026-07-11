import 'package:flutter_code_editor/flutter_code_editor.dart';

/// A diagnostic from any open file, for the Problems panel.
class ProblemEntry {
  const ProblemEntry({
    required this.filePath,
    required this.line,
    required this.message,
    required this.severity,
  });

  final String filePath;
  final int line;
  final String message;
  final IssueType severity;
}

/// Aggregates LSP diagnostics across all tracked files.
class ProblemsCollector {
  ProblemsCollector();

  final Map<String, List<Issue>> _byFile = {};

  void update(String filePath, List<Issue> issues) {
    _byFile[filePath] = issues;
  }

  void remove(String filePath) => _byFile.remove(filePath);

  List<ProblemEntry> all({String filter = '', IssueType? severityFilter}) {
    final lower = filter.toLowerCase();
    final out = <ProblemEntry>[];
    for (final entry in _byFile.entries) {
      for (final issue in entry.value) {
        if (severityFilter != null && issue.type != severityFilter) continue;
        if (lower.isNotEmpty &&
            !issue.message.toLowerCase().contains(lower) &&
            !entry.key.toLowerCase().contains(lower)) {
          continue;
        }
        out.add(
          ProblemEntry(
            filePath: entry.key,
            line: issue.line,
            message: issue.message,
            severity: issue.type,
          ),
        );
      }
    }
    out.sort((a, b) {
      final pathCmp = a.filePath.compareTo(b.filePath);
      if (pathCmp != 0) return pathCmp;
      return a.line.compareTo(b.line);
    });
    return out;
  }

  int get errorCount =>
      _byFile.values.expand((i) => i).where((i) => i.type == IssueType.error).length;

  int get warningCount => _byFile.values
      .expand((i) => i)
      .where((i) => i.type == IssueType.warning)
      .length;
}

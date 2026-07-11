import 'dart:convert';
import 'dart:io';

/// A single ripgrep match in the workspace.
class WorkspaceSearchMatch {
  const WorkspaceSearchMatch({
    required this.filePath,
    required this.line,
    required this.column,
    required this.text,
  });

  final String filePath;
  final int line;
  final int column;
  final String text;
}

/// Runs workspace-wide search via `rg` (ripgrep).
class WorkspaceSearchService {
  Future<List<WorkspaceSearchMatch>> search({
    required String rootPath,
    required String query,
    bool caseSensitive = false,
  }) async {
    if (query.trim().isEmpty) return const [];

    final args = <String>[
      '--json',
      '--line-number',
      '--column',
      '--no-heading',
      if (!caseSensitive) '--ignore-case',
      '--',
      query,
      '.',
    ];

    try {
      final result = await Process.run(
        'rg',
        args,
        workingDirectory: rootPath,
        runInShell: true,
      );
      if (result.exitCode > 1) return const [];

      final matches = <WorkspaceSearchMatch>[];
      final root = rootPath.endsWith(Platform.pathSeparator)
          ? rootPath
          : '$rootPath${Platform.pathSeparator}';

      for (final line in (result.stdout as String).split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          if (json['type'] != 'match') continue;
          final data = json['data'] as Map<String, dynamic>;
          final path = data['path']?['text'] as String? ?? '';
          final lineNum = data['line_number'] as int? ?? 1;
          final submatches = data['submatches'] as List?;
          final col = submatches?.isNotEmpty == true
              ? (submatches!.first as Map)['start'] as int? ?? 0
              : 0;
          final text = data['lines']?['text'] as String? ?? '';
          matches.add(
            WorkspaceSearchMatch(
              filePath: '$root$path',
              line: lineNum - 1,
              column: col,
              text: text.trimRight(),
            ),
          );
        } catch (_) {}
      }
      return matches;
    } catch (_) {
      return const [];
    }
  }
}

import 'dart:io';

/// Lightweight git metadata for the workspace footer.
class GitStatus {
  const GitStatus({this.branch, this.modifiedCount = 0});

  final String? branch;
  final int modifiedCount;

  bool get isRepo => branch != null;
}

class GitService {
  Future<GitStatus> status(String? rootPath) async {
    if (rootPath == null) return const GitStatus();
    try {
      final branchResult = await Process.run(
        'git',
        ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: rootPath,
      );
      if (branchResult.exitCode != 0) return const GitStatus();

      final branch = (branchResult.stdout as String).trim();
      if (branch.isEmpty) return const GitStatus();

      final statusResult = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: rootPath,
      );
      final lines = (statusResult.stdout as String)
          .split('\n')
          .where((l) => l.trim().isNotEmpty);

      return GitStatus(branch: branch, modifiedCount: lines.length);
    } catch (_) {
      return const GitStatus();
    }
  }
}

import 'dart:io';

class GitStatus { const GitStatus({this.branch, this.modifiedCount = 0}); final String? branch; final int modifiedCount; bool get isRepo => branch != null; }
class FileDiffMarkers { const FileDiffMarkers({this.addedLines = const {}, this.removedLines = const {}}); final Set<int> addedLines; final Set<int> removedLines; bool get isEmpty => addedLines.isEmpty && removedLines.isEmpty; }
class BlameLine { const BlameLine({required this.author, required this.summary, required this.date}); final String author; final String summary; final DateTime? date; }

class GitService {
  Future<GitStatus> status(String? root) async {
    if (root == null) return const GitStatus();
    try {
      final b = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD'], workingDirectory: root);
      if (b.exitCode != 0) return const GitStatus();
      final branch = (b.stdout as String).trim(); if (branch.isEmpty) return const GitStatus();
      final s = await Process.run('git', ['status', '--porcelain'], workingDirectory: root);
      return GitStatus(branch: branch, modifiedCount: (s.stdout as String).split('\n').where((l)=>l.trim().isNotEmpty).length);
    } catch (_) { return const GitStatus(); }
  }
  Future<FileDiffMarkers> diffMarkers(String? root, String file) async {
    if (root == null) return const FileDiffMarkers();
    try { final r = await Process.run('git', ['diff', '--unified=0', 'HEAD', '--', file], workingDirectory: root); if (r.exitCode != 0) return const FileDiffMarkers(); return _parse(r.stdout as String); } catch (_) { return const FileDiffMarkers(); }
  }
  Future<bool> stageFile(String? root, String file) async { if (root == null) return false; try { return (await Process.run('git', ['add', '--', file], workingDirectory: root)).exitCode == 0; } catch (_) { return false; } }
  Future<Map<int, BlameLine>> blame(String? root, String file) async {
    if (root == null) return {};
    try { final r = await Process.run('git', ['blame', '--line-porcelain', '--', file], workingDirectory: root); if (r.exitCode != 0) return {}; return _blame(r.stdout as String); } catch (_) { return {}; }
  }
  FileDiffMarkers _parse(String diff) { final a=<int>{}, d=<int>{}; var n=0; for (final raw in diff.split('\n')) { if (raw.startsWith('@@')) { final m=RegExp(r'\+(\d+)').firstMatch(raw); if (m!=null) n=int.parse(m.group(1)!)-1; continue;} if (raw.startsWith('+++')||raw.startsWith('---')||raw.startsWith('diff ')) continue; if (raw.startsWith('+')) { a.add(n); n++; } else if (raw.startsWith('-')) d.add(n); else if (raw.startsWith(' ')) n++; } return FileDiffMarkers(addedLines:a, removedLines:d); }
  Map<int, BlameLine> _blame(String o) { final res=<int,BlameLine>{}; final lines=o.split('\n'); var i=0; while(i<lines.length){ final m=RegExp(r'^[0-9a-f]{7,40}\s+\d+\s+(\d+)\s+(\d+)').firstMatch(lines[i]); if(m==null){i++;continue;} final s=int.parse(m.group(1)!)-1; final c=int.parse(m.group(2)!); String? author; int? t; i++; while(i<lines.length&&!lines[i].startsWith('\t')){ final l=lines[i]; if(l.startsWith('author ')) author=l.substring(7); if(l.startsWith('author-time ')) t=int.tryParse(l.substring(12)); i++; } final dt=t!=null?DateTime.fromMillisecondsSinceEpoch(t*1000):null; final bl=BlameLine(author:author??'unknown', summary:author??'unknown', date:dt); for(var j=0;j<c;j++) res[s+j]=bl; if(i<lines.length&&lines[i].startsWith('\t')) i++; } return res; }
}

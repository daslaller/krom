import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class CommandPaletteController extends ChangeNotifier {
  List<String> _allPaths = [];
  String? _rootPath;
  String _query = '';
  int _selectedIndex = 0;
  List<_ScoredPath> _filtered = [];

  List<String> get filteredPaths => _filtered.map((s) => s.path).toList();
  int get selectedIndex => _selectedIndex;
  String get query => _query;

  void setFiles(List<String> paths, String rootPath) {
    _allPaths = paths;
    _rootPath = rootPath;
    _applyFilter();
  }

  void updateQuery(String query) {
    _query = query;
    _selectedIndex = 0;
    _applyFilter();
  }

  void moveUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      notifyListeners();
    }
  }

  void moveDown() {
    if (_selectedIndex < _filtered.length - 1) {
      _selectedIndex++;
      notifyListeners();
    }
  }

  String? confirm() {
    if (_filtered.isEmpty) return null;
    return _filtered[_selectedIndex].path;
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = _allPaths
          .take(30)
          .map((p) => _ScoredPath(p, 0))
          .toList();
    } else {
      final queryLower = _query.toLowerCase();
      _filtered = _allPaths
          .map((path) {
            final score = _fuzzyScore(
              _relativePath(path).toLowerCase(),
              queryLower,
            );
            return score > 0 ? _ScoredPath(path, score) : null;
          })
          .whereType<_ScoredPath>()
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      if (_filtered.length > 30) _filtered = _filtered.sublist(0, 30);
    }
    if (_selectedIndex >= _filtered.length) {
      _selectedIndex = _filtered.isEmpty ? 0 : _filtered.length - 1;
    }
    notifyListeners();
  }

  String _relativePath(String path) {
    if (_rootPath != null && path.startsWith(_rootPath!)) {
      return path.substring(_rootPath!.length + 1);
    }
    return p.basename(path);
  }

  static int _fuzzyScore(String text, String query) {
    var textIdx = 0;
    var queryIdx = 0;
    var score = 0;
    var consecutive = 0;

    while (textIdx < text.length && queryIdx < query.length) {
      if (text[textIdx] == query[queryIdx]) {
        queryIdx++;
        consecutive++;
        score += consecutive * 2;
        // Bonus for matching after separator
        if (textIdx == 0 ||
            text[textIdx - 1] == '/' ||
            text[textIdx - 1] == '\\' ||
            text[textIdx - 1] == '_' ||
            text[textIdx - 1] == '.') {
          score += 5;
        }
      } else {
        consecutive = 0;
      }
      textIdx++;
    }

    return queryIdx == query.length ? score : 0;
  }
}

class _ScoredPath {
  _ScoredPath(this.path, this.score);
  final String path;
  final int score;
}

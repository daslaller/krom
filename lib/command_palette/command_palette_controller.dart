import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'palette_item.dart';

class CommandPaletteController extends ChangeNotifier {
  List<PaletteCommandItem> _commands = const [];
  List<String> _allPaths = [];
  List<String> _recentPaths = [];
  String? _rootPath;
  String _query = '';
  int _selectedIndex = 0;
  List<PaletteItem> _filtered = [];

  List<PaletteItem> get items => _filtered;
  int get selectedIndex => _selectedIndex;
  String get query => _query;

  void setCommands(List<PaletteCommandItem> commands) {
    _commands = commands;
    _applyFilter();
  }

  void setFiles(List<String> paths, String rootPath) {
    _allPaths = paths;
    _rootPath = rootPath;
    _applyFilter();
  }

  void noteRecentFile(String path) {
    _recentPaths.remove(path);
    _recentPaths.insert(0, path);
    if (_recentPaths.length > 12) {
      _recentPaths = _recentPaths.sublist(0, 12);
    }
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

  void setSelectedIndex(int index) {
    if (index < 0 || index >= _filtered.length || index == _selectedIndex) {
      return;
    }
    _selectedIndex = index;
    notifyListeners();
  }

  PaletteItem? confirm() {
    if (_filtered.isEmpty) return null;
    return _filtered[_selectedIndex];
  }

  void _applyFilter() {
    final queryLower = _query.trim().toLowerCase();

    if (queryLower.isEmpty) {
      final recentFiles = _recentPaths
          .where(_allPaths.contains)
          .map(
            (path) => PaletteFileItem(
              path: path,
              label: _relativePath(path),
              hint: p.extension(path).replaceFirst('.', ''),
              score: 500,
            ),
          )
          .toList();

      _filtered = [
        ..._commands,
        ...recentFiles,
        ..._allPaths
            .where((path) => !_recentPaths.contains(path))
            .take(20)
            .map(
              (path) => PaletteFileItem(
                path: path,
                label: _relativePath(path),
                hint: p.extension(path).replaceFirst('.', ''),
                score: 100,
              ),
            ),
      ];
    } else {
      final commandMatches = _commands
          .where((c) => c.label.toLowerCase().contains(queryLower))
          .map(
            (c) => PaletteCommandItem(
              id: c.id,
              label: c.label,
              hint: c.hint,
              score: 2000 + _fuzzyScore(c.label.toLowerCase(), queryLower),
            ),
          );

      final fileMatches = _allPaths
          .map((path) {
            final rel = _relativePath(path).toLowerCase();
            final score = _fuzzyScore(rel, queryLower);
            return score > 0
                ? PaletteFileItem(
                    path: path,
                    label: _relativePath(path),
                    hint: p.extension(path).replaceFirst('.', ''),
                    score: score,
                  )
                : null;
          })
          .whereType<PaletteFileItem>();

      _filtered = [...commandMatches, ...fileMatches]
        ..sort((a, b) => b.score.compareTo(a.score));
      if (_filtered.length > 40) {
        _filtered = _filtered.sublist(0, 40);
      }
    }

    if (_selectedIndex >= _filtered.length) {
      _selectedIndex = _filtered.isEmpty ? 0 : _filtered.length - 1;
    }
    notifyListeners();
  }

  String _relativePath(String path) {
    if (_rootPath != null && path.startsWith(_rootPath!)) {
      return path.substring(_rootPath!.length + 1).replaceAll('\\', '/');
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

import 'package:flutter/foundation.dart';

/// A single match range in a text buffer (flat offsets).
class TextMatch {
  const TextMatch({required this.start, required this.end});

  final int start;
  final int end;

  int get length => end - start;
}

/// In-file find/replace state for the active editor tab.
class FindReplaceController extends ChangeNotifier {
  String query = '';
  String replacement = '';
  bool caseSensitive = false;
  bool useRegex = false;
  int currentIndex = 0;
  List<TextMatch> matches = const [];

  void setQuery(String value) {
    query = value;
    _recompute();
  }

  void setReplacement(String value) {
    replacement = value;
    notifyListeners();
  }

  void toggleCaseSensitive() {
    caseSensitive = !caseSensitive;
    _recompute();
  }

  void toggleRegex() {
    useRegex = !useRegex;
    _recompute();
  }

  void findIn(String text, {int? startFrom}) {
    _recompute(text: text, startFrom: startFrom);
  }

  void _recompute({String? text, int? startFrom}) {
    final source = text;
    if (source == null || query.isEmpty) {
      matches = const [];
      currentIndex = 0;
      notifyListeners();
      return;
    }

    final found = <TextMatch>[];
    if (useRegex) {
      try {
        final pattern = RegExp(
          query,
          caseSensitive: caseSensitive,
        );
        for (final m in pattern.allMatches(source)) {
          found.add(TextMatch(start: m.start, end: m.end));
        }
      } catch (_) {
        matches = const [];
        currentIndex = 0;
        notifyListeners();
        return;
      }
    } else {
      final needle = caseSensitive ? query : query.toLowerCase();
      final haystack = caseSensitive ? source : source.toLowerCase();
      var i = 0;
      while (i <= haystack.length - needle.length) {
        final at = haystack.indexOf(needle, i);
        if (at < 0) break;
        found.add(TextMatch(start: at, end: at + needle.length));
        i = at + (needle.isEmpty ? 1 : needle.length);
      }
    }

    matches = found;
    if (matches.isEmpty) {
      currentIndex = 0;
    } else if (startFrom != null) {
      currentIndex = _indexAtOrAfter(startFrom);
    } else if (currentIndex >= matches.length) {
      currentIndex = matches.length - 1;
    }
    notifyListeners();
  }

  int _indexAtOrAfter(int offset) {
    for (var i = 0; i < matches.length; i++) {
      if (matches[i].start >= offset) return i;
    }
    return 0;
  }

  TextMatch? get currentMatch =>
      matches.isEmpty ? null : matches[currentIndex.clamp(0, matches.length - 1)];

  int next() {
    if (matches.isEmpty) return 0;
    currentIndex = (currentIndex + 1) % matches.length;
    notifyListeners();
    return currentIndex;
  }

  int previous() {
    if (matches.isEmpty) return 0;
    currentIndex = (currentIndex - 1 + matches.length) % matches.length;
    notifyListeners();
    return currentIndex;
  }

  /// Replaces the current match. Returns updated text or null if no match.
  String? replaceCurrent(String text) {
    final match = currentMatch;
    if (match == null) return null;
    final updated = text.replaceRange(match.start, match.end, replacement);
    _recompute(text: updated, startFrom: match.start);
    return updated;
  }

  /// Replaces all matches. Returns updated text or null if no matches.
  String? replaceAll(String text) {
    if (matches.isEmpty) return null;
    var result = text;
    for (final match in matches.reversed) {
      result = result.replaceRange(match.start, match.end, replacement);
    }
    matches = const [];
    currentIndex = 0;
    notifyListeners();
    return result;
  }
}

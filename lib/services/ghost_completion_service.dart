import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/lsp_service.dart';
import 'anthropic_service.dart';
import 'settings_service.dart';

class GhostCompletionService extends ChangeNotifier {
  GhostCompletionService({
    required SettingsService settings,
    AnthropicService? anthropic,
  })  : _settings = settings,
        _anthropic = anthropic ?? AnthropicService(settings);

  final SettingsService _settings;
  final AnthropicService _anthropic;

  String? _suggestion;
  Timer? _debounce;

  String? get suggestion => _suggestion;

  static String? heuristicSuffix(String fileText, int cursorOffset) {
    if (cursorOffset <= 0 || cursorOffset > fileText.length) return null;

    final before = fileText.substring(0, cursorOffset);
    final match = RegExp(r'[\w$]+$').firstMatch(before);
    if (match == null) return null;

    final prefix = match.group(0)!;
    if (prefix.length < 2) return null;

    final tokenPattern = RegExp(r'[\w$]+');
    String? best;
    for (final m in tokenPattern.allMatches(fileText)) {
      final token = m.group(0)!;
      if (token.length <= prefix.length) continue;
      if (!token.startsWith(prefix)) continue;
      if (cursorOffset > m.start && cursorOffset <= m.end) continue;
      final suffix = token.substring(prefix.length);
      if (best == null || suffix.length < best.length) best = suffix;
    }
    return best;
  }

  void schedule({
    required String fileText,
    required int cursorOffset,
    required String filePath,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_refresh(
        fileText: fileText,
        cursorOffset: cursorOffset,
        filePath: filePath,
      ));
    });
  }

  Future<void> _refresh({
    required String fileText,
    required int cursorOffset,
    required String filePath,
  }) async {
    var next = heuristicSuffix(fileText, cursorOffset);

    if (next == null && _settings.hasAnthropicKey) {
      final languageId = LspService.languageIdFromPath(filePath) ?? 'text';
      next = await _anthropic.completeLine(
        prefix: fileText.substring(0, cursorOffset),
        languageId: languageId,
      );
    }

    if (_suggestion != next) {
      _suggestion = next;
      notifyListeners();
    }
  }

  void clear() {
    _debounce?.cancel();
    if (_suggestion != null) {
      _suggestion = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

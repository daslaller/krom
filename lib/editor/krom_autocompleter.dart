import 'dart:async';

import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../services/lsp_service.dart';
import '../utils/text_position.dart';

/// Feeds LSP completions into a [CodeController]'s built-in [Autocompleter].
///
/// Call [onChanged] on every editor text change. Results are debounced (200 ms)
/// and injected via [Autocompleter.setCustomWords].
class KromAutocompleter {
  KromAutocompleter({
    required LspService lspService,
    required String filePath,
  })  : _lspService = lspService,
        _filePath = filePath;

  final LspService _lspService;
  final String _filePath;
  Timer? _debounce;

  /// Call this from the editor's onChange handler.
  void onChanged(CodeController controller) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _requestCompletions(controller);
    });
  }

  Future<void> _requestCompletions(CodeController controller) async {
    final offset = controller.selection.baseOffset;
    if (offset < 0) return;

    final text = controller.fullText;
    final (line, character) = offsetToLineChar(text, offset);

    final items = await _lspService.getCompletions(_filePath, line, character);
    if (items.isEmpty) return;

    controller.autocompleter
        .setCustomWords(items.map((i) => i.insertText ?? i.label).toList());
  }

  void dispose() {
    _debounce?.cancel();
  }
}

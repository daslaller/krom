import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/lsp_service.dart';
import '../../../utils/text_position.dart';
import '../ide_fonts.dart';
import '../ide_concepts_theme.dart';

class CodeLensOverlay extends StatefulWidget {
  const CodeLensOverlay({
    super.key,
    required this.theme,
    required this.lspService,
    required this.filePath,
    required this.fileText,
    required this.cursorOffset,
    required this.lineHeight,
    required this.gutterWidth,
    required this.horizontalPad,
    required this.verticalPad,
    this.onReferencesTap,
  });

  final IdeConceptsTheme theme;
  final LspService? lspService;
  final String filePath;
  final String fileText;
  final int cursorOffset;
  final double lineHeight;
  final double gutterWidth;
  final double horizontalPad;
  final double verticalPad;
  final void Function(int line, int character)? onReferencesTap;

  @override
  State<CodeLensOverlay> createState() => _CodeLensOverlayState();
}

class _CodeLensOverlayState extends State<CodeLensOverlay> {
  Timer? _debounce;
  int? _refCount;
  int? _lensLine;
  int? _lensCharacter;

  @override
  void initState() {
    super.initState();
    _scheduleLookup();
  }

  @override
  void didUpdateWidget(covariant CodeLensOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cursorOffset != widget.cursorOffset ||
        oldWidget.fileText != widget.fileText) {
      _scheduleLookup();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleLookup() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _lookup);
  }

  Future<void> _lookup() async {
    final lsp = widget.lspService;
    if (lsp == null || !lsp.isAvailable) {
      if (mounted) setState(() => _refCount = null);
      return;
    }
    final offset = widget.cursorOffset.clamp(0, widget.fileText.length);
    final (line, character) = offsetToLineChar(widget.fileText, offset);
    final refs = await lsp.getReferences(widget.filePath, line, character);
    if (!mounted) return;
    setState(() {
      _refCount = refs.isEmpty ? null : refs.length;
      _lensLine = line;
      _lensCharacter = character;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = _refCount;
    if (count == null || _lensLine == null) return const SizedBox.shrink();

    return Positioned(
      left: widget.gutterWidth + widget.horizontalPad,
      top: (widget.verticalPad + _lensLine! * widget.lineHeight - 18)
          .clamp(0.0, double.infinity),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final ch = _lensCharacter;
            if (ch != null) widget.onReferencesTap?.call(_lensLine!, ch);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: widget.theme.rowActive.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count references',
              style: IdeFonts.mono(fontSize: 11, color: widget.theme.accent),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/lsp_service.dart';
import '../theme/krom_colors.dart';
import '../utils/text_position.dart';
import '../theme/typography.dart';
import 'krom_code_controller.dart';

/// Shows an LSP hover tooltip near the cursor when the user pauses over a symbol.
class HoverTooltip extends StatefulWidget {
  const HoverTooltip({
    super.key,
    required this.lspService,
    required this.controller,
    required this.filePath,
    required this.child,
  });

  final LspService lspService;
  final KromCodeController controller;
  final String filePath;
  final Widget child;

  @override
  State<HoverTooltip> createState() => _HoverTooltipState();
}

class _HoverTooltipState extends State<HoverTooltip> {
  String? _hoverText;
  Offset? _hoverOffset;
  bool _requestPending = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MouseRegion(
          onHover: _onHover,
          onExit: (_) => setState(() {
            _hoverText = null;
            _hoverOffset = null;
          }),
          child: widget.child,
        ),
        if (_hoverText != null && _hoverOffset != null)
          Positioned(
            left: _hoverOffset!.dx + 16,
            top: _hoverOffset!.dy + 24,
            child: Material(
              elevation: 4,
              color: KromColors.surface,
              borderRadius: BorderRadius.circular(4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _hoverText!,
                    style: KromTypography.code(
                      color: KromColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onHover(PointerHoverEvent event) async {
    if (_requestPending) return;
    _requestPending = true;

    final offset = widget.controller.selection.baseOffset;
    if (offset < 0) {
      _requestPending = false;
      return;
    }

    final text = widget.controller.fullText;
    final (line, character) = offsetToLineChar(text, offset);

    final hover = await widget.lspService.getHover(
      widget.filePath,
      line,
      character,
    );

    if (!mounted) return;
    _requestPending = false;

    if (hover == null || hover.content.trim().isEmpty) {
      setState(() {
        _hoverText = null;
        _hoverOffset = null;
      });
      return;
    }

    setState(() {
      _hoverText = hover.content;
      _hoverOffset = event.localPosition;
    });
  }
}

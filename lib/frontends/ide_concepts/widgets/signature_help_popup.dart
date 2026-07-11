import 'package:flutter/material.dart';
import 'package:lsp_client/lsp_client.dart';

import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

/// Parameter hint popup from LSP `textDocument/signatureHelp`.
class IdeConceptsSignatureHelpPopup extends StatelessWidget {
  const IdeConceptsSignatureHelpPopup({
    super.key,
    required this.theme,
    required this.help,
    this.offset = Offset.zero,
  });

  final IdeConceptsTheme theme;
  final LspSignatureHelp help;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (help.signatures.isEmpty) return const SizedBox.shrink();

    final activeIdx = help.activeSignature ?? 0;
    final sig = help.signatures[activeIdx.clamp(0, help.signatures.length - 1)];
    final paramIdx = help.activeParameter ?? 0;

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Material(
        elevation: 6,
        color: theme.panelBg,
        borderRadius: BorderRadius.circular(4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSignatureLabel(sig, paramIdx),
                if (sig.documentation != null && sig.documentation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sig.documentation!,
                      style: IdeFonts.mono(color: theme.muted, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureLabel(LspSignatureInformation sig, int activeParam) {
    final label = sig.label;
    if (sig.parameters.isEmpty) {
      return Text(
        label,
        style: IdeFonts.mono(color: theme.text, fontSize: 12.5),
      );
    }

    // Highlight active parameter in the signature label.
    var searchFrom = 0;
    final spans = <InlineSpan>[];
    for (var i = 0; i < sig.parameters.length; i++) {
      final param = sig.parameters[i];
      final paramLabel = param.displayLabel;
      if (paramLabel.isEmpty) continue;
      final idx = label.indexOf(paramLabel, searchFrom);
      if (idx < 0) continue;
      if (idx > searchFrom) {
        spans.add(TextSpan(text: label.substring(searchFrom, idx)));
      }
      spans.add(
        TextSpan(
          text: paramLabel,
          style: TextStyle(
            color: i == activeParam
                ? (theme.syntax['number'] ?? theme.accent2)
                : theme.text,
            fontWeight: i == activeParam ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      );
      searchFrom = idx + paramLabel.length;
    }
    if (searchFrom < label.length) {
      spans.add(TextSpan(text: label.substring(searchFrom)));
    }

    return Text.rich(
      TextSpan(
        style: IdeFonts.mono(color: theme.text, fontSize: 12.5),
        children: spans,
      ),
    );
  }
}

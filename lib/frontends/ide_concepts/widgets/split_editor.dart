import 'package:flutter/material.dart';
import 'package:lsp_client/lsp_client.dart';
import '../ide_concepts_theme.dart';

import '../../../editor/navigation_pulse.dart';
import '../../../editor/tab_controller.dart';
import '../../../editor/tab_model.dart';
import '../../../services/lsp_service.dart';
import 'code_view.dart';

/// Horizontal or vertical split editor panes sharing one [KromTabController].
enum SplitDirection { none, horizontal, vertical }

/// Two-pane split editor layout.
class SplitEditorView extends StatelessWidget {
  const SplitEditorView({
    super.key,
    required this.theme,
    required this.tabController,
    required this.direction,
    required this.focusOn,
    required this.lspService,
    required this.onChanged,
    this.onSignatureHelp,
    this.navigationPulse,
    this.editorFontSize = 13.5,
    this.editorLineHeight = 24 / 13.5,
    this.secondaryIndex,
  });

  final IdeConceptsTheme theme;
  final KromTabController tabController;
  final SplitDirection direction;
  final bool focusOn;
  final LspService lspService;
  final VoidCallback onChanged;
  final Future<LspSignatureHelp?> Function()? onSignatureHelp;
  final NavigationPulse? navigationPulse;
  final double editorFontSize;
  final double editorLineHeight;
  final int? secondaryIndex;

  @override
  Widget build(BuildContext context) {
    if (direction == SplitDirection.none) {
      return _paneFor(tabController.activeTab);
    }

    final primary = tabController.activeTab;
    final secondary = secondaryIndex != null &&
            secondaryIndex! >= 0 &&
            secondaryIndex! < tabController.tabs.length
        ? tabController.tabs[secondaryIndex!]
        : tabController.tabs.length > 1
            ? tabController.tabs[
                (tabController.activeIndex + 1) % tabController.tabs.length]
            : primary;

    final first = _paneFor(primary, label: primary?.label);
    final second = _paneFor(secondary, label: secondary?.label);

    if (direction == SplitDirection.horizontal) {
      return Column(
        children: [
          Expanded(child: first),
          Divider(height: 1, color: theme.hairline),
          Expanded(child: second),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: first),
        VerticalDivider(width: 1, color: theme.hairline),
        Expanded(child: second),
      ],
    );
  }

  Widget _paneFor(TabModel? tab, {String? label}) {
    if (tab == null) {
      return ColoredBox(color: theme.editorBg);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null && direction != SplitDirection.none)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: theme.tabBarBg,
            child: Text(
              label,
              style: TextStyle(
                color: theme.muted,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        Expanded(
          child: IdeConceptsCodeView(
            key: ValueKey('split-${tab.filePath}'),
            theme: theme,
            tab: tab,
            focusOn: focusOn,
            lspService: lspService,
            navigationPulse: navigationPulse,
            editorFontSize: editorFontSize,
            editorLineHeight: editorLineHeight,
            onChanged: onChanged,
            onSignatureHelp: onSignatureHelp,
          ),
        ),
      ],
    );
  }
}

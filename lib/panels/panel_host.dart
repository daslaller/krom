import 'package:flutter/material.dart';
import '../editor/tab_controller.dart';
import '../theme/krom_colors.dart';
import 'panel_controller.dart';
import 'file_tree/file_tree_panel.dart';
import 'outline/outline_panel.dart';

class PanelHost extends StatelessWidget {
  const PanelHost({
    super.key,
    required this.panelController,
    required this.tabController,
    required this.onFileSelected,
    required this.rootPath,
  });

  final PanelController panelController;
  final KromTabController tabController;
  final void Function(String path) onFileSelected;
  final String? rootPath;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: panelController,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: panelController.isOpen ? 280 : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: KromColors.surface,
          ),
          child: panelController.isOpen ? _buildPanel() : null,
        );
      },
    );
  }

  Widget _buildPanel() {
    return switch (panelController.activePanel) {
      PanelType.fileTree => FileTreePanel(
          rootPath: rootPath,
          onFileSelected: onFileSelected,
        ),
      PanelType.outline => OutlinePanel(tabController: tabController),
      null => const SizedBox.shrink(),
    };
  }
}

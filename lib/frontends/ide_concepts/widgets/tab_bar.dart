import 'package:flutter/material.dart';

import '../../../editor/tab_controller.dart';
import '../ide_concepts_theme.dart';

class IdeConceptsTabBar extends StatelessWidget {
  const IdeConceptsTabBar({
    super.key,
    required this.theme,
    required this.controller,
  });

  final IdeConceptsTheme theme;
  final KromTabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.tabBarBg,
        border: Border(bottom: BorderSide(color: theme.hairline)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.tabs.isEmpty) return const SizedBox.shrink();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < controller.tabs.length; i++)
                  _Tab(
                    theme: theme,
                    label: controller.tabs[i].label,
                    isActive: i == controller.activeIndex,
                    isDirty: controller.tabs[i].isDirty,
                    onTap: () => controller.setActive(i),
                    onClose: () => controller.closeTab(i),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.theme,
    required this.label,
    required this.isActive,
    required this.isDirty,
    required this.onTap,
    required this.onClose,
  });

  final IdeConceptsTheme theme;
  final String label;
  final bool isActive;
  final bool isDirty;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: widget.isActive ? theme.editorBg : Colors.transparent,
            border: Border(
              right: BorderSide(color: theme.hairline),
              top: BorderSide(
                color: widget.isActive ? theme.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: widget.isActive ? theme.text : theme.muted,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 14,
                height: 14,
                child: widget.isDirty && !_hovered
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.accent2,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : _hovered
                    ? GestureDetector(
                        onTap: widget.onClose,
                        child: Icon(Icons.close, size: 13, color: theme.muted),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

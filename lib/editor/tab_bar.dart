import 'package:flutter/material.dart';
import '../theme/krom_colors.dart';
import '../theme/typography.dart';
import 'tab_controller.dart';

class KromTabBar extends StatelessWidget {
  const KromTabBar({super.key, required this.controller});

  final KromTabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: KromColors.tabBarBg,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.tabs.isEmpty) return const SizedBox.shrink();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < controller.tabs.length; i++)
                  _Tab(
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
    required this.label,
    required this.isActive,
    required this.isDirty,
    required this.onTap,
    required this.onClose,
  });

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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isActive
                ? KromColors.tabActive
                : KromColors.tabInactive,
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? KromColors.accent
                    : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: KromTypography.ui(
                  color: widget.isActive
                      ? KromColors.text
                      : KromColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 16,
                height: 16,
                child: widget.isDirty && !_hovered
                    ? Center(
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: KromColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : _hovered
                        ? GestureDetector(
                            onTap: widget.onClose,
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: KromColors.textSecondary,
                            ),
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

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../editor/tab_controller.dart';
import '../file_label.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

/// Tab strip with Tacet-style sliding active indicator and extension coloring.
class IdeConceptsTabBar extends StatefulWidget {
  const IdeConceptsTabBar({
    super.key,
    required this.theme,
    required this.controller,
  });

  final IdeConceptsTheme theme;
  final KromTabController controller;

  @override
  State<IdeConceptsTabBar> createState() => _IdeConceptsTabBarState();
}

class _IdeConceptsTabBarState extends State<IdeConceptsTabBar> {
  final _tabKeys = <GlobalKey>[];
  double _indicatorLeft = 0;
  double _indicatorWidth = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabsChanged);
    super.dispose();
  }

  void _onTabsChanged() {
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
    setState(() {});
  }

  void _syncKeys() {
    while (_tabKeys.length < widget.controller.tabs.length) {
      _tabKeys.add(GlobalKey());
    }
    while (_tabKeys.length > widget.controller.tabs.length) {
      _tabKeys.removeLast();
    }
  }

  void _updateIndicator() {
    final index = widget.controller.activeIndex;
    if (index < 0 || index >= _tabKeys.length) {
      if (_indicatorWidth != 0) {
        setState(() {
          _indicatorLeft = 0;
          _indicatorWidth = 0;
        });
      }
      return;
    }

    final context = _tabKeys[index].currentContext;
    final box = context?.findRenderObject() as RenderBox?;
    final barBox = context?.findAncestorRenderObjectOfType<RenderBox>();
    if (box == null || barBox == null) return;

    final tabOffset = box.localToGlobal(Offset.zero, ancestor: barBox);
    final nextLeft = tabOffset.dx;
    final nextWidth = box.size.width;
    if ((nextLeft - _indicatorLeft).abs() > 0.5 ||
        (nextWidth - _indicatorWidth).abs() > 0.5) {
      setState(() {
        _indicatorLeft = nextLeft;
        _indicatorWidth = nextWidth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      decoration: BoxDecoration(
        color: theme.tabBarBg,
        border: Border(bottom: BorderSide(color: theme.hairline)),
      ),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          _syncKeys();
          if (widget.controller.tabs.isEmpty) return const SizedBox.shrink();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateIndicator();
          });

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 1, color: theme.hairline),
              ),
              if (_indicatorWidth > 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: _indicatorLeft,
                  top: 0,
                  width: _indicatorWidth,
                  height: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.editorBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < widget.controller.tabs.length; i++)
                      _Tab(
                        key: _tabKeys[i],
                        theme: theme,
                        label: widget.controller.tabs[i].label,
                        isActive: i == widget.controller.activeIndex,
                        isDirty: widget.controller.tabs[i].isDirty,
                        onTap: () => widget.controller.setActive(i),
                        onClose: () => widget.controller.closeTab(i),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    super.key,
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
    final parts = FileLabelParts.fromFileName(widget.label);
    final extColor = parts.extKey != null
        ? theme.colorForExtension(parts.extKey)
        : theme.muted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isDirty && !_hovered)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: parts.base,
                      style: IdeFonts.mono(
                        fontSize: 13,
                        color: widget.isActive ? theme.text : theme.muted,
                        weight: widget.isActive ? FontWeight.w500 : null,
                      ),
                    ),
                    if (parts.ext.isNotEmpty)
                      TextSpan(
                        text: parts.ext,
                        style: IdeFonts.mono(
                          fontSize: 13,
                          color: extColor,
                          weight: widget.isActive ? FontWeight.w500 : null,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_hovered)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Text(
                    '×',
                    style: IdeFonts.mono(
                      fontSize: 15,
                      color: theme.muted,
                      weight: FontWeight.w300,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

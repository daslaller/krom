import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';

/// Top chrome with Tacet-style path breadcrumb pill and editor controls.
class IdeConceptsTitleBar extends StatelessWidget {
  const IdeConceptsTitleBar({
    super.key,
    required this.theme,
    required this.workspaceName,
    required this.activePath,
    required this.isDark,
    required this.focusOn,
    required this.onToggleFocus,
    required this.onOpenPalette,
    required this.onToggleTheme,
  });

  final IdeConceptsTheme theme;
  final String workspaceName;
  final String activePath;
  final bool isDark;
  final bool focusOn;
  final VoidCallback onToggleFocus;
  final VoidCallback onOpenPalette;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.topBg,
        border: Border(bottom: BorderSide(color: theme.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.chromeDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _PathBreadcrumb(
            theme: theme,
            workspaceName: workspaceName,
            activePath: activePath,
            onTap: onOpenPalette,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ChromeButton(
                  theme: theme,
                  label: focusOn ? 'exit focus' : 'focus',
                  onTap: onToggleFocus,
                ),
                const SizedBox(width: 8),
                _ChromeButton(
                  theme: theme,
                  label: '⌘K',
                  onTap: onOpenPalette,
                ),
                const SizedBox(width: 8),
                _ThemePill(
                  theme: theme,
                  isDark: isDark,
                  onTap: onToggleTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathBreadcrumb extends StatefulWidget {
  const _PathBreadcrumb({
    required this.theme,
    required this.workspaceName,
    required this.activePath,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final String workspaceName;
  final String activePath;
  final VoidCallback onTap;

  @override
  State<_PathBreadcrumb> createState() => _PathBreadcrumbState();
}

class _PathBreadcrumbState extends State<_PathBreadcrumb> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final displayPath = widget.activePath.isEmpty
        ? widget.workspaceName
        : widget.activePath;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          constraints: const BoxConstraints(minWidth: 280),
          decoration: BoxDecoration(
            color: theme.editorBg,
            border: Border.all(
              color: _hovered ? theme.hairlineStrong : theme.hairline,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.basename(widget.workspaceName),
                style: IdeFonts.mono(fontSize: 11, color: theme.iconDim),
              ),
              Text(
                ' / ',
                style: IdeFonts.mono(fontSize: 11, color: theme.iconDim),
              ),
              Flexible(
                child: Text(
                  displayPath,
                  overflow: TextOverflow.ellipsis,
                  style: IdeFonts.mono(fontSize: 11.5, color: theme.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChromeButton extends StatefulWidget {
  const _ChromeButton({
    required this.theme,
    required this.label,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ChromeButton> createState() => _ChromeButtonState();
}

class _ChromeButtonState extends State<_ChromeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered ? widget.theme.hairlineStrong : widget.theme.hairline,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: IdeFonts.mono(
              fontSize: 11,
              color: _hovered ? widget.theme.text : widget.theme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePill extends StatefulWidget {
  const _ThemePill({
    required this.theme,
    required this.isDark,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_ThemePill> createState() => _ThemePillState();
}

class _ThemePillState extends State<_ThemePill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.85 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: widget.theme.togglePillBg,
              border: Border.all(color: widget.theme.hairline),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.theme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isDark ? 'Dark' : 'Light',
                  style: IdeFonts.mono(
                    fontSize: 11,
                    color: widget.theme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

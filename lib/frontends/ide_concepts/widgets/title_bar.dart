import 'package:flutter/material.dart';

import '../ide_concepts_theme.dart';

/// Top chrome strip matching the Beautiful IDE v2 mockup: traffic dots,
/// active file path, focus toggle, palette shortcut, and theme pill.
class IdeConceptsTitleBar extends StatelessWidget {
  const IdeConceptsTitleBar({
    super.key,
    required this.theme,
    required this.activePath,
    required this.isDark,
    required this.focusOn,
    required this.onToggleFocus,
    required this.onOpenPalette,
    required this.onToggleTheme,
  });

  final IdeConceptsTheme theme;
  final String activePath;
  final bool isDark;
  final bool focusOn;
  final VoidCallback onToggleFocus;
  final VoidCallback onOpenPalette;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 7),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: theme.chromeDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            activePath,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.02 * 12,
              color: theme.muted,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ChromeButton(
                  theme: theme,
                  label: focusOn ? 'Exit Focus' : 'Focus',
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
            border: Border.all(color: widget.theme.hairline),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
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
        child: Opacity(
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
                  style: TextStyle(fontSize: 11, color: widget.theme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

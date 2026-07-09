import 'package:flutter/material.dart';

import '../ide_concepts_theme.dart';

/// Decorative chrome strip at the top of the window: three faint dots
/// (matches the mockup — not functional window controls, since Krom
/// keeps the native OS window frame), a centered label, and a light/dark
/// toggle where the mockup reserved a symmetric 44px spacer.
class IdeConceptsTitleBar extends StatelessWidget {
  const IdeConceptsTitleBar({
    super.key,
    required this.theme,
    required this.label,
    required this.isDark,
    required this.onToggleTheme,
  });

  final IdeConceptsTheme theme;
  final String label;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.topBg,
        border: Border(bottom: BorderSide(color: theme.hairline)),
      ),
      child: Row(
        children: [
          Row(
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
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.02 * 12,
                color: theme.muted,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ThemeToggle(
                theme: theme,
                isDark: isDark,
                onTap: onToggleTheme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({
    required this.theme,
    required this.isDark,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: isDark
              ? 'Switch to Paper Light'
              : 'Switch to Midnight Indigo',
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 16,
            color: theme.muted,
          ),
        ),
      ),
    );
  }
}

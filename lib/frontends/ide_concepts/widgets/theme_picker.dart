import 'dart:ui';

import 'package:flutter/material.dart';

import '../ide_concepts_theme.dart';
import '../ide_concepts_themes.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

/// Visual theme picker with accent swatches and accessibility toggles.
class IdeConceptsThemePicker extends StatefulWidget {
  const IdeConceptsThemePicker({
    super.key,
    required this.theme,
    required this.activeThemeId,
    required this.accentIndex,
    required this.highContrast,
    required this.themeSyncOs,
    required this.onSelect,
    required this.onAccentIndex,
    required this.onHighContrast,
    required this.onThemeSyncOs,
    required this.onDismiss,
  });

  final IdeConceptsTheme theme;
  final String activeThemeId;
  final int accentIndex;
  final bool highContrast;
  final bool themeSyncOs;
  final void Function(String themeId) onSelect;
  final void Function(int index) onAccentIndex;
  final void Function(bool value) onHighContrast;
  final void Function(bool value) onThemeSyncOs;
  final VoidCallback onDismiss;

  @override
  State<IdeConceptsThemePicker> createState() => _IdeConceptsThemePickerState();
}

class _IdeConceptsThemePickerState extends State<IdeConceptsThemePicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: KromMotion.paletteDuration,
  )..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: KromMotion.paletteCurve),
    );
    final fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    return GestureDetector(
      onTap: widget.onDismiss,
      child: ColoredBox(
        color: theme.veil,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: Material(
                    color: theme.panelBg,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 16,
                    child: Container(
                      width: 560,
                      constraints: const BoxConstraints(maxHeight: 520),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.hairlineStrong),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Themes',
                            style: IdeFonts.mono(
                              color: theme.text,
                              fontSize: 14,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ToggleRow(
                            theme: theme,
                            label: 'High contrast',
                            value: widget.highContrast,
                            onChanged: widget.onHighContrast,
                          ),
                          _ToggleRow(
                            theme: theme,
                            label: 'Sync with OS',
                            value: widget.themeSyncOs,
                            onChanged: widget.onThemeSyncOs,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accent',
                            style: IdeFonts.mono(
                              color: theme.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              for (var i = 0; i < 4; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _AccentSwatch(
                                    color: theme.resolvedAccentVariants[i],
                                    selected: widget.accentIndex == i,
                                    onTap: () => widget.onAccentIndex(i),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final entry in IdeConceptsThemes.all)
                                    _ThemeCard(
                                      entry: entry,
                                      active: entry.id ==
                                          IdeConceptsThemes.normalizeId(
                                            widget.activeThemeId,
                                          ),
                                      onTap: () => widget.onSelect(entry.id),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: widget.onDismiss,
                              child: Text(
                                'Close',
                                style: IdeFonts.mono(color: theme.muted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IdeConceptsTheme theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: IdeFonts.mono(color: theme.text, fontSize: 12),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: theme.accent,
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.black26,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  const _ThemeCard({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final IdeConceptsThemeEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.entry.theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KromMotion.hoverDuration,
          width: 148,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovered ? t.rowHover : t.togglePillBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.active ? t.accent : t.hairline,
              width: widget.active ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Swatch(color: t.editorBg),
                  const SizedBox(width: 4),
                  _Swatch(color: t.accent),
                  const SizedBox(width: 4),
                  _Swatch(color: t.syntax['string'] ?? t.accent2),
                  const SizedBox(width: 4),
                  _Swatch(color: t.syntax['keyword'] ?? t.accent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.name,
                style: IdeFonts.mono(
                  color: t.text,
                  fontSize: 11,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}

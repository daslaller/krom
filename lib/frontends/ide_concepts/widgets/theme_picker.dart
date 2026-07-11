import 'dart:ui';
import 'package:flutter/material.dart';
import '../ide_concepts_theme.dart';
import '../ide_concepts_themes.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

class IdeConceptsThemePicker extends StatefulWidget {
  const IdeConceptsThemePicker({super.key, required this.theme, required this.activeThemeId, required this.accentIndex, required this.highContrast, required this.themeSyncOs, required this.onSelect, required this.onAccentIndex, required this.onHighContrast, required this.onThemeSyncOs, required this.onDismiss});
  final IdeConceptsTheme theme; final String activeThemeId; final int accentIndex; final bool highContrast, themeSyncOs;
  final void Function(String) onSelect; final void Function(int) onAccentIndex; final void Function(bool) onHighContrast, onThemeSyncOs; final VoidCallback onDismiss;
  @override State<IdeConceptsThemePicker> createState() => _S();
}
class _S extends State<IdeConceptsThemePicker> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(vsync: this, duration: KromMotion.paletteDuration)..forward();
  @override void dispose() { _a.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(onTap: widget.onDismiss, child: ColoredBox(color: t.veil, child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: Center(child: GestureDetector(onTap: () {}, child: FadeTransition(opacity: CurvedAnimation(parent: _a, curve: Curves.easeOut), child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: _a, curve: KromMotion.paletteCurve)), child: Material(color: t.panelBg, borderRadius: BorderRadius.circular(12), child: Container(width: 560, constraints: const BoxConstraints(maxHeight: 520), padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Themes', style: IdeFonts.mono(color: t.text, fontSize: 14, weight: FontWeight.w600)),
      SwitchListTile(title: Text('High contrast', style: IdeFonts.mono(color: t.text, fontSize: 12)), value: widget.highContrast, onChanged: widget.onHighContrast),
      SwitchListTile(title: Text('Sync with OS', style: IdeFonts.mono(color: t.text, fontSize: 12)), value: widget.themeSyncOs, onChanged: widget.onThemeSyncOs),
      Row(children: [for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: () => widget.onAccentIndex(i), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: t.resolvedAccentVariants[i], shape: BoxShape.circle, border: Border.all(color: widget.accentIndex == i ? Colors.white : Colors.black26, width: widget.accentIndex == i ? 2 : 1)))))]),
      const SizedBox(height: 12),
      Flexible(child: SingleChildScrollView(child: Wrap(spacing: 12, runSpacing: 12, children: [for (final e in IdeConceptsThemes.all) GestureDetector(onTap: () => widget.onSelect(e.id), child: Container(width: 148, padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: e.id == IdeConceptsThemes.normalizeId(widget.activeThemeId) ? t.accent : t.hairline, width: e.id == IdeConceptsThemes.normalizeId(widget.activeThemeId) ? 1.5 : 1)), child: Text(e.theme.name, style: IdeFonts.mono(color: t.text, fontSize: 11))))]))),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: widget.onDismiss, child: Text('Close', style: IdeFonts.mono(color: t.muted)))),
    ]))))))));
  }
}

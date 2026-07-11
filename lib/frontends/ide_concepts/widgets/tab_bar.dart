import 'package:flutter/material.dart';
import '../../../editor/tab_controller.dart';
import '../file_label.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

class IdeConceptsTabBar extends StatefulWidget {
  const IdeConceptsTabBar({super.key, required this.theme, required this.controller, this.uiFontSize = 13});
  final IdeConceptsTheme theme; final KromTabController controller; final double uiFontSize;
  @override State<IdeConceptsTabBar> createState() => _S();
}
class _S extends State<IdeConceptsTabBar> {
  final _keys = <GlobalKey>[]; double _l = 0, _w = 0;
  @override void initState() { super.initState(); widget.controller.addListener(_c); }
  @override void dispose() { widget.controller.removeListener(_c); super.dispose(); }
  void _c() { while (_keys.length < widget.controller.tabs.length) _keys.add(GlobalKey()); while (_keys.length > widget.controller.tabs.length) _keys.removeLast(); WidgetsBinding.instance.addPostFrameCallback((_) => _u()); setState(() {}); }
  void _u() { final i = widget.controller.activeIndex; if (i < 0 || i >= _keys.length) return; final box = _keys[i].currentContext?.findRenderObject() as RenderBox?; final bar = _keys[i].currentContext?.findAncestorRenderObjectOfType<RenderBox>(); if (box == null || bar == null) return; final o = box.localToGlobal(Offset.zero, ancestor: bar); setState(() { _l = o.dx; _w = box.size.width; }); }
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Container(height: 44, padding: const EdgeInsets.fromLTRB(10, 8, 10, 0), decoration: BoxDecoration(color: t.tabBarBg, border: Border(bottom: BorderSide(color: t.hairline))),
      child: ListenableBuilder(listenable: widget.controller, builder: (_, __) {
        if (widget.controller.tabs.isEmpty) return const SizedBox.shrink();
        WidgetsBinding.instance.addPostFrameCallback((_) => _u());
        return Stack(clipBehavior: Clip.none, children: [
          if (_w > 0) AnimatedPositioned(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic, left: _l, top: 0, width: _w, height: 36, child: DecoratedBox(decoration: BoxDecoration(color: t.editorBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(11))))),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (var i = 0; i < widget.controller.tabs.length; i++) _Tab(key: _keys[i], theme: t, label: widget.controller.tabs[i].label, active: i == widget.controller.activeIndex, dirty: widget.controller.tabs[i].isDirty, flash: widget.controller.lastSavedIndex == i, fs: widget.uiFontSize, onTap: () => widget.controller.setActive(i), onClose: () => widget.controller.closeTab(i))])),
        ]);
      }));
  }
}
class _Tab extends StatefulWidget {
  const _Tab({super.key, required this.theme, required this.label, required this.active, required this.dirty, required this.flash, required this.fs, required this.onTap, required this.onClose});
  final IdeConceptsTheme theme; final String label; final bool active, dirty, flash; final double fs; final VoidCallback onTap, onClose;
  @override State<_Tab> createState() => _TS();
}
class _TS extends State<_Tab> {
  bool _h = false;
  @override Widget build(BuildContext context) {
    final p = FileLabelParts.fromFileName(widget.label);
    return MouseRegion(onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false), child: GestureDetector(onTap: widget.onTap, child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (!_h) AnimatedSwitcher(duration: KromMotion.saveFlashDuration, child: widget.flash ? Icon(Icons.check, key: const ValueKey('c'), size: 12, color: widget.theme.accent2) : widget.dirty ? Container(key: const ValueKey('d'), width: 6, height: 6, decoration: BoxDecoration(color: widget.theme.accent, shape: BoxShape.circle)) : const SizedBox(key: ValueKey('e'), width: 8)),
      if (!_h && (widget.dirty || widget.flash)) const SizedBox(width: 6),
      Text.rich(TextSpan(children: [TextSpan(text: p.base, style: IdeFonts.mono(fontSize: widget.fs, color: widget.active ? widget.theme.text : widget.theme.muted)), if (p.ext.isNotEmpty) TextSpan(text: p.ext, style: IdeFonts.mono(fontSize: widget.fs, color: widget.theme.colorForExtension(p.extKey)))])),
      const SizedBox(width: 8), if (_h) GestureDetector(onTap: widget.onClose, child: Text('×', style: IdeFonts.mono(fontSize: widget.fs + 2, color: widget.theme.muted))),
    ]))));
  }
}

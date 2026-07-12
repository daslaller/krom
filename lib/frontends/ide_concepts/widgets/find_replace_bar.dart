import 'package:flutter/material.dart';

import '../../../editor/find_replace.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

/// Bottom find/replace bar — `Ctrl+F` / `Ctrl+H`.
class IdeConceptsFindReplaceBar extends StatefulWidget {
  const IdeConceptsFindReplaceBar({
    super.key,
    required this.theme,
    required this.controller,
    required this.showReplace,
    this.initialFind = '',
    required this.onFind,
    required this.onNext,
    required this.onPrevious,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
  });

  final IdeConceptsTheme theme;
  final FindReplaceController controller;
  final bool showReplace;
  final String initialFind;
  final VoidCallback onFind;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;
  final VoidCallback onClose;

  @override
  State<IdeConceptsFindReplaceBar> createState() =>
      _IdeConceptsFindReplaceBarState();
}

class _IdeConceptsFindReplaceBarState extends State<IdeConceptsFindReplaceBar>
    with SingleTickerProviderStateMixin {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _findFocus = FocusNode();
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: KromMotion.panelDuration,
  )..forward();

  @override
  void initState() {
    super.initState();
    if (widget.initialFind.isNotEmpty) {
      _findController.text = widget.initialFind;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findFocus.requestFocus();
      _findController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _findController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocus.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _onFindChanged(String value) {
    widget.controller.setQuery(value);
    widget.onFind();
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: IdeFonts.mono(color: widget.theme.muted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: widget.theme.editorBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: widget.theme.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: widget.theme.accent),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final count = widget.controller.matches.length;
    final index = widget.controller.matches.isEmpty
        ? 0
        : widget.controller.currentIndex + 1;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: _slide, curve: KromMotion.panelCurve),
      ),
      child: Material(
        color: theme.panelBg,
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.hairlineStrong)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _findController,
                      focusNode: _findFocus,
                      style: IdeFonts.mono(color: theme.text, fontSize: 12),
                      cursorColor: theme.accent,
                      decoration: _fieldDecoration('Find'),
                      onChanged: _onFindChanged,
                      onSubmitted: (_) => widget.onFind(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count == 0 ? 'No results' : '$index of $count',
                    style: IdeFonts.mono(color: theme.muted, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    theme: theme,
                    icon: Icons.arrow_upward_rounded,
                    tooltip: 'Previous (Shift+F3)',
                    onTap: widget.onPrevious,
                  ),
                  _IconBtn(
                    theme: theme,
                    icon: Icons.arrow_downward_rounded,
                    tooltip: 'Next (F3)',
                    onTap: widget.onNext,
                  ),
                  _ToggleBtn(
                    theme: theme,
                    label: 'Aa',
                    active: widget.controller.caseSensitive,
                    onTap: widget.controller.toggleCaseSensitive,
                  ),
                  _ToggleBtn(
                    theme: theme,
                    label: '.*',
                    active: widget.controller.useRegex,
                    onTap: widget.controller.toggleRegex,
                  ),
                  _IconBtn(
                    theme: theme,
                    icon: Icons.close_rounded,
                    tooltip: 'Close (Esc)',
                    onTap: widget.onClose,
                  ),
                ],
              ),
              if (widget.showReplace) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replaceController,
                        style: IdeFonts.mono(color: theme.text, fontSize: 12),
                        cursorColor: theme.accent,
                        decoration: _fieldDecoration('Replace'),
                        onChanged: widget.controller.setReplacement,
                        onSubmitted: (_) => widget.onReplace(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      theme: theme,
                      label: 'Replace',
                      onTap: widget.onReplace,
                    ),
                    const SizedBox(width: 6),
                    _ActionBtn(
                      theme: theme,
                      label: 'All',
                      onTap: widget.onReplaceAll,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({
    required this.theme,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: KromMotion.hoverDuration,
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: _hovered ? widget.theme.rowHover : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 16, color: widget.theme.muted),
          ),
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatefulWidget {
  const _ToggleBtn({
    required this.theme,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_ToggleBtn> createState() => _ToggleBtnState();
}

class _ToggleBtnState extends State<_ToggleBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KromMotion.hoverDuration,
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: widget.active
                ? widget.theme.rowActive
                : _hovered
                    ? widget.theme.rowHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: IdeFonts.mono(
              color: widget.active ? widget.theme.accent : widget.theme.muted,
              fontSize: 11,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.theme,
    required this.label,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KromMotion.hoverDuration,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? widget.theme.rowActive : widget.theme.togglePillBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: widget.theme.hairline),
          ),
          child: Text(
            widget.label,
            style: IdeFonts.mono(color: widget.theme.text, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

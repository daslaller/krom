import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

class TerminalPanel extends StatefulWidget {
  const TerminalPanel({super.key, required this.theme, required this.workingDirectory});
  final IdeConceptsTheme theme;
  final String? workingDirectory;
  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  Process? _process;
  final _output = <String>[];
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  StreamSubscription<List<int>>? _stdoutSub;
  StreamSubscription<List<int>>? _stderrSub;

  @override
  void initState() {
    super.initState();
    _startShell();
  }

  Future<void> _startShell() async {
    final cwd = widget.workingDirectory ?? Directory.current.path;
    try {
      _process = await Process.start(
        Platform.isWindows ? 'cmd.exe' : 'bash',
        Platform.isWindows ? [] : ['--login'],
        workingDirectory: cwd,
        environment: Platform.environment,
      );
      _append('${Platform.isWindows ? 'cmd' : 'bash'} — $cwd\n');
      _stdoutSub = _process!.stdout.listen((d) => _append(utf8.decode(d, allowMalformed: true)));
      _stderrSub = _process!.stderr.listen((d) => _append(utf8.decode(d, allowMalformed: true)));
    } catch (e) {
      _append('Failed to start shell: $e\n');
    }
  }

  void _append(String text) {
    if (!mounted) return;
    setState(() => _output.add(text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendLine(String line) {
    _process?.stdin.writeln(line);
    _append('> $line\n');
    _inputController.clear();
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _process?.kill();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Column(
      children: [
        Expanded(
          child: Container(
            color: theme.editorBg,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SelectableText(
                _output.join().isEmpty ? 'Starting shell…' : _output.join(),
                style: IdeFonts.mono(color: theme.text, fontSize: 12, height: 1.4),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.hairline)), color: theme.panelBg),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Row(
            children: [
              Text('\$', style: IdeFonts.mono(color: theme.accent, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: IdeFonts.mono(color: theme.text, fontSize: 12),
                  cursorColor: theme.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Enter command…',
                    hintStyle: IdeFonts.mono(color: theme.muted, fontSize: 12),
                  ),
                  onSubmitted: _sendLine,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BottomPanelHost extends StatefulWidget {
  const BottomPanelHost({
    super.key,
    required this.theme,
    required this.visible,
    required this.title,
    required this.child,
    required this.onClose,
  });

  final IdeConceptsTheme theme;
  final bool visible;
  final String title;
  final Widget child;
  final VoidCallback onClose;

  @override
  State<BottomPanelHost> createState() => _BottomPanelHostState();
}

class _BottomPanelHostState extends State<BottomPanelHost> with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(vsync: this, duration: KromMotion.panelDuration);

  @override
  void initState() {
    super.initState();
    if (widget.visible) _slide.forward();
  }

  @override
  void didUpdateWidget(BottomPanelHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _slide.forward(from: 0);
    else if (!widget.visible && oldWidget.visible) _slide.reverse();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _slide.isDismissed) return const SizedBox.shrink();
    final theme = widget.theme;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _slide, curve: KromMotion.panelCurve)),
      child: Material(
        color: theme.panelBg,
        elevation: 8,
        child: Container(
          height: 220,
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.hairlineStrong))),
          child: Column(
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.hairline))),
                child: Row(
                  children: [
                    Text(widget.title, style: IdeFonts.mono(color: theme.muted, fontSize: 11, weight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Icon(Icons.close_rounded, size: 16, color: theme.muted),
                    ),
                  ],
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

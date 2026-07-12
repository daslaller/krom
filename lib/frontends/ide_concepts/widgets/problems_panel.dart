import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:path/path.dart' as p;

import '../../../services/problems_collector.dart';
import '../ide_concepts_theme.dart';
import '../ide_fonts.dart';
import '../krom_motion.dart';

/// Problems panel — `Ctrl+Shift+M`.
class IdeConceptsProblemsPanel extends StatefulWidget {
  const IdeConceptsProblemsPanel({
    super.key,
    required this.theme,
    required this.collector,
    required this.onOpenProblem,
    this.onClose,
  });

  final IdeConceptsTheme theme;
  final ProblemsCollector collector;
  final void Function(ProblemEntry problem) onOpenProblem;
  final VoidCallback? onClose;

  @override
  State<IdeConceptsProblemsPanel> createState() =>
      _IdeConceptsProblemsPanelState();
}

class _IdeConceptsProblemsPanelState extends State<IdeConceptsProblemsPanel> {
  final _filterController = TextEditingController();
  IssueType? _severityFilter;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<ProblemEntry> get _problems => widget.collector.all(
        filter: _filterController.text,
        severityFilter: _severityFilter,
      );

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final problems = _problems;
    return Container(
      decoration: BoxDecoration(
        color: theme.panelBg,
        border: Border(top: BorderSide(color: theme.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Text(
                  'PROBLEMS',
                  style: IdeFonts.mono(
                    color: theme.muted,
                    fontSize: 11,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.collector.errorCount} errors',
                  style: IdeFonts.mono(
                    color: theme.syntax['keyword'] ?? theme.accent,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.collector.warningCount} warnings',
                  style: IdeFonts.mono(color: theme.syntax['number'], fontSize: 11),
                ),
                const Spacer(),
                if (widget.onClose != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: theme.iconDim),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filterController,
                    onChanged: (_) => setState(() {}),
                    style: IdeFonts.mono(color: theme.text, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Filter…',
                      hintStyle: IdeFonts.mono(color: theme.iconDim, fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.hairline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SeverityChip(
                  theme: theme,
                  label: 'All',
                  active: _severityFilter == null,
                  onTap: () => setState(() => _severityFilter = null),
                ),
                _SeverityChip(
                  theme: theme,
                  label: 'E',
                  active: _severityFilter == IssueType.error,
                  color: theme.syntax['keyword'],
                  onTap: () => setState(() => _severityFilter = IssueType.error),
                ),
                _SeverityChip(
                  theme: theme,
                  label: 'W',
                  active: _severityFilter == IssueType.warning,
                  color: theme.syntax['number'],
                  onTap: () =>
                      setState(() => _severityFilter = IssueType.warning),
                ),
              ],
            ),
          ),
          Expanded(
            child: problems.isEmpty
                ? Center(
                    child: Text(
                      'No problems',
                      style: IdeFonts.mono(color: theme.iconDim, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    itemCount: problems.length,
                    itemBuilder: (context, i) => _ProblemRow(
                      theme: theme,
                      problem: problems[i],
                      onTap: () => widget.onOpenProblem(problems[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProblemRow extends StatefulWidget {
  const _ProblemRow({
    required this.theme,
    required this.problem,
    required this.onTap,
  });

  final IdeConceptsTheme theme;
  final ProblemEntry problem;
  final VoidCallback onTap;

  @override
  State<_ProblemRow> createState() => _ProblemRowState();
}

class _ProblemRowState extends State<_ProblemRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final problem = widget.problem;
    final iconColor = switch (problem.severity) {
      IssueType.error => theme.syntax['keyword'] ?? theme.accent,
      IssueType.warning => theme.syntax['number'] ?? theme.accent2,
      _ => theme.iconDim,
    };
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: KromMotion.hoverDuration,
          curve: KromMotion.hoverCurve,
          color: _hovered ? theme.rowHover : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                problem.severity == IssueType.error
                    ? Icons.error_outline
                    : Icons.warning_amber_outlined,
                size: 14,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.message,
                      style: IdeFonts.mono(color: theme.text, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.basename(problem.filePath)}:${problem.line + 1}',
                      style: IdeFonts.mono(color: theme.iconDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.theme,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  final IdeConceptsTheme theme;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.rowActive : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.hairline),
        ),
        child: Text(
          label,
          style: IdeFonts.mono(
            color: active ? (color ?? theme.accent) : theme.iconDim,
            fontSize: 11,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../models/enums.dart';
import '../../models/project_engine.dart';
import '../../models/work.dart';
import '../../services/ai_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'project_chat_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadProjectDetail(widget.project.id);
    });
  }

  Color _riskColor(int sev) => sev >= 3
      ? const Color(0xFFE5484D)
      : sev >= 2
          ? const Color(0xFFF5A524)
          : const Color(0xFF7C8598);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = widget.project;
    final detail = state.detailProjectId == p.id ? state.currentDetail : null;
    final loading = state.detailLoading && detail == null;
    final health = state.projectHealth(p, detail);
    final projTasks =
        state.tasks.where((t) => t.relatedProjectId == p.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProjectChatScreen(
                project: p, context: _chatContext(p, detail, projTasks)))),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Project AI'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                _earlyWarningBanner(context, state, p, detail, projTasks),
                _healthCard(context, p, health),
                const SizedBox(height: 16),
                _dashboard(context, state, p, detail, projTasks),
                const SizedBox(height: 16),
                _healthBreakdown(context, state, p, detail, projTasks),
                const SizedBox(height: 16),
                _adaptSection(context, state, p, detail, projTasks),
                const SizedBox(height: 16),
                if (p.objective.isNotEmpty) ...[
                  _objectiveCard(context, p),
                  const SizedBox(height: 16),
                ],
                _stageRow(context, p),
                const SizedBox(height: 20),
                _milestones(context, state, p, detail, projTasks),
                const SizedBox(height: 20),
                _risks(context, state, p, detail),
                const SizedBox(height: 20),
                _simpleListSection<ProjectAssumption>(
                  context,
                  title: 'Assumptions',
                  items: detail?.assumptions ?? const [],
                  icon: Icons.help_outline,
                  labelOf: (a) => a.statement,
                  subOf: (a) => '${a.confidence}% confidence · ${a.status}',
                  onAdd: () => _addText(context, 'Add an assumption', (v) {
                    state.addProjectAssumption(p.id,
                        ProjectAssumption(id: state.newId('asm'), statement: v));
                  }),
                ),
                const SizedBox(height: 20),
                _financials(context, state, p, detail),
                const SizedBox(height: 20),
                _resources(context, state, p, detail),
                const SizedBox(height: 20),
                _simpleListSection<ProjectDecision>(
                  context,
                  title: 'Decisions',
                  items: detail?.decisions ?? const [],
                  icon: Icons.gavel_outlined,
                  labelOf: (d) => d.decision,
                  subOf: (d) => d.rationale,
                  onAdd: () => _addText(context, 'Log a decision', (v) {
                    state.addProjectDecision(
                        p.id, ProjectDecision(id: state.newId('dec'), decision: v));
                  }),
                ),
                const SizedBox(height: 20),
                _simpleListSection<ProjectLesson>(
                  context,
                  title: 'Lessons learned',
                  items: detail?.lessons ?? const [],
                  icon: Icons.school_outlined,
                  labelOf: (l) => l.lesson,
                  subOf: (l) => l.category,
                  onAdd: () => _addText(context, 'Capture a lesson', (v) {
                    state.addProjectLesson(
                        p.id, ProjectLesson(id: state.newId('les'), lesson: v));
                  }),
                ),
                const SizedBox(height: 20),
                _timeline(context, state, p, detail),
              ],
            ),
    );
  }

  Map<String, dynamic> _chatContext(
      Project p, ProjectDetail? d, List<Task> tasks) {
    return {
      'name': p.name,
      'objective': p.objective,
      'type': p.projectType,
      'status': p.status,
      'deadline': p.deadline.toIso8601String(),
      'milestones': (d?.milestones ?? [])
          .map((m) => {'title': m.title, 'status': m.status})
          .toList(),
      'openTasks': tasks
          .where((t) => !t.isDone)
          .map((t) => {'title': t.title, 'priority': t.priority.label})
          .toList(),
      'risks': (d?.risks ?? [])
          .map((r) => {
                'title': r.title,
                'probability': r.probability,
                'impact': r.impact,
                'status': r.status
              })
          .toList(),
    };
  }

  Widget _healthCard(BuildContext context, Project p, int health) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.brandDeep, AppColors.brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ScoreRing(score: health, size: 80, light: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROJECT HEALTH',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (p.projectType.isNotEmpty)
                      _whitePill(p.projectType),
                    if (p.complexity.isNotEmpty)
                      _whitePill('${p.complexity} complexity'),
                    _whitePill(p.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whitePill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _dashboard(BuildContext context, AppState state, Project p,
      ProjectDetail? d, List<Task> projTasks) {
    final ms = d?.milestones ?? const <Milestone>[];
    final msPct = ms.isEmpty ? 0.0 : ms.where((m) => m.isDone).length / ms.length;
    final tasksPct = projTasks.isEmpty
        ? 0.0
        : projTasks.where((t) => t.isDone).length / projTasks.length;
    final openRisks =
        (d?.risks ?? const []).where((r) => r.status == 'open').length;
    final daysLeft = p.daysToDeadline;

    // Budget: spent (expense lines) vs planned budget.
    final budget = p.budgetAmount ??
        (d?.budget ?? const [])
            .where((b) => b.type == 'budget')
            .fold<double>(0, (s, b) => s + b.amount);
    final spent = (d?.budget ?? const [])
        .where((b) => b.type == 'expense')
        .fold<double>(0, (s, b) => s + b.amount);
    final budgetLeftPct =
        budget > 0 ? ((budget - spent) / budget).clamp(0.0, 1.0) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Next best action
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.bolt, size: 16, color: AppColors.brand),
                SizedBox(width: 6),
                Text('Next best action',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.brand)),
              ]),
              const SizedBox(height: 8),
              Text(_nextBestAction(p, d, projTasks),
                  style: const TextStyle(height: 1.4, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _bar(context, 'Milestones', msPct, const Color(0xFF30A46C)),
            const SizedBox(width: 10),
            _bar(context, 'Tasks', tasksPct, AppColors.accent),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _stat(context, '$openRisks',
                openRisks == 1 ? 'open risk' : 'open risks',
                const Color(0xFFE5484D)),
            _stat(
                context,
                daysLeft < 0 ? '${-daysLeft}' : '$daysLeft',
                daysLeft < 0 ? 'days over' : 'days left',
                daysLeft < 0 ? const Color(0xFFE5484D) : AppColors.brand),
            if (budgetLeftPct != null)
              _stat(context, '${(budgetLeftPct * 100).round()}%',
                  'budget left', const Color(0xFFF5A524)),
          ],
        ),
      ],
    );
  }

  String _nextBestAction(Project p, ProjectDetail? d, List<Task> projTasks) {
    final open = projTasks.where((t) => !t.isClosed).toList()
      ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));
    final overdue = open.where((t) => t.isOverdue).toList();
    if (overdue.isNotEmpty) return 'Clear overdue task: "${overdue.first.title}".';
    final blocked =
        projTasks.where((t) => t.status == TaskStatus.blocked).toList();
    if (blocked.isNotEmpty) return 'Unblock: "${blocked.first.title}".';
    if (open.isNotEmpty) {
      return 'Focus on "${open.first.title}" (${open.first.priority.label}).';
    }
    final nextMs = (d?.milestones ?? const []).where((m) => !m.isDone).toList();
    if (nextMs.isNotEmpty) return 'Advance the "${nextMs.first.title}" milestone.';
    return 'Everything is on track — plan the next milestone.';
  }

  Widget _bar(BuildContext context, String label, double pct, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text('${(pct * 100).round()}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // ---- Early warning (P5) ----------------------------------------------
  List<({String title, String detail})> _warnings(
      AppState state, Project p, ProjectDetail? d, List<Task> projTasks) {
    final w = <({String title, String detail})>[];
    final now = DateTime.now();
    final overdue = projTasks.where((t) => t.isOverdue).toList();
    if (overdue.isNotEmpty) {
      w.add((
        title: '${overdue.length} overdue task(s)',
        detail: '"${overdue.first.title}" — clear it to protect the timeline.'
      ));
    }
    final blocked =
        projTasks.where((t) => t.status == TaskStatus.blocked).toList();
    if (blocked.isNotEmpty) {
      w.add((
        title: '${blocked.length} blocked task(s)',
        detail: '"${blocked.first.title}" is blocked.'
      ));
    }
    final lines = d?.budget ?? const <BudgetLine>[];
    double sumOf(String t) =>
        lines.where((b) => b.type == t).fold(0.0, (s, b) => s + b.amount);
    final budget = p.budgetAmount ?? sumOf('budget');
    if (budget > 0 && sumOf('expense') + sumOf('committed') > budget) {
      w.add((
        title: 'Budget overrun risk',
        detail: 'Projected cost exceeds the budget.'
      ));
    }
    final lateMs = (d?.milestones ?? const <Milestone>[])
        .where((m) => !m.isDone && m.dueDate != null && m.dueDate!.isBefore(now))
        .toList();
    if (lateMs.isNotEmpty) {
      w.add((
        title: '${lateMs.length} milestone(s) past due',
        detail: '"${lateMs.first.title}" is overdue.'
      ));
    }
    final atRisk = (d?.assumptions ?? const <ProjectAssumption>[])
        .where((a) => a.status != 'holding')
        .toList();
    if (atRisk.isNotEmpty) {
      w.add((
        title: 'Assumption at risk',
        detail: '"${atRisk.first.statement}".'
      ));
    }
    if (p.daysToDeadline < 0 &&
        p.status != 'Done' &&
        p.status != 'Completed') {
      w.add((
        title: 'Project past deadline',
        detail: '${-p.daysToDeadline} days over target.'
      ));
    }
    return w;
  }

  Widget _earlyWarningBanner(BuildContext context, AppState state, Project p,
      ProjectDetail? detail, List<Task> projTasks) {
    final w = _warnings(state, p, detail, projTasks);
    if (w.isEmpty) return const SizedBox.shrink();
    const red = Color(0xFFE5484D);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: red.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.warning_amber_rounded, size: 16, color: red),
              SizedBox(width: 6),
              Text('Early warnings',
                  style: TextStyle(fontWeight: FontWeight.w700, color: red)),
            ]),
            const SizedBox(height: 10),
            ...w.take(4).map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 8),
                        child: Icon(Icons.circle, size: 6, color: red),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(it.detail,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ---- Health breakdown (P5) -------------------------------------------
  Map<String, int> _breakdown(
      Project p, ProjectDetail? d, List<Task> projTasks) {
    final overdue = projTasks.where((t) => t.isOverdue).length;
    var schedule = 100 - overdue * 12 - (p.daysToDeadline < 0 ? 30 : 0);
    final doneT = projTasks.where((t) => t.isDone).length;
    final taskPct = projTasks.isEmpty ? 1.0 : doneT / projTasks.length;
    final ms = d?.milestones ?? const <Milestone>[];
    final msPct =
        ms.isEmpty ? taskPct : ms.where((m) => m.isDone).length / ms.length;
    final execution = ((taskPct * 0.5 + msPct * 0.5) * 100).round();
    final lines = d?.budget ?? const <BudgetLine>[];
    double sumOf(String t) =>
        lines.where((b) => b.type == t).fold(0.0, (s, b) => s + b.amount);
    final bAmt = p.budgetAmount ?? sumOf('budget');
    var budget = 100;
    if (bAmt > 0) {
      final projected = sumOf('expense') + sumOf('committed');
      budget = (100 - ((projected - bAmt) / bAmt * 100)).round();
    }
    final openRisks =
        (d?.risks ?? const <ProjectRisk>[]).where((r) => r.status == 'open');
    final high = openRisks.where((r) => r.severity >= 3).length;
    var risk = 100 - high * 20 - (openRisks.length - high) * 8;
    final brokenA = (d?.assumptions ?? const <ProjectAssumption>[])
        .where((a) => a.status == 'broken')
        .length;
    risk -= brokenA * 15;
    final resCount = (d?.resources ?? const []).length;
    final resources = resCount >= 3 ? 90 : (resCount == 0 ? 60 : 78);
    int c(int v) => v.clamp(0, 100);
    final overall =
        ((c(schedule) + execution + c(budget) + c(risk) + resources) / 5)
            .round();
    return {
      'Overall': overall,
      'Schedule': c(schedule),
      'Execution': c(execution),
      'Budget': c(budget),
      'Risk': c(risk),
      'Resources': resources,
    };
  }

  Widget _healthBreakdown(BuildContext context, AppState state, Project p,
      ProjectDetail? detail, List<Task> projTasks) {
    final b = _breakdown(p, detail, projTasks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Health breakdown'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: b.entries
                  .where((e) => e.key != 'Overall')
                  .map((e) => _hbRow(context, e.key, e.value))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hbRow(BuildContext context, String label, int score) {
    final c = score >= 80
        ? const Color(0xFF30A46C)
        : score >= 60
            ? const Color(0xFFF5A524)
            : const Color(0xFFE5484D);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 86, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text('$score',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w700, color: c)),
          ),
        ],
      ),
    );
  }

  // ---- Adapt: replan + scenarios (P5) ----------------------------------
  Widget _adaptSection(BuildContext context, AppState state, Project p,
      ProjectDetail? detail, List<Task> projTasks) {
    final ctx = _chatContext(p, detail, projTasks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Adapt'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openReplan(context, state, p, ctx),
                icon: const Icon(Icons.change_circle_outlined, size: 18),
                label: const Text('Replan'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openScenarios(context, ctx),
                icon: const Icon(Icons.alt_route_outlined, size: 18),
                label: const Text('Scenarios'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openReplan(BuildContext context, AppState state, Project p,
      Map<String, dynamic> ctx) async {
    final controller = TextEditingController();
    final change = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('What changed?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. Supplier cancelled the contract'),
          onSubmitted: (v) => Navigator.pop(dctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, controller.text),
              child: const Text('Analyze')),
        ],
      ),
    );
    if (change == null || change.trim().isEmpty || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          _AdaptResultScreen(kind: 'replan', input: change.trim(), context: ctx),
    ));
  }

  void _openScenarios(BuildContext context, Map<String, dynamic> ctx) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          _AdaptResultScreen(kind: 'scenarios', input: '', context: ctx),
    ));
  }

  Widget _objectiveCard(BuildContext context, Project p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.gps_fixed, size: 16, color: AppColors.brand),
            SizedBox(width: 6),
            Text('Objective',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.brand)),
          ]),
          const SizedBox(height: 8),
          Text(p.objective, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  Widget _stageRow(BuildContext context, Project p) {
    const stages = ['Idea', 'Planning', 'Execution', 'Review', 'Done'];
    int active;
    switch (p.status) {
      case 'Planning':
        active = 1;
        break;
      case 'On track':
      case 'At risk':
        active = 2;
        break;
      case 'Review':
        active = 3;
        break;
      case 'Done':
      case 'Completed':
        active = 4;
        break;
      default:
        active = 0;
    }
    return Row(
      children: List.generate(stages.length, (i) {
        final on = i <= active;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 2,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= active
                                  ? AppColors.brand
                                  : Theme.of(context).dividerColor))),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? AppColors.brand : Theme.of(context).cardColor,
                      border: Border.all(
                          color: on
                              ? AppColors.brand
                              : Theme.of(context).dividerColor,
                          width: 2),
                    ),
                  ),
                  Expanded(
                      child: Container(
                          height: 2,
                          color: i == stages.length - 1
                              ? Colors.transparent
                              : (i < active
                                  ? AppColors.brand
                                  : Theme.of(context).dividerColor))),
                ],
              ),
              const SizedBox(height: 4),
              Text(stages[i],
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on
                          ? AppColors.brand
                          : Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        );
      }),
    );
  }

  Widget _milestones(BuildContext context, AppState state, Project p,
      ProjectDetail? detail, List<Task> projTasks) {
    final ms = detail?.milestones ?? const <Milestone>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Milestones'),
        if (ms.isEmpty)
          Text('No milestones yet.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          ...ms.map((m) {
            final tasks =
                projTasks.where((t) => t.milestoneId == m.id).toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => state.setMilestoneStatus(
                              m, m.isDone ? 'pending' : 'done'),
                          child: Icon(
                            m.isDone
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: m.isDone
                                ? const Color(0xFF30A46C)
                                : AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(m.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: m.isDone
                                      ? TextDecoration.lineThrough
                                      : null)),
                        ),
                      ],
                    ),
                    ...tasks.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 34, top: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => state.toggleTask(t),
                                child: Icon(
                                    t.isDone
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 18,
                                    color: t.isDone
                                        ? const Color(0xFF30A46C)
                                        : t.priority.color),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(t.title,
                                    style: TextStyle(
                                        fontSize: 13,
                                        decoration: t.isDone
                                            ? TextDecoration.lineThrough
                                            : null)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _risks(BuildContext context, AppState state, Project p,
      ProjectDetail? detail) {
    final risks = (detail?.risks ?? const <ProjectRisk>[]).toList()
      ..sort((a, b) => b.severity.compareTo(a.severity));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Risks', action: 'Add', onAction: () {
          _addText(context, 'Describe the risk', (v) {
            state.addProjectRisk(
                p.id, ProjectRisk(id: state.newId('rsk'), title: v));
          });
        }),
        if (risks.isEmpty)
          Text('No risks logged.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          ...risks.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_outlined,
                      color: _riskColor(r.severity)),
                  title: Text(r.title,
                      style: TextStyle(
                          decoration: r.status == 'open'
                              ? null
                              : TextDecoration.lineThrough)),
                  subtitle: Text(
                      'P: ${r.probability} · I: ${r.impact}'
                      '${r.mitigation.isEmpty ? '' : ' · ${r.mitigation}'}'),
                  trailing: IconButton(
                    icon: Icon(r.status == 'open'
                        ? Icons.check_circle_outline
                        : Icons.undo),
                    onPressed: () => state.setRiskStatus(
                        r, r.status == 'open' ? 'mitigated' : 'open'),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _simpleListSection<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required IconData icon,
    required String Function(T) labelOf,
    required String Function(T) subOf,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, action: 'Add', onAction: onAdd),
        if (items.isEmpty)
          Text('Nothing yet.', style: Theme.of(context).textTheme.bodySmall)
        else
          ...items.map((it) {
            final sub = subOf(it);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(icon, color: AppColors.brand),
                title: Text(labelOf(it)),
                subtitle: sub.isEmpty ? null : Text(sub),
              ),
            );
          }),
      ],
    );
  }

  // ---- Financials (P4) -------------------------------------------------
  String _money(String cur, double v) =>
      '$cur${NumberFormat.decimalPattern().format(v.round())}';

  Widget _financials(BuildContext context, AppState state, Project p,
      ProjectDetail? detail) {
    final cur = state.company.currency;
    final lines = detail?.budget ?? const <BudgetLine>[];
    double sumOf(String t) =>
        lines.where((b) => b.type == t).fold(0.0, (s, b) => s + b.amount);
    final budget = p.budgetAmount ?? sumOf('budget');
    final committed = sumOf('committed');
    final spent = sumOf('expense');
    final remaining = budget - spent;
    final projected = spent + committed;
    final overrun = budget > 0 && projected > budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Financials',
            action: 'Add', onAction: () => _addBudgetLine(context, state, p.id)),
        if (budget == 0 && lines.isEmpty)
          Text('No budget tracked yet.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(children: [
                    _fin(context, 'Budget', _money(cur, budget)),
                    _fin(context, 'Spent', _money(cur, spent)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _fin(context, 'Committed', _money(cur, committed)),
                    _fin(context, 'Remaining', _money(cur, remaining),
                        color: remaining < 0 ? const Color(0xFFE5484D) : null),
                  ]),
                  const Divider(height: 24),
                  Row(children: [
                    const Text('Projected final cost',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(_money(cur, projected),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: overrun ? const Color(0xFFE5484D) : null)),
                  ]),
                  if (overrun) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.warning_amber_outlined,
                          size: 15, color: Color(0xFFE5484D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Projected to exceed budget by '
                          '${_money(cur, projected - budget)}.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFE5484D)),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ...lines.map((b) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Card(
                child: ListTile(
                  dense: true,
                  leading: Icon(
                      b.type == 'funding'
                          ? Icons.savings_outlined
                          : Icons.receipt_long_outlined,
                      color: AppColors.brand),
                  title: Text(b.label),
                  subtitle: Text(b.type),
                  trailing: Text(_money(cur, b.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            )),
      ],
    );
  }

  Widget _fin(BuildContext context, String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ---- Resources (P4) --------------------------------------------------
  Widget _resources(BuildContext context, AppState state, Project p,
      ProjectDetail? detail) {
    final res = detail?.resources ?? const <ProjectResource>[];
    const groups = {
      'person': 'People',
      'asset': 'Assets',
      'skill': 'Skills',
      'information': 'Information',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Resources',
            action: 'Add',
            onAction: () => _addResourceKind(context, state, p.id)),
        if (res.isEmpty)
          Text('No resources yet.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          ...groups.entries.expand((g) {
            final items = res.where((r) => r.kind == g.key).toList();
            if (items.isEmpty) return <Widget>[];
            return [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(g.value.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
              ),
              ...items.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: Icon(_resIcon(r.kind), color: AppColors.brand),
                      title: Text(r.name),
                      subtitle: r.detail.isEmpty ? null : Text(r.detail),
                    ),
                  )),
            ];
          }),
      ],
    );
  }

  IconData _resIcon(String kind) {
    switch (kind) {
      case 'person':
        return Icons.person_outline;
      case 'asset':
        return Icons.inventory_2_outlined;
      case 'skill':
        return Icons.psychology_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  // ---- Timeline (P4) ---------------------------------------------------
  Widget _timeline(BuildContext context, AppState state, Project p,
      ProjectDetail? detail) {
    final items = <_TLItem>[];
    items.add(_TLItem(p.startDate ?? p.deadline, 'Project started',
        Icons.flag_circle_outlined));
    for (final m in detail?.milestones ?? const <Milestone>[]) {
      if (m.dueDate != null) {
        items.add(_TLItem(m.dueDate!, 'Milestone: ${m.title}',
            Icons.flag_outlined));
      }
    }
    for (final d in detail?.decisions ?? const <ProjectDecision>[]) {
      if (d.decidedOn != null) {
        items.add(_TLItem(d.decidedOn!, 'Decision: ${d.decision}',
            Icons.gavel_outlined));
      }
    }
    for (final u in detail?.updates ?? const <ProjectUpdate>[]) {
      items.add(_TLItem(u.createdAt, u.note, Icons.history));
    }
    items.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Timeline',
            action: 'Add note',
            onAction: () => _addText(context, 'Add an update', (v) {
                  state.addProjectUpdate(
                      p.id, ProjectUpdate(id: state.newId('upd'), note: v));
                })),
        if (items.isEmpty)
          Text('Nothing on the timeline yet.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          ...items.asMap().entries.map((e) => _tlRow(
              context, e.value, e.key == items.length - 1)),
      ],
    );
  }

  Widget _tlRow(BuildContext context, _TLItem it, bool last) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(it.icon, size: 16, color: AppColors.brand),
              ),
              if (!last)
                Expanded(
                    child: Container(
                        width: 2, color: Theme.of(context).dividerColor)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM d, y').format(it.date),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand)),
                  const SizedBox(height: 2),
                  Text(it.title, style: const TextStyle(height: 1.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Add dialogs (P4) ------------------------------------------------
  Future<void> _addBudgetLine(
      BuildContext context, AppState state, String pid) async {
    final label = TextEditingController();
    final amount = TextEditingController();
    var type = 'expense';
    const types = ['budget', 'committed', 'expense', 'funding'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Add budget entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 10),
              TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: types
                    .map((t) => ChoiceChip(
                          label: Text(t),
                          selected: type == t,
                          onSelected: (_) => setD(() => type = t),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok == true && label.text.trim().isNotEmpty) {
      state.addBudgetLine(
          pid,
          BudgetLine(
            id: state.newId('bud'),
            label: label.text.trim(),
            amount: double.tryParse(amount.text.trim()) ?? 0,
            type: type,
          ));
    }
  }

  Future<void> _addResourceKind(
      BuildContext context, AppState state, String pid) async {
    final name = TextEditingController();
    final detail = TextEditingController();
    var kind = 'person';
    const kinds = {
      'person': 'Person',
      'asset': 'Asset',
      'skill': 'Skill',
      'information': 'Information',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Add resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(
                  controller: detail,
                  decoration:
                      const InputDecoration(labelText: 'Detail (optional)')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: kinds.entries
                    .map((k) => ChoiceChip(
                          label: Text(k.value),
                          selected: kind == k.key,
                          onSelected: (_) => setD(() => kind = k.key),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      state.addProjectResource(
          pid,
          ProjectResource(
            id: state.newId('res'),
            kind: kind,
            name: name.text.trim(),
            detail: detail.text.trim(),
          ));
    }
  }

  Future<void> _addText(
      BuildContext context, String title, ValueChanged<String> onSubmit) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Type here…'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) onSubmit(result.trim());
  }
}

class _TLItem {
  final DateTime date;
  final String title;
  final IconData icon;
  _TLItem(this.date, this.title, this.icon);
}

/// Shows AI dynamic-replanning or scenario-planning output for a project.
class _AdaptResultScreen extends StatefulWidget {
  final String kind; // 'replan' | 'scenarios'
  final String input;
  final Map<String, dynamic> context;
  const _AdaptResultScreen(
      {required this.kind, required this.input, required this.context});

  @override
  State<_AdaptResultScreen> createState() => _AdaptResultScreenState();
}

class _AdaptResultScreenState extends State<_AdaptResultScreen> {
  final _ai = AiService();
  String? _text;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final t = widget.kind == 'replan'
          ? await _ai.replan(change: widget.input, project: widget.context)
          : await _ai.scenarios(project: widget.context);
      if (mounted) {
        setState(() {
          _text = t;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'AI is unavailable — deploy the ai function and try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.kind == 'replan' ? 'Impact analysis' : 'Scenarios';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(height: 14),
                  Text(
                      widget.kind == 'replan'
                          ? 'Calculating the impact…'
                          : 'Comparing scenarios…',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    if (widget.kind == 'replan' && widget.input.isNotEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.change_circle_outlined,
                              color: AppColors.brand),
                          title: const Text('Change'),
                          subtitle: Text(widget.input),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(_text!, style: const TextStyle(height: 1.5)),
                  ],
                ),
    );
  }
}

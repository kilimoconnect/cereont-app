import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../models/enums.dart';
import '../../models/project_engine.dart';
import '../../models/work.dart';
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
                _healthCard(context, p, health),
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
                _simpleListSection<ProjectResource>(
                  context,
                  title: 'Resources',
                  items: detail?.resources ?? const [],
                  icon: Icons.inventory_2_outlined,
                  labelOf: (r) => r.name,
                  subOf: (r) => '${r.kind}${r.detail.isEmpty ? '' : ' · ${r.detail}'}',
                  onAdd: () => _addResource(context, state, p.id),
                ),
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
                _simpleListSection<ProjectUpdate>(
                  context,
                  title: 'Activity log',
                  items: detail?.updates ?? const [],
                  icon: Icons.history,
                  labelOf: (u) => u.note,
                  subOf: (u) => u.author,
                  onAdd: () => _addText(context, 'Add an update', (v) {
                    state.addProjectUpdate(
                        p.id, ProjectUpdate(id: state.newId('upd'), note: v));
                  }),
                ),
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

  void _addResource(BuildContext context, AppState state, String pid) {
    _addText(context, 'Add a resource', (v) {
      state.addProjectResource(
          pid, ProjectResource(id: state.newId('res'), name: v));
    });
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

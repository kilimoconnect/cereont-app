import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../projects/new_project_screen.dart';
import '../projects/project_detail_screen.dart';

enum _Filter { all, active, planning, atRisk, done, archived }
enum _Sort { attention, deadline, name, progress }

Color healthColor(int h) {
  if (h >= 85) return const Color(0xFF30A46C);
  if (h >= 70) return AppColors.brand;
  if (h >= 50) return const Color(0xFFF5A524);
  return const Color(0xFFE5484D);
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.attention;

  bool _isActive(Project p) =>
      !['Planning', 'Done', 'Completed'].contains(p.status);

  List<Project> _apply(AppState state) {
    final all = state.projects;
    Iterable<Project> list =
        _filter == _Filter.archived ? all.where((p) => p.archived) : state.liveProjects;

    switch (_filter) {
      case _Filter.active:
        list = list.where(_isActive);
        break;
      case _Filter.planning:
        list = list.where((p) => p.status == 'Planning');
        break;
      case _Filter.atRisk:
        list = list.where(
            (p) => p.status == 'At risk' || state.quickHealth(p) < 50);
        break;
      case _Filter.done:
        list = list.where((p) => ['Done', 'Completed'].contains(p.status));
        break;
      case _Filter.all:
      case _Filter.archived:
        break;
    }

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.projectType.toLowerCase().contains(q) ||
          p.objective.toLowerCase().contains(q));
    }

    final result = list.toList();
    switch (_sort) {
      case _Sort.attention:
        result.sort(
            (a, b) => state.quickHealth(a).compareTo(state.quickHealth(b)));
        break;
      case _Sort.deadline:
        result.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case _Sort.name:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _Sort.progress:
        result.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final projects = _apply(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort),
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.attention, child: Text('Sort: Needs attention')),
              PopupMenuItem(value: _Sort.deadline, child: Text('Sort: Deadline')),
              PopupMenuItem(value: _Sort.progress, child: Text('Sort: Progress')),
              PopupMenuItem(value: _Sort.name, child: Text('Sort: Name')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const NewProjectScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search projects…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', _Filter.all),
                _chip('Active', _Filter.active),
                _chip('Planning', _Filter.planning),
                _chip('At risk', _Filter.atRisk),
                _chip('Done', _Filter.done),
                _chip('Archived', _Filter.archived),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (_filter != _Filter.archived) _PortfolioSummary(state: state),
                if (_filter == _Filter.all) ...[
                  const SizedBox(height: 12),
                  _PortfolioIntelligence(state: state),
                  _BusinessMemory(state: state),
                ],
                const SizedBox(height: 8),
                if (projects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                        icon: Icons.folder_special_outlined,
                        title: 'No projects here',
                        subtitle: 'Tap New to turn an idea into a plan.'),
                  )
                else
                  ...projects.map((p) => _ProjectCard(project: p)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  final AppState state;
  const _PortfolioSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final live = state.liveProjects;
    final active = live.where((p) => !['Planning', 'Done', 'Completed'].contains(p.status)).length;
    final onTrack = live.where((p) => state.quickHealth(p) >= 70).length;
    final attention =
        live.where((p) => state.quickHealth(p) >= 50 && state.quickHealth(p) < 70).length;
    final critical = live.where((p) => state.quickHealth(p) < 50).length;

    if (live.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.brandDeep, AppColors.brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.insights, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('AI Portfolio Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('$active', 'Active', Colors.white),
              _stat('$onTrack', 'On track', const Color(0xFF7EE2B0)),
              _stat('$attention', 'Attention', const Color(0xFFFFD79A)),
              _stat('$critical', 'Critical', const Color(0xFFFFB4B4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final p = project;
    final health = state.quickHealth(p);
    final hc = healthColor(health);
    final statusLine = state.projectStatusLine(p);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: p))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hc.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$health%',
                          style: TextStyle(
                              color: hc,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                    _menu(context, state, p),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: p.progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation(hc),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    PriorityChip(p.priority, dense: true),
                    const SizedBox(width: 8),
                    Pill(p.status, color: _statusColor(p.status)),
                    const Spacer(),
                    Icon(Icons.event_outlined,
                        size: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM d').format(p.deadline),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 13, color: hc),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(statusLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, AppState state, Project p) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
      onSelected: (v) {
        if (v == 'archive') {
          state.archiveProject(p, !p.archived);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(p.archived ? 'Unarchived' : 'Archived')));
        } else if (v == 'delete') {
          _confirmDelete(context, state, p);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'archive',
            child: Text(p.archived ? 'Unarchive' : 'Archive')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Project p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
            'This permanently deletes "${p.name}" and its milestones, tasks and risks.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D)),
            onPressed: () {
              state.deleteProject(p);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'On track':
        return const Color(0xFF30A46C);
      case 'At risk':
        return const Color(0xFFE5484D);
      case 'Done':
      case 'Completed':
        return AppColors.accent;
      default:
        return const Color(0xFFF5A524);
    }
  }
}

/// Cross-project intelligence: conflicts, overloads and clustered deadlines.
class _PortfolioIntelligence extends StatelessWidget {
  final AppState state;
  const _PortfolioIntelligence({required this.state});

  @override
  Widget build(BuildContext context) {
    final live = state.liveProjects;
    if (live.isEmpty) return const SizedBox.shrink();

    bool terminal(Project p) =>
        ['Done', 'Completed', 'Cancelled', 'Failed'].contains(p.status);
    final insights = <String>[];

    final critical = live.where((p) => state.quickHealth(p) < 50).length;
    if (critical >= 2) {
      insights.add('$critical projects are critical and competing for attention.');
    }
    final counts = <String, int>{};
    for (final p in live.where((p) => !terminal(p) && p.status != 'Planning')) {
      for (final m in p.team) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    counts.forEach((name, c) {
      if (c >= 3) {
        insights.add('$name is on $c active projects — possible overload.');
      }
    });
    final soon = live
        .where((p) =>
            !terminal(p) && p.daysToDeadline >= 0 && p.daysToDeadline <= 14)
        .length;
    if (soon >= 2) insights.add('$soon projects are due within two weeks.');
    final atRisk = live.where((p) => p.status == 'At risk').length;
    if (atRisk > 0) insights.add('$atRisk project(s) flagged at risk.');
    if (insights.isEmpty) {
      insights.add('No portfolio conflicts detected — capacity looks balanced.');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
              Icon(Icons.hub_outlined, size: 16, color: AppColors.brand),
              SizedBox(width: 6),
              Text('Portfolio intelligence',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.brand)),
            ]),
            const SizedBox(height: 10),
            ...insights.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6, right: 8),
                        child: Icon(Icons.circle,
                            size: 5, color: AppColors.brand),
                      ),
                      Expanded(
                          child: Text(i,
                              style: const TextStyle(height: 1.35))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Business memory: lessons learned across past projects.
class _BusinessMemory extends StatelessWidget {
  final AppState state;
  const _BusinessMemory({required this.state});

  @override
  Widget build(BuildContext context) {
    final lessons = state.companyLessons;
    if (lessons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.school_outlined,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                const Text('Business memory · what we’ve learned',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              ...lessons.take(4).map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (l.category.isNotEmpty)
                          Text(l.category.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.brand)),
                        Text(l.lesson,
                            style: const TextStyle(height: 1.3)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

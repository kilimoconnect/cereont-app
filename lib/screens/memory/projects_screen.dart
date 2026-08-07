import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../projects/new_project_screen.dart';
import '../projects/project_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  Color _statusColor(String s) {
    switch (s) {
      case 'On track':
        return const Color(0xFF30A46C);
      case 'At risk':
        return const Color(0xFFE5484D);
      default:
        return const Color(0xFFF5A524);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<AppState>().projects;

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const NewProjectScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Project'),
      ),
      body: projects.isEmpty
          ? const EmptyState(
              icon: Icons.folder_special_outlined,
              title: 'No projects yet',
              subtitle: 'Create a project to track status and deadlines.')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: projects.length,
        itemBuilder: (_, i) {
          final p = projects[i];
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        Pill(p.status, color: _statusColor(p.status)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: p.progress,
                        minHeight: 8,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation(
                            _statusColor(p.status)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${(p.progress * 100).round()}% complete',
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Icon(Icons.event_outlined,
                            size: 13,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          p.daysToDeadline < 0
                              ? 'Past due'
                              : 'Due ${DateFormat('MMM d').format(p.deadline)} (${p.daysToDeadline}d)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.daysToDeadline <= 10
                                ? const Color(0xFFE5484D)
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                          ),
                        ),
                      ],
                    ),
                    if (p.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(p.notes,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: p.team
                          .map((m) =>
                              Pill(m, icon: Icons.person_outline))
                          .toList(),
                    ),
                  ],
                ),
              ),
              ),
            ),
          );
        },
      ),
    );
  }
}

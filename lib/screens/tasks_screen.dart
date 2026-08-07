import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/work.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'task_edit_screen.dart';

enum _Filter { all, today, overdue, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _Filter _filter = _Filter.all;

  List<Task> _apply(AppState s) {
    switch (_filter) {
      case _Filter.all:
        return s.todaysPriorities;
      case _Filter.today:
        final now = DateTime.now();
        return s.todaysPriorities
            .where((t) =>
                t.due != null &&
                t.due!.year == now.year &&
                t.due!.month == now.month &&
                t.due!.day == now.day)
            .toList();
      case _Filter.overdue:
        return s.overdueTasks;
      case _Filter.done:
        return s.tasks.where((t) => t.isDone).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tasks = _apply(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', _Filter.all),
                _chip('Today', _Filter.today),
                _chip('Overdue', _Filter.overdue, count: state.overdueTasks.length),
                _chip('Done', _Filter.done),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const EmptyState(
                    icon: Icons.task_alt,
                    title: 'Nothing here',
                    subtitle: 'You are all caught up on this view.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) =>
                        _TaskTile(task: tasks[i], onEdit: () => _edit(context, tasks[i])),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f, {int count = 0}) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(count > 0 ? '$label ($count)' : label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Task? task) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TaskEditScreen(task: task)));
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  const _TaskTile({required this.task, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final customer = state.customerById(task.relatedCustomerId);
    final supplier = state.supplierById(task.relatedSupplierId);
    final project = state.projectById(task.relatedProjectId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE5484D).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline, color: Color(0xFFE5484D)),
        ),
        onDismissed: (_) => state.deleteTask(task),
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => state.toggleTask(task),
                    child: Icon(
                      task.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.isDone
                          ? AppColors.brand
                          : task.priority.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isDone
                                ? Theme.of(context).textTheme.bodySmall?.color
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PriorityChip(task.priority, dense: true),
                            if (task.due != null)
                              Pill(
                                task.isOverdue
                                    ? 'Overdue'
                                    : DateFormat('MMM d').format(task.due!),
                                color: task.isOverdue
                                    ? const Color(0xFFE5484D)
                                    : null,
                                icon: Icons.schedule,
                              ),
                            Pill(task.source, icon: Icons.bolt_outlined),
                            if (customer != null)
                              Pill(customer.name,
                                  icon: Icons.person_outline),
                            if (supplier != null)
                              Pill(supplier.name,
                                  icon: Icons.local_shipping_outlined),
                            if (project != null)
                              Pill(project.name,
                                  icon: Icons.folder_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/work.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class TaskEditScreen extends StatefulWidget {
  final Task? task;
  const TaskEditScreen({super.key, this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late TextEditingController _title;
  late TextEditingController _notes;
  late Priority _priority;
  late TaskStatus _status;
  DateTime? _due;
  String? _customerId;
  String? _supplierId;
  String? _projectId;

  bool get _isNew => widget.task == null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _priority = t?.priority ?? Priority.medium;
    _status = t?.status ?? TaskStatus.open;
    _due = t?.due;
    _customerId = t?.relatedCustomerId;
    _supplierId = t?.relatedSupplierId;
    _projectId = t?.relatedProjectId;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Give the task a title first.')));
      return;
    }
    final state = context.read<AppState>();
    final edited = Task(
      id: widget.task?.id ?? state.newId('t'),
      title: _title.text.trim(),
      priority: _priority,
      status: _status,
      due: _due,
      owner: widget.task?.owner ?? 'You',
      relatedCustomerId: _customerId,
      relatedSupplierId: _supplierId,
      relatedProjectId: _projectId,
      source: widget.task?.source ?? 'Manual',
      notes: _notes.text.trim(),
    );
    if (_isNew) {
      state.addTask(edited);
    } else {
      state.updateTask(widget.task!, edited);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New task' : 'Edit task'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                state.deleteTask(widget.task!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Task title'),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Priority'),
          Wrap(
            spacing: 8,
            children: Priority.values.map((p) {
              return ChoiceChip(
                label: Text(p.label),
                selected: _priority == p,
                onSelected: (_) => setState(() => _priority = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Status'),
          Wrap(
            spacing: 8,
            children: TaskStatus.values.map((s) {
              return ChoiceChip(
                label: Text(s.label),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Due date'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(_due == null
                  ? 'No due date'
                  : DateFormat('EEEE, MMM d, y').format(_due!)),
              trailing: _due == null
                  ? const Icon(Icons.add)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _due = null),
                    ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _due ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) setState(() => _due = picked);
              },
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Related to'),
          _dropdown<String?>(
            label: 'Customer',
            value: _customerId,
            items: {
              null: 'None',
              for (final c in state.customers) c.id: c.name,
            },
            onChanged: (v) => setState(() => _customerId = v),
          ),
          const SizedBox(height: 12),
          _dropdown<String?>(
            label: 'Supplier',
            value: _supplierId,
            items: {
              null: 'None',
              for (final s in state.suppliers) s.id: s.name,
            },
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 12),
          _dropdown<String?>(
            label: 'Project',
            value: _projectId,
            items: {
              null: 'None',
              for (final p in state.projects) p.id: p.name,
            },
            onChanged: (v) => setState(() => _projectId = v),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notes,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(_isNew ? 'Create task' : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.entries
              .map((e) =>
                  DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => onChanged(v as T),
        ),
      ),
    );
  }
}

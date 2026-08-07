import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/project_templates.dart';
import '../../models/business.dart';
import '../../models/enums.dart';
import '../../services/ai_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'project_detail_screen.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _ai = AiService();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  Priority _priority = Priority.high;
  DateTime? _target;

  ProjectPlan? _plan;
  bool _generating = false;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Name your project first.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      _plan = await _ai.planProject(
          name: _name.text.trim(), description: _desc.text.trim());
    } catch (_) {
      setState(() => _error =
          'AI planning is unavailable — pick a template or deploy the ai function.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _useTemplate(ProjectTemplateDef t) {
    setState(() {
      _plan = t.toPlan(objective: _desc.text.trim());
      _error = null;
      if (_name.text.trim().isEmpty) _name.text = t.name;
    });
  }

  Future<void> _create() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _creating = true);
    final state = context.read<AppState>();
    final base = Project(
      id: state.newId('pr'),
      name: _name.text.trim(),
      status: 'Planning',
      deadline: _target ?? DateTime.now().add(const Duration(days: 90)),
      progress: 0,
      team: const [],
      description: _desc.text.trim(),
      category: plan.projectType,
      priority: _priority,
      startDate: DateTime.now(),
      projectType: plan.projectType,
      complexity: plan.complexity,
      objective: plan.objective,
    );
    try {
      final saved = await state.createPlannedProject(base, plan);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: saved)));
    } catch (_) {
      setState(() {
        _creating = false;
        _error = 'Could not create the project. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New project')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: const TextStyle(color: Color(0xFFE5484D))),
            ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Project name',
              hintText: 'e.g. Start a fertilizer distribution company',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _desc,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Describe the idea (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader('Priority'),
          Wrap(
            spacing: 8,
            children: Priority.values
                .map((p) => ChoiceChip(
                      label: Text(p.label),
                      selected: _priority == p,
                      onSelected: (_) => setState(() => _priority = p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(_target == null
                  ? 'Target completion date'
                  : 'Target: ${_target.toString().split(' ').first}'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _target ?? DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 1460)),
                );
                if (picked != null) setState(() => _target = picked);
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label:
                  Text(_generating ? 'Planning…' : 'Generate plan with AI'),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Or start from a template'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kProjectTemplates
                .map((t) => ActionChip(
                      avatar: Icon(t.icon, size: 16),
                      label: Text(t.name),
                      onPressed: () => _useTemplate(t),
                    ))
                .toList(),
          ),
          if (_plan != null) ...[
            const SizedBox(height: 24),
            _planPreview(context, _plan!),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _creating ? null : _create,
                child: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Create project · ${_plan!.milestones.length} milestones'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planPreview(BuildContext context, ProjectPlan plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.brand),
              SizedBox(width: 6),
              Text('AI plan',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 10),
          if (plan.objective.isNotEmpty) ...[
            const Text('Objective',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text(plan.objective, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (plan.projectType.isNotEmpty) Pill(plan.projectType),
              if (plan.complexity.isNotEmpty)
                Pill('${plan.complexity} complexity'),
              if (plan.duration.isNotEmpty) Pill(plan.duration),
            ],
          ),
          const SizedBox(height: 14),
          ...plan.milestones.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 15, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${m.title}  ·  ${m.tasks.length} task(s)',
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              )),
          if (plan.risks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${plan.risks.length} risk(s) identified',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

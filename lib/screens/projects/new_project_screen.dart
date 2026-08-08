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
  final _idea = TextEditingController();
  final _answer = TextEditingController();

  int _step = 0; // 0 idea · 1 discovery · 2 blueprint
  String? _error;

  // discovery
  final List<Map<String, String>> _history = [];
  String? _question;
  bool _busy = false; // discover/blueprint/create in flight

  // blueprint
  ProjectBlueprint? _bp;
  Priority _priority = Priority.high;
  DateTime? _target;

  @override
  void dispose() {
    _idea.dispose();
    _answer.dispose();
    super.dispose();
  }

  // ---- flow ------------------------------------------------------------
  Future<void> _startDiscovery() async {
    if (_idea.text.trim().isEmpty) {
      setState(() => _error = 'Describe your idea first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _ai.discover(idea: _idea.text.trim(), history: _history);
      if (r.done) {
        await _buildBlueprint();
      } else {
        setState(() {
          _question = r.question;
          _step = 1;
        });
      }
    } catch (_) {
      // AI unavailable — skip straight to a template-free manual plan is hard,
      // so surface an error and let them use a template instead.
      setState(() =>
          _error = 'AI is unavailable. Deploy the ai function or use a template.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitAnswer() async {
    final a = _answer.text.trim();
    if (a.isEmpty || _question == null) return;
    _history.add({'q': _question!, 'a': a});
    _answer.clear();
    setState(() => _busy = true);
    try {
      final r = await _ai.discover(idea: _idea.text.trim(), history: _history);
      if (r.done || _history.length >= 6) {
        await _buildBlueprint();
      } else {
        setState(() => _question = r.question);
      }
    } catch (_) {
      await _buildBlueprint(); // best effort with what we have
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buildBlueprint() async {
    setState(() => _busy = true);
    try {
      _bp = await _ai.blueprint(idea: _idea.text.trim(), history: _history);
      setState(() => _step = 2);
    } catch (_) {
      setState(() => _error = 'Could not build the plan. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activate() async {
    final bp = _bp;
    if (bp == null) return;
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final u = bp.understanding;
    final base = Project(
      id: state.newId('pr'),
      name: u.name.isNotEmpty ? u.name : _idea.text.trim(),
      status: 'On track',
      deadline: _target ?? _deadlineFromTimeline(u.timeline),
      progress: 0,
      team: const [],
      description: _idea.text.trim(),
      category: u.category,
      priority: _priority,
      startDate: DateTime.now(),
      projectType: u.projectType,
      complexity: u.complexity,
      objective: u.objective,
      successMetrics: u.successMetrics,
      scopeIncluded: u.scopeIncluded,
      scopeExcluded: u.scopeExcluded,
    );
    try {
      final saved = await state.createBlueprintProject(base, bp);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: saved)));
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Could not activate the project. Try again.';
      });
    }
  }

  Future<void> _useTemplate(ProjectTemplateDef t) async {
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final base = Project(
      id: state.newId('pr'),
      name: _idea.text.trim().isEmpty ? t.name : _idea.text.trim(),
      status: 'On track',
      deadline: _deadlineFromTimeline(t.duration),
      progress: 0,
      team: const [],
      description: _idea.text.trim(),
      category: t.category,
      priority: _priority,
      startDate: DateTime.now(),
      projectType: t.projectType,
      complexity: t.complexity,
    );
    try {
      final saved = await state.createPlannedProject(base, t.toPlan());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: saved)));
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Could not create from template.';
      });
    }
  }

  DateTime _deadlineFromTimeline(String t) {
    final now = DateTime.now();
    final m = RegExp(r'(\d+)\s*(day|week|month|year)', caseSensitive: false)
        .firstMatch(t.toLowerCase());
    if (m == null) return now.add(const Duration(days: 90));
    final n = int.parse(m.group(1)!);
    switch (m.group(2)) {
      case 'day':
        return now.add(Duration(days: n));
      case 'week':
        return now.add(Duration(days: n * 7));
      case 'month':
        return DateTime(now.year, now.month + n, now.day);
      case 'year':
        return DateTime(now.year + n, now.month, now.day);
      default:
        return now.add(const Duration(days: 90));
    }
  }

  // ---- UI --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_step) {
          1 => 'A few questions',
          2 => 'Project blueprint',
          _ => 'New project',
        }),
      ),
      body: SafeArea(
        child: switch (_step) {
          1 => _discoveryView(),
          2 => _blueprintView(),
          _ => _ideaView(),
        },
      ),
    );
  }

  Widget _errorBanner() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!,
              style: const TextStyle(color: Color(0xFFE5484D))),
        );

  Widget _ideaView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const _StepDots(step: 0),
        const SizedBox(height: 20),
        Text('What are you trying to accomplish?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Describe it in your own words. Cereont will ask a few questions, '
          'then build a structured project.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _errorBanner(),
        TextField(
          controller: _idea,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText:
                'e.g. Start a fertilizer distribution business in Tanzania…',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _busy ? null : _startDiscovery,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(_busy ? 'Thinking…' : 'Continue'),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader('Or start from a template'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kProjectTemplates
              .map((t) => ActionChip(
                    avatar: Icon(t.icon, size: 16),
                    label: Text(t.name),
                    onPressed: _busy ? null : () => _useTemplate(t),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _discoveryView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _StepDots(step: 1),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              for (final qa in _history) ...[
                _bubble(qa['q'] ?? '', ai: true),
                _bubble(qa['a'] ?? '', ai: false),
              ],
              if (_question != null) _bubble(_question!, ai: true),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Cereont is thinking…'),
                  ]),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _answer,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitAnswer(),
                        decoration:
                            const InputDecoration(hintText: 'Your answer…'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton.small(
                      elevation: 0,
                      onPressed: _busy ? null : _submitAnswer,
                      child: const Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _buildBlueprint,
                    child: const Text('Skip — build my plan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(String text, {required bool ai}) {
    return Align(
      alignment: ai ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: ai ? Theme.of(context).cardColor : AppColors.brand,
          borderRadius: BorderRadius.circular(16),
          border:
              ai ? Border.all(color: Theme.of(context).dividerColor) : null,
        ),
        child: Text(text,
            style: TextStyle(height: 1.4, color: ai ? null : Colors.white)),
      ),
    );
  }

  Widget _blueprintView() {
    final bp = _bp!;
    final u = bp.understanding;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const _StepDots(step: 2),
        const SizedBox(height: 16),
        _errorBanner(),
        // Understanding
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.name.isEmpty ? 'Your project' : u.name,
                  style: Theme.of(context).textTheme.titleMedium),
              if (u.objective.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(u.objective, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (u.projectType.isNotEmpty) Pill(u.projectType),
                  if (u.complexity.isNotEmpty) Pill('${u.complexity} complexity'),
                  if (u.timeline.isNotEmpty) Pill(u.timeline),
                  if (u.budget.isNotEmpty) Pill(u.budget),
                  if (u.target.isNotEmpty) Pill(u.target),
                ],
              ),
            ],
          ),
        ),
        if (u.successMetrics.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader('Success metrics'),
          ...u.successMetrics.map((m) => _bullet(m, Icons.check_circle_outline)),
        ],
        if (u.scopeIncluded.isNotEmpty || u.scopeExcluded.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader('Scope'),
          ...u.scopeIncluded.map((s) => _bullet(s, Icons.add, green: true)),
          ...u.scopeExcluded.map((s) => _bullet(s, Icons.remove, muted: true)),
        ],
        const SizedBox(height: 20),
        SectionHeader('Plan · ${bp.milestones.length} milestones'),
        ...bp.milestones.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.brand),
                title: Text(m.title),
                subtitle: Text('${m.tasks.length} task(s)'),
              ),
            )),
        if (bp.risks.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionHeader('Risks · ${bp.risks.length}'),
          ...bp.risks.map((r) => _bullet(
              '${r.title}  (P:${r.probability}/I:${r.impact})',
              Icons.warning_amber_outlined)),
        ],
        if (bp.assumptions.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionHeader('Assumptions · ${bp.assumptions.length}'),
          ...bp.assumptions.map((a) =>
              _bullet('${a.statement}  (${a.confidence}%)', Icons.help_outline)),
        ],
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _busy ? null : _activate,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rocket_launch_outlined),
            label: Text(_busy ? 'Activating…' : 'Activate project'),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text, IconData icon,
      {bool green = false, bool muted = false}) {
    final color = green
        ? const Color(0xFF30A46C)
        : muted
            ? Theme.of(context).textTheme.bodySmall?.color
            : AppColors.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(icon, size: 15, color: color),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;
  const _StepDots({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Idea', 'Discovery', 'Blueprint'];
    return Row(
      children: List.generate(labels.length, (i) {
        final on = i <= step;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? AppColors.brand : Theme.of(context).cardColor,
                  border: Border.all(
                      color: on
                          ? AppColors.brand
                          : Theme.of(context).dividerColor),
                ),
                child: Text('${i + 1}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : null)),
              ),
              const SizedBox(width: 6),
              Text(labels[i],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on
                          ? AppColors.brand
                          : Theme.of(context).textTheme.bodySmall?.color)),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: Theme.of(context).dividerColor,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

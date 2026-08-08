import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/executive_brief.dart';
import '../models/work.dart';

class AiReply {
  final String text;
  final String provider; // 'openai' | 'gemini'
  const AiReply(this.text, this.provider);
}

/// Calls the `ai` Supabase Edge Function (OpenAI primary, Gemini fallback).
/// The user's JWT is attached automatically, so the function reads their
/// business data under RLS. Throws on any failure so callers can fall back
/// to the offline engine.
class AiService {
  Future<AiReply> chat({
    required String message,
    required List<ChatMessage> history,
    Map<String, dynamic>? project,
  }) async {
    final res = await Supabase.instance.client.functions.invoke(
      'ai',
      body: {
        'action': 'chat',
        'message': message,
        'history': history
            .map((m) => {'fromUser': m.fromUser, 'text': m.text})
            .toList(),
        if (project != null) 'project': project,
      },
    );

    final data = res.data;
    if (data is Map && data['reply'] is String) {
      final reply = (data['reply'] as String).trim();
      if (reply.isNotEmpty) {
        return AiReply(reply, (data['provider'] as String?) ?? 'ai');
      }
    }
    throw Exception('AI function returned no reply');
  }

  /// Requests a structured executive brief from the edge function.
  Future<ExecutiveBrief> brief() async {
    final res = await Supabase.instance.client.functions.invoke(
      'ai',
      body: {'action': 'brief'},
    );
    final data = res.data;
    if (data is Map && data['brief'] is Map) {
      return ExecutiveBrief.fromJson(
        Map<String, dynamic>.from(data['brief'] as Map),
        (data['provider'] as String?) ?? 'ai',
      );
    }
    throw Exception('AI function returned no brief');
  }

  /// Turns a raw meeting transcript/notes into a structured result.
  Future<ParsedMeeting> meeting(String transcript) async {
    final res = await Supabase.instance.client.functions.invoke(
      'ai',
      body: {'action': 'meeting', 'transcript': transcript},
    );
    final data = res.data;
    if (data is Map && data['meeting'] is Map) {
      final m = Map<String, dynamic>.from(data['meeting'] as Map);
      return ParsedMeeting(
        title: (m['title'] ?? 'Captured meeting').toString(),
        summary: (m['summary'] ?? '').toString(),
        decisions: (m['decisions'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
        actions: (m['action_items'] as List?)
                ?.map((e) => e is Map
                    ? (e['text'] ?? '').toString()
                    : e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
      );
    }
    throw Exception('AI function returned no meeting');
  }

  /// Asks the AI to classify and plan a project from an idea.
  Future<ProjectPlan> planProject({
    required String name,
    required String description,
  }) async {
    final res = await Supabase.instance.client.functions.invoke(
      'ai',
      body: {
        'action': 'plan_project',
        'name': name,
        'description': description,
      },
    );
    final data = res.data;
    if (data is Map && data['plan'] is Map) {
      return ProjectPlan.fromJson(
        Map<String, dynamic>.from(data['plan'] as Map),
        (data['provider'] as String?) ?? 'ai',
      );
    }
    throw Exception('AI function returned no plan');
  }

  /// Discovery interview: returns the next question, or done.
  Future<DiscoverResult> discover({
    required String idea,
    required List<Map<String, String>> history,
  }) async {
    final res = await Supabase.instance.client.functions.invoke('ai', body: {
      'action': 'discover',
      'idea': idea,
      'history': history,
    });
    final d = res.data;
    if (d is Map) {
      return DiscoverResult(
        done: d['done'] == true,
        question: (d['question'] ?? '').toString(),
      );
    }
    throw Exception('No discovery response');
  }

  /// Full blueprint (understanding + milestones + tasks + risks + assumptions).
  Future<ProjectBlueprint> blueprint({
    required String idea,
    required List<Map<String, String>> history,
  }) async {
    final res = await Supabase.instance.client.functions.invoke('ai', body: {
      'action': 'blueprint',
      'idea': idea,
      'history': history,
    });
    final d = res.data;
    if (d is Map && d['blueprint'] is Map) {
      return ProjectBlueprint.fromJson(
        Map<String, dynamic>.from(d['blueprint'] as Map),
        (d['provider'] as String?) ?? 'ai',
      );
    }
    throw Exception('No blueprint response');
  }

  /// Turns natural-language text into a structured task (title/due/priority).
  Future<ParsedTask> parseTask(String text) async {
    final res = await Supabase.instance.client.functions.invoke('ai', body: {
      'action': 'parse_task',
      'text': text,
    });
    final d = res.data;
    if (d is Map && d['task'] is Map) {
      final t = Map<String, dynamic>.from(d['task'] as Map);
      final dueStr = (t['due'] ?? '').toString();
      return ParsedTask(
        title: (t['title'] ?? text).toString(),
        due: dueStr.isEmpty ? null : DateTime.tryParse(dueStr),
        priority: (t['priority'] ?? 'medium').toString(),
      );
    }
    throw Exception('No task response');
  }

  /// Dynamic replanning: impact analysis for a reported change (markdown text).
  Future<String> replan({
    required String change,
    required Map<String, dynamic> project,
  }) async {
    final res = await Supabase.instance.client.functions.invoke('ai', body: {
      'action': 'replan',
      'change': change,
      'project': project,
    });
    final d = res.data;
    final a = (d is Map ? d['analysis'] : null)?.toString();
    if (a != null && a.trim().isNotEmpty) return a;
    throw Exception('No analysis');
  }

  /// Extracts summary + actionable tasks + risks from document text.
  Future<DocExtract> extractDocument(String text) async {
    final res = await Supabase.instance.client.functions.invoke('ai', body: {
      'action': 'extract_document',
      'text': text,
    });
    final d = res.data;
    if (d is Map && d['doc'] is Map) {
      final m = Map<String, dynamic>.from(d['doc'] as Map);
      List<String> l(dynamic v) =>
          v is List ? v.map((e) => e.toString()).toList() : const <String>[];
      return DocExtract(
        summary: (m['summary'] ?? '').toString(),
        tasks: l(m['tasks']),
        risks: l(m['risks']),
      );
    }
    throw Exception('No document extraction');
  }

  /// Scenario planning: 3 what-if comparisons (markdown text).
  Future<String> scenarios({required Map<String, dynamic> project}) async {
    final res = await Supabase.instance.client.functions.invoke('ai', body: {
      'action': 'scenarios',
      'project': project,
    });
    final d = res.data;
    final a = (d is Map ? d['analysis'] : null)?.toString();
    if (a != null && a.trim().isNotEmpty) return a;
    throw Exception('No analysis');
  }
}

class ParsedTask {
  final String title;
  final DateTime? due;
  final String priority;
  const ParsedTask({required this.title, this.due, required this.priority});
}

class DocExtract {
  final String summary;
  final List<String> tasks;
  final List<String> risks;
  const DocExtract(
      {required this.summary, required this.tasks, required this.risks});
}

class DiscoverResult {
  final bool done;
  final String question;
  const DiscoverResult({required this.done, required this.question});
}

class BlueprintUnderstanding {
  final String name;
  final String objective;
  final String projectType;
  final String complexity;
  final String category;
  final String target;
  final String budget;
  final String timeline;
  final List<String> successMetrics;
  final List<String> scopeIncluded;
  final List<String> scopeExcluded;

  const BlueprintUnderstanding({
    required this.name,
    required this.objective,
    required this.projectType,
    required this.complexity,
    required this.category,
    required this.target,
    required this.budget,
    required this.timeline,
    required this.successMetrics,
    required this.scopeIncluded,
    required this.scopeExcluded,
  });

  static String _s(dynamic v) => (v ?? '').toString();
  static List<String> _l(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];

  factory BlueprintUnderstanding.fromJson(Map<String, dynamic> m) =>
      BlueprintUnderstanding(
        name: _s(m['name']),
        objective: _s(m['objective']),
        projectType: _s(m['project_type']),
        complexity: _s(m['complexity']),
        category: _s(m['category']),
        target: _s(m['target']),
        budget: _s(m['budget']),
        timeline: _s(m['timeline']),
        successMetrics: _l(m['success_metrics']),
        scopeIncluded: _l(m['scope_included']),
        scopeExcluded: _l(m['scope_excluded']),
      );
}

class BlueprintAssumption {
  final String statement;
  final int confidence;
  const BlueprintAssumption(this.statement, this.confidence);
}

class ProjectBlueprint {
  final BlueprintUnderstanding understanding;
  final List<PlanMilestone> milestones;
  final List<PlanRisk> risks;
  final List<BlueprintAssumption> assumptions;
  final String provider;

  const ProjectBlueprint({
    required this.understanding,
    required this.milestones,
    required this.risks,
    required this.assumptions,
    required this.provider,
  });

  static String _s(dynamic v) => (v ?? '').toString();

  factory ProjectBlueprint.fromJson(Map<String, dynamic> m, String provider) {
    final milestones = <PlanMilestone>[];
    if (m['milestones'] is List) {
      for (final ms in (m['milestones'] as List).whereType<Map>()) {
        final tasks = <PlanTask>[];
        if (ms['tasks'] is List) {
          for (final t in (ms['tasks'] as List).whereType<Map>()) {
            tasks.add(PlanTask(_s(t['title']),
                _s(t['priority']).isEmpty ? 'medium' : _s(t['priority'])));
          }
        }
        milestones.add(PlanMilestone(_s(ms['title']), tasks));
      }
    }
    final risks = <PlanRisk>[];
    if (m['risks'] is List) {
      for (final r in (m['risks'] as List).whereType<Map>()) {
        risks.add(PlanRisk(_s(r['title']), _s(r['probability']),
            _s(r['impact']), _s(r['mitigation'])));
      }
    }
    final assumptions = <BlueprintAssumption>[];
    if (m['assumptions'] is List) {
      for (final a in (m['assumptions'] as List).whereType<Map>()) {
        final c = a['confidence'];
        final conf = c is num ? c.round() : int.tryParse('$c') ?? 70;
        assumptions.add(BlueprintAssumption(_s(a['statement']), conf));
      }
    }
    return ProjectBlueprint(
      understanding: BlueprintUnderstanding.fromJson(
          m['understanding'] is Map
              ? Map<String, dynamic>.from(m['understanding'] as Map)
              : <String, dynamic>{}),
      milestones: milestones,
      risks: risks,
      assumptions: assumptions,
      provider: provider,
    );
  }
}

class ParsedMeeting {
  final String title;
  final String summary;
  final List<String> decisions;
  final List<String> actions;
  const ParsedMeeting({
    required this.title,
    required this.summary,
    required this.decisions,
    required this.actions,
  });
}

// ---- Project planning result ---------------------------------------------
class PlanTask {
  final String title;
  final String priority;
  const PlanTask(this.title, this.priority);
}

class PlanMilestone {
  final String title;
  final List<PlanTask> tasks;
  const PlanMilestone(this.title, this.tasks);
}

class PlanRisk {
  final String title;
  final String probability;
  final String impact;
  final String mitigation;
  const PlanRisk(this.title, this.probability, this.impact, this.mitigation);
}

class ProjectPlan {
  final String projectType;
  final String complexity;
  final String duration;
  final String objective;
  final List<String> requiredAreas;
  final List<PlanMilestone> milestones;
  final List<PlanRisk> risks;
  final String provider;

  const ProjectPlan({
    required this.projectType,
    required this.complexity,
    required this.duration,
    required this.objective,
    required this.requiredAreas,
    required this.milestones,
    required this.risks,
    required this.provider,
  });

  static String _s(dynamic v) => (v ?? '').toString();

  factory ProjectPlan.fromJson(Map<String, dynamic> m, String provider) {
    final milestones = <PlanMilestone>[];
    if (m['milestones'] is List) {
      for (final ms in (m['milestones'] as List).whereType<Map>()) {
        final tasks = <PlanTask>[];
        if (ms['tasks'] is List) {
          for (final t in (ms['tasks'] as List).whereType<Map>()) {
            tasks.add(PlanTask(_s(t['title']),
                _s(t['priority']).isEmpty ? 'medium' : _s(t['priority'])));
          }
        }
        milestones.add(PlanMilestone(_s(ms['title']), tasks));
      }
    }
    final risks = <PlanRisk>[];
    if (m['risks'] is List) {
      for (final r in (m['risks'] as List).whereType<Map>()) {
        risks.add(PlanRisk(_s(r['title']), _s(r['probability']),
            _s(r['impact']), _s(r['mitigation'])));
      }
    }
    return ProjectPlan(
      projectType: _s(m['project_type']),
      complexity: _s(m['complexity']),
      duration: _s(m['estimated_duration']),
      objective: _s(m['objective']),
      requiredAreas: (m['required_areas'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      milestones: milestones,
      risks: risks,
      provider: provider,
    );
  }
}

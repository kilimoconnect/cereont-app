import 'serial.dart';

class Milestone {
  final String id;
  String title;
  String status; // pending / in_progress / done
  DateTime? dueDate;
  int orderIndex;

  Milestone({
    required this.id,
    required this.title,
    this.status = 'pending',
    this.dueDate,
    this.orderIndex = 0,
  });

  bool get isDone => status == 'done';

  factory Milestone.fromMap(Map<String, dynamic> m) => Milestone(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        status: m['status'] as String? ?? 'pending',
        dueDate: parseDate(m['due_date']),
        orderIndex: toInt(m['order_index']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'status': status,
        'due_date': dateStr(dueDate),
        'order_index': orderIndex,
      };
}

class ProjectRisk {
  final String id;
  String title;
  String probability; // low/medium/high
  String impact; // low/medium/high
  String mitigation;
  String status; // open/mitigated/closed

  ProjectRisk({
    required this.id,
    required this.title,
    this.probability = 'medium',
    this.impact = 'medium',
    this.mitigation = '',
    this.status = 'open',
  });

  /// 0..4 severity for sorting/colour.
  int get severity {
    int v(String s) => s == 'high' ? 2 : (s == 'medium' ? 1 : 0);
    return v(probability) + v(impact);
  }

  factory ProjectRisk.fromMap(Map<String, dynamic> m) => ProjectRisk(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        probability: m['probability'] as String? ?? 'medium',
        impact: m['impact'] as String? ?? 'medium',
        mitigation: m['mitigation'] as String? ?? '',
        status: m['status'] as String? ?? 'open',
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'probability': probability,
        'impact': impact,
        'mitigation': mitigation,
        'status': status,
      };
}

class ProjectResource {
  final String id;
  String kind; // person/money/asset/information
  String name;
  String detail;

  ProjectResource({
    required this.id,
    this.kind = 'person',
    required this.name,
    this.detail = '',
  });

  factory ProjectResource.fromMap(Map<String, dynamic> m) => ProjectResource(
        id: m['id'] as String,
        kind: m['kind'] as String? ?? 'person',
        name: m['name'] as String? ?? '',
        detail: m['detail'] as String? ?? '',
      );

  Map<String, dynamic> toMap() =>
      {'kind': kind, 'name': name, 'detail': detail};
}

class BudgetLine {
  final String id;
  String label;
  double amount;
  String type; // budget/expense/funding

  BudgetLine({
    required this.id,
    required this.label,
    this.amount = 0,
    this.type = 'expense',
  });

  factory BudgetLine.fromMap(Map<String, dynamic> m) => BudgetLine(
        id: m['id'] as String,
        label: m['label'] as String? ?? '',
        amount: toDouble(m['amount']),
        type: m['type'] as String? ?? 'expense',
      );

  Map<String, dynamic> toMap() =>
      {'label': label, 'amount': amount, 'type': type};
}

class ProjectDecision {
  final String id;
  String decision;
  String rationale;
  DateTime? decidedOn;

  ProjectDecision({
    required this.id,
    required this.decision,
    this.rationale = '',
    this.decidedOn,
  });

  factory ProjectDecision.fromMap(Map<String, dynamic> m) => ProjectDecision(
        id: m['id'] as String,
        decision: m['decision'] as String? ?? '',
        rationale: m['rationale'] as String? ?? '',
        decidedOn: parseDate(m['decided_on']),
      );

  Map<String, dynamic> toMap() => {
        'decision': decision,
        'rationale': rationale,
        'decided_on': dateStr(decidedOn),
      };
}

class ProjectLesson {
  final String id;
  String lesson;
  String category;

  ProjectLesson({required this.id, required this.lesson, this.category = ''});

  factory ProjectLesson.fromMap(Map<String, dynamic> m) => ProjectLesson(
        id: m['id'] as String,
        lesson: m['lesson'] as String? ?? '',
        category: m['category'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'lesson': lesson, 'category': category};
}

class ProjectUpdate {
  final String id;
  String note;
  String author;
  DateTime createdAt;

  ProjectUpdate({
    required this.id,
    required this.note,
    this.author = 'You',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProjectUpdate.fromMap(Map<String, dynamic> m) => ProjectUpdate(
        id: m['id'] as String,
        note: m['note'] as String? ?? '',
        author: m['author'] as String? ?? '',
        createdAt: parseTs(m['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {'note': note, 'author': author};
}

/// A whole project loaded with its children — used by the detail screen.
class ProjectDetail {
  final List<Milestone> milestones;
  final List<ProjectRisk> risks;
  final List<ProjectResource> resources;
  final List<BudgetLine> budget;
  final List<ProjectDecision> decisions;
  final List<ProjectLesson> lessons;
  final List<ProjectUpdate> updates;

  const ProjectDetail({
    this.milestones = const [],
    this.risks = const [],
    this.resources = const [],
    this.budget = const [],
    this.decisions = const [],
    this.lessons = const [],
    this.updates = const [],
  });
}

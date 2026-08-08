import 'enums.dart';
import 'serial.dart';

class Task {
  final String id;
  String title;
  Priority priority;
  TaskStatus status;
  DateTime? due;
  String owner;
  String? relatedCustomerId;
  String? relatedSupplierId;
  String? relatedProjectId;
  String? milestoneId;
  String? parentTaskId;
  String? dependsOn;
  String source; // Email, Meeting, AI, Manual
  String notes;

  Task({
    required this.id,
    required this.title,
    this.priority = Priority.medium,
    this.status = TaskStatus.open,
    this.due,
    this.owner = 'You',
    this.relatedCustomerId,
    this.relatedSupplierId,
    this.relatedProjectId,
    this.milestoneId,
    this.parentTaskId,
    this.dependsOn,
    this.source = 'Manual',
    this.notes = '',
  });

  bool get isDone => status == TaskStatus.done;
  bool get isClosed =>
      status == TaskStatus.done || status == TaskStatus.cancelled;
  bool get isSubtask => parentTaskId != null;

  bool get isOverdue =>
      !isClosed && due != null && due!.isBefore(DateTime.now());

  int? get daysToDue => due?.difference(DateTime.now()).inDays;

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        priority: PriorityWire.fromWire(m['priority'] as String?),
        status: TaskStatusWire.fromWire(m['status'] as String?),
        due: parseTs(m['due']),
        owner: m['owner'] as String? ?? 'You',
        relatedCustomerId: m['related_customer_id'] as String?,
        relatedSupplierId: m['related_supplier_id'] as String?,
        relatedProjectId: m['related_project_id'] as String?,
        milestoneId: m['milestone_id'] as String?,
        parentTaskId: m['parent_task_id'] as String?,
        dependsOn: m['depends_on'] as String?,
        source: m['source'] as String? ?? 'Manual',
        notes: m['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'priority': priority.wire,
        'status': status.wire,
        'due': tsStr(due),
        'owner': owner,
        'related_customer_id': relatedCustomerId,
        'related_supplier_id': relatedSupplierId,
        'related_project_id': relatedProjectId,
        'milestone_id': milestoneId,
        'parent_task_id': parentTaskId,
        'depends_on': dependsOn,
        'source': source,
        'notes': notes,
      };
}

class CalendarEvent {
  final String id;
  String title;
  DateTime start;
  Duration duration;
  String location;
  String kind; // Meeting, Deadline, Renewal, Follow-up
  String? relatedId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    this.duration = const Duration(hours: 1),
    this.location = '',
    this.kind = 'Meeting',
    this.relatedId,
  });

  DateTime get end => start.add(duration);

  factory CalendarEvent.fromMap(Map<String, dynamic> m) => CalendarEvent(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        start: parseTs(m['start_at']) ?? DateTime.now(),
        duration: Duration(minutes: toInt(m['duration_minutes'], 60)),
        location: m['location'] as String? ?? '',
        kind: m['kind'] as String? ?? 'Meeting',
        relatedId: m['related_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'start_at': tsStr(start),
        'duration_minutes': duration.inMinutes,
        'location': location,
        'kind': kind,
        'related_id': relatedId,
      };
}

class EmailItem {
  final String id;
  final String from;
  final String fromAddress;
  final String subject;
  final String body;
  final DateTime received;
  final EmailKind kind;
  final Priority priority;

  /// AI-generated one-line summary.
  final String aiSummary;

  /// AI-suggested action, if any.
  final String? aiAction;
  final DateTime? deadline;
  final String? relatedCustomerId;
  final String? relatedSupplierId;
  bool read;
  bool handled;

  EmailItem({
    required this.id,
    required this.from,
    required this.fromAddress,
    required this.subject,
    required this.body,
    required this.received,
    required this.kind,
    required this.priority,
    required this.aiSummary,
    this.aiAction,
    this.deadline,
    this.relatedCustomerId,
    this.relatedSupplierId,
    this.read = false,
    this.handled = false,
  });

  factory EmailItem.fromMap(Map<String, dynamic> m) => EmailItem(
        id: m['id'] as String,
        from: m['from_name'] as String? ?? '',
        fromAddress: m['from_address'] as String? ?? '',
        subject: m['subject'] as String? ?? '',
        body: m['body'] as String? ?? '',
        received: parseTs(m['received_at']) ?? DateTime.now(),
        kind: EmailKindWire.fromWire(m['kind'] as String?),
        priority: PriorityWire.fromWire(m['priority'] as String?),
        aiSummary: m['ai_summary'] as String? ?? '',
        aiAction: m['ai_action'] as String?,
        deadline: parseTs(m['deadline']),
        relatedCustomerId: m['related_customer_id'] as String?,
        relatedSupplierId: m['related_supplier_id'] as String?,
        read: m['read'] as bool? ?? false,
        handled: m['handled'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'from_name': from,
        'from_address': fromAddress,
        'subject': subject,
        'body': body,
        'received_at': tsStr(received),
        'kind': kind.wire,
        'priority': priority.wire,
        'ai_summary': aiSummary,
        'ai_action': aiAction,
        'deadline': tsStr(deadline),
        'related_customer_id': relatedCustomerId,
        'related_supplier_id': relatedSupplierId,
        'read': read,
        'handled': handled,
      };
}

class ActionItem {
  final String text;
  bool done;
  ActionItem(this.text, {this.done = false});

  factory ActionItem.fromMap(Map<String, dynamic> m) =>
      ActionItem(m['text'] as String? ?? '', done: m['done'] as bool? ?? false);

  Map<String, dynamic> toMap() => {'text': text, 'done': done};
}

class Meeting {
  final String id;
  String title;
  DateTime date;
  List<String> attendees;
  String summary;
  List<String> decisions;
  List<ActionItem> actionItems;
  bool processed;

  Meeting({
    required this.id,
    required this.title,
    required this.date,
    required this.attendees,
    this.summary = '',
    this.decisions = const [],
    this.actionItems = const [],
    this.processed = false,
  });

  factory Meeting.fromMap(Map<String, dynamic> m) => Meeting(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        date: parseTs(m['meeting_date']) ?? DateTime.now(),
        attendees: strList(m['attendees']),
        summary: m['summary'] as String? ?? '',
        decisions: strList(m['decisions']),
        actionItems: ((m['action_items'] as List?) ?? [])
            .map((e) => ActionItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        processed: m['processed'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'meeting_date': tsStr(date),
        'attendees': attendees,
        'summary': summary,
        'decisions': decisions,
        'action_items': actionItems.map((a) => a.toMap()).toList(),
        'processed': processed,
      };
}

class Note {
  final String id;
  String title;
  String body;
  DateTime created;
  List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.created,
    this.tags = const [],
  });

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        created: parseTs(m['created_at']) ?? DateTime.now(),
        tags: strList(m['tags']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'tags': tags,
      };
}

class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;
  ChatMessage({required this.text, required this.fromUser, DateTime? time})
      : time = time ?? DateTime.now();
}

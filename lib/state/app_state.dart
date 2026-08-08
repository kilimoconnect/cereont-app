import 'package:flutter/foundation.dart';

import '../models/business.dart';
import '../models/enums.dart';
import '../models/executive_brief.dart';
import '../models/project_engine.dart';
import '../models/work.dart';
import '../services/ai_engine.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/repository.dart';

/// The single source of truth for the app. Holds the business memory for the
/// current company in memory (loaded from Supabase) and writes changes back
/// optimistically.
class AppState extends ChangeNotifier {
  final CereontRepository repo = CereontRepository();

  /// Null until the user creates / joins a company.
  String? companyId;

  /// Kept non-null (empty placeholder) so screens can read it directly.
  Company company = Company(
    name: '',
    industry: '',
    tagline: '',
    productsServices: const [],
    departments: const [],
    goals: const [],
  );

  final List<Customer> customers = [];
  final List<Supplier> suppliers = [];
  final List<Product> products = [];
  final List<Project> projects = [];
  final List<Task> tasks = [];
  final List<CalendarEvent> events = [];
  final List<EmailItem> emails = [];
  final List<Meeting> meetings = [];
  final List<Note> notes = [];
  final List<TimelineEvent> timeline = [];
  final List<ChatMessage> chat = [];

  late final AiEngine ai = AiEngine(this);
  final AiService _aiService = AiService();

  /// True while awaiting an AI reply (drives the chat typing indicator).
  bool aiThinking = false;

  /// Which backend answered the last message ('openai' | 'gemini' | 'offline').
  String? lastAiProvider;

  /// The current executive brief (AI-generated, or offline fallback).
  ExecutiveBrief? brief;
  bool briefLoading = false;

  bool loading = false;
  bool ready = false;
  String? loadError;

  bool emailSyncing = false;
  String? emailSyncMessage;

  bool get hasCompany => companyId != null;

  int _seq = 1000;
  String newId(String prefix) => '$prefix${_seq++}';

  // ---- Bootstrapping ---------------------------------------------------
  /// Loads the user's company (if any) and all of its data.
  Future<void> bootstrap() async {
    _reset();
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      companyId = await repo.currentCompanyId();
      if (companyId != null) {
        await _loadAll();
        loadBrief(); // fire-and-forget; UI updates when ready
      }
    } catch (e) {
      loadError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAll() async {
    final cid = companyId!;
    company = (await repo.loadCompany(cid)) ?? company;
    final results = await Future.wait([
      repo.fetchCustomers(cid),
      repo.fetchSuppliers(cid),
      repo.fetchProducts(cid),
      repo.fetchProjects(cid),
      repo.fetchTasks(cid),
      repo.fetchEvents(cid),
      repo.fetchEmails(cid),
      repo.fetchMeetings(cid),
      repo.fetchNotes(cid),
      repo.fetchTimeline(cid),
    ]);
    _replace(customers, results[0] as List<Customer>);
    _replace(suppliers, results[1] as List<Supplier>);
    _replace(products, results[2] as List<Product>);
    _replace(projects, results[3] as List<Project>);
    _replace(tasks, results[4] as List<Task>);
    _replace(events, results[5] as List<CalendarEvent>);
    _replace(emails, results[6] as List<EmailItem>);
    _replace(meetings, results[7] as List<Meeting>);
    _replace(notes, results[8] as List<Note>);
    _replace(timeline, results[9] as List<TimelineEvent>);
    ready = true;
  }

  void _replace<T>(List<T> target, List<T> source) {
    target
      ..clear()
      ..addAll(source);
  }

  /// Clears all in-memory state (used before (re)bootstrapping / on sign-out).
  void _reset() {
    companyId = null;
    ready = false;
    brief = null;
    briefLoading = false;
    company = Company(
      name: '',
      industry: '',
      tagline: '',
      productsServices: const [],
      departments: const [],
      goals: const [],
    );
    for (final l in [
      customers,
      suppliers,
      products,
      projects,
      tasks,
      events,
      emails,
      meetings,
      notes,
      timeline,
      chat,
    ]) {
      l.clear();
    }
  }

  /// Creates the user's company and switches into it. Errors propagate to the
  /// caller (the onboarding screen) so they can be shown; we deliberately do
  /// NOT set the global `loading` flag here, which would swap the onboarding
  /// screen for the splash and hide any error.
  Future<void> createCompany(Company c) async {
    companyId = await repo.createCompany(c);
    company = c;
    ready = true;
    loadBrief(); // populate the (empty) dashboard in the background
    notifyListeners();
  }

  /// Generates the executive brief via the LLM, falling back to the offline
  /// engine. Cached until [force]d (e.g. pull-to-refresh).
  Future<void> loadBrief({bool force = false}) async {
    if (briefLoading) return;
    if (brief != null && !force) return;
    briefLoading = true;
    notifyListeners();
    try {
      brief = await _aiService.brief();
    } catch (_) {
      brief = ai.localBrief();
    }
    briefLoading = false;
    notifyListeners();
  }

  /// Fire-and-forget persistence with error swallowing (optimistic UI).
  void _persist(Future<void> Function() op) {
    op().catchError((Object e) {
      if (kDebugMode) debugPrint('Cereont persist error: $e');
    });
  }

  // ---- Lookups ---------------------------------------------------------
  Customer? customerById(String? id) =>
      id == null ? null : customers.where((c) => c.id == id).firstOrNull;
  Supplier? supplierById(String? id) =>
      id == null ? null : suppliers.where((s) => s.id == id).firstOrNull;
  Project? projectById(String? id) =>
      id == null ? null : projects.where((p) => p.id == id).firstOrNull;

  // ---- Derived task views ---------------------------------------------
  List<Task> get openTasks => tasks.where((t) => !t.isDone).toList();

  List<Task> get todaysPriorities {
    final list = openTasks.toList()
      ..sort((a, b) {
        final byPriority = b.priority.weight.compareTo(a.priority.weight);
        if (byPriority != 0) return byPriority;
        final ad = a.due, bd = b.due;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    return list;
  }

  List<Task> get overdueTasks => openTasks.where((t) => t.isOverdue).toList();

  List<Task> tasksDueOn(DateTime day) => tasks.where((t) {
        final d = t.due;
        return d != null &&
            d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).toList();

  List<CalendarEvent> eventsOn(DateTime day) => (events
          .where((e) =>
              e.start.year == day.year &&
              e.start.month == day.month &&
              e.start.day == day.day)
          .toList())
      ..sort((a, b) => a.start.compareTo(b.start));

  List<CalendarEvent> get todaysEvents => eventsOn(DateTime.now());

  int get unreadEmails => emails.where((e) => !e.read).length;

  // ---- Relationship graph (everything related to X) --------------------
  bool _mentions(String text, String name) {
    final t = text.toLowerCase();
    if (name.isNotEmpty && t.contains(name.toLowerCase())) return true;
    final first = name.split(' ').first.toLowerCase();
    return first.length > 2 && t.contains(first);
  }

  List<Meeting> meetingsMentioning(String name) => meetings
      .where((m) =>
          _mentions('${m.title} ${m.summary} ${m.attendees.join(' ')}', name))
      .toList();

  List<TimelineEvent> timelineMentioning(String name) => timeline
      .where((e) => _mentions('${e.title} ${e.detail}', name))
      .toList();

  List<Note> notesMentioning(String name) =>
      notes.where((n) => _mentions('${n.title} ${n.body}', name)).toList();

  // ---- Task mutations --------------------------------------------------
  void toggleTask(Task t) {
    t.status = t.isDone ? TaskStatus.open : TaskStatus.done;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateTask(t));
  }

  void setTaskStatus(Task t, TaskStatus s) {
    t.status = s;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateTask(t));
  }

  void addTask(Task t) {
    tasks.add(t);
    notifyListeners();
    if (companyId != null) {
      _persist(() async {
        final saved = await repo.insertTask(companyId!, t);
        final i = tasks.indexWhere((x) => x.id == t.id);
        if (i != -1) tasks[i] = saved;
        notifyListeners();
      });
    }
  }

  void updateTask(Task original, Task edited) {
    final i = tasks.indexWhere((t) => t.id == original.id);
    if (i != -1) tasks[i] = edited;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateTask(edited));
  }

  void deleteTask(Task t) {
    tasks.removeWhere((x) => x.id == t.id);
    notifyListeners();
    if (companyId != null) _persist(() => repo.deleteTask(t.id));
  }

  // ---- Email mutations -------------------------------------------------
  void markEmailRead(EmailItem e) {
    if (!e.read) {
      e.read = true;
      notifyListeners();
      if (companyId != null) _persist(() => repo.updateEmail(e));
    }
  }

  void toggleEmailHandled(EmailItem e) {
    e.handled = !e.handled;
    e.read = true;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateEmail(e));
  }

  /// Turn an email's AI-suggested action into a real task.
  Task createTaskFromEmail(EmailItem e) {
    final t = Task(
      id: newId('t'),
      title: e.aiAction ?? 'Follow up: ${e.subject}',
      priority: e.priority,
      due: e.deadline,
      source: 'Email',
      relatedCustomerId: e.relatedCustomerId,
      relatedSupplierId: e.relatedSupplierId,
    );
    tasks.add(t);
    e.handled = true;
    notifyListeners();
    if (companyId != null) {
      _persist(() async {
        final saved = await repo.insertTask(companyId!, t);
        final i = tasks.indexWhere((x) => x.id == t.id);
        if (i != -1) tasks[i] = saved;
        await repo.updateEmail(e);
        notifyListeners();
      });
    }
    return t;
  }

  // ---- Memory entity creation -----------------------------------------
  void addCustomer(Customer c) => _addEntity(customers, c, () async {
        final saved = await repo.insertCustomer(companyId!, c);
        _swap(customers, c.id, saved, (x) => x.id);
      });

  void addSupplier(Supplier s) => _addEntity(suppliers, s, () async {
        final saved = await repo.insertSupplier(companyId!, s);
        _swap(suppliers, s.id, saved, (x) => x.id);
      });

  void addProduct(Product p) => _addEntity(products, p, () async {
        final saved = await repo.insertProduct(companyId!, p);
        _swap(products, p.id, saved, (x) => x.id);
      });

  void addProject(Project p) => _addEntity(projects, p, () async {
        final saved = await repo.insertProject(companyId!, p);
        _swap(projects, p.id, saved, (x) => x.id);
      });

  // ---- Project engine --------------------------------------------------
  ProjectDetail? currentDetail;
  String? detailProjectId;
  bool detailLoading = false;

  /// Creates a project with an AI-generated plan (milestones, tasks, risks).
  Future<Project> createPlannedProject(Project base, ProjectPlan plan) async {
    final saved = await repo.createProjectWithPlan(companyId!, base, plan);
    projects.insert(0, saved);
    // Reload tasks so the AI-generated ones appear.
    _replace(tasks, await repo.fetchTasks(companyId!));
    notifyListeners();
    return saved;
  }

  Future<void> loadProjectDetail(String projectId, {bool force = false}) async {
    if (detailLoading) return;
    if (detailProjectId == projectId && currentDetail != null && !force) return;
    detailLoading = true;
    detailProjectId = projectId;
    currentDetail = null;
    notifyListeners();
    try {
      currentDetail = await repo.loadProjectDetail(projectId);
    } catch (_) {
      currentDetail = ProjectDetail(
        milestones: [], risks: [], resources: [], budget: [],
        decisions: [], lessons: [], updates: [],
      );
    }
    detailLoading = false;
    notifyListeners();
  }

  /// Milestone completion + task completion → 0..100 project health.
  int projectHealth(Project p, ProjectDetail? d) {
    final projTasks =
        tasks.where((t) => t.relatedProjectId == p.id).toList();
    final doneTasks = projTasks.where((t) => t.isDone).length;
    final taskPct = projTasks.isEmpty ? 1.0 : doneTasks / projTasks.length;
    final ms = d?.milestones ?? const [];
    final msPct = ms.isEmpty
        ? taskPct
        : ms.where((m) => m.isDone).length / ms.length;
    double s = 100;
    s -= projTasks.where((t) => t.isOverdue).length * 5;
    final risks = d?.risks ?? const [];
    s -= risks.where((r) => r.status == 'open' && r.severity >= 3).length * 10;
    s -= risks.where((r) => r.status == 'open').length * 3;
    if (p.status == 'At risk') s -= 15;
    if (p.daysToDeadline < 0 && msPct < 1) s -= 20;
    s = s * (0.6 + 0.4 * msPct);
    return s.clamp(0, 100).round();
  }

  void setMilestoneStatus(Milestone m, String status) {
    m.status = status;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateMilestone(m));
  }

  void setRiskStatus(ProjectRisk r, String status) {
    r.status = status;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateRisk(r));
  }

  void addProjectRisk(String projectId, ProjectRisk r) {
    currentDetail?.risks.add(r);
    notifyListeners();
    if (companyId != null) {
      _persist(() async {
        final saved = await repo.addRisk(companyId!, projectId, r);
        final list = currentDetail?.risks;
        if (list != null) _swap(list, r.id, saved, (x) => x.id);
        notifyListeners();
      });
    }
  }

  void addProjectUpdate(String projectId, ProjectUpdate u) {
    currentDetail?.updates.insert(0, u);
    notifyListeners();
    if (companyId != null) _persist(() => repo.addUpdate(companyId!, projectId, u));
  }

  void addProjectDecision(String projectId, ProjectDecision d) {
    currentDetail?.decisions.insert(0, d);
    notifyListeners();
    if (companyId != null) {
      _persist(() => repo.addDecision(companyId!, projectId, d));
    }
  }

  void addProjectLesson(String projectId, ProjectLesson l) {
    currentDetail?.lessons.insert(0, l);
    notifyListeners();
    if (companyId != null) _persist(() => repo.addLesson(companyId!, projectId, l));
  }

  void addProjectResource(String projectId, ProjectResource x) {
    currentDetail?.resources.add(x);
    notifyListeners();
    if (companyId != null) {
      _persist(() => repo.addResource(companyId!, projectId, x));
    }
  }

  void addBudgetLine(String projectId, BudgetLine x) {
    currentDetail?.budget.add(x);
    notifyListeners();
    if (companyId != null) _persist(() => repo.addBudgetLine(companyId!, projectId, x));
  }

  void updateProject(Project p) {
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateProject(p));
  }

  // ---- Project hub helpers --------------------------------------------
  List<Project> get liveProjects =>
      projects.where((p) => !p.archived).toList();

  void archiveProject(Project p, bool archived) {
    p.archived = archived;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateProject(p));
  }

  void deleteProject(Project p) {
    projects.removeWhere((x) => x.id == p.id);
    notifyListeners();
    if (companyId != null) _persist(() => repo.deleteProject(p.id));
  }

  /// Quick, detail-free health used for hub cards (task + status based).
  int quickHealth(Project p) => projectHealth(p, null);

  /// A short AI-flavoured status line for a project card.
  String projectStatusLine(Project p) {
    if (p.status == 'Done' || p.status == 'Completed') return 'Completed';
    final t = tasks.where((x) => x.relatedProjectId == p.id);
    final overdue = t.where((x) => x.isOverdue).length;
    if (overdue > 0) return '$overdue overdue task(s) need attention';
    final h = quickHealth(p);
    if (h < 50) return 'Critical — needs immediate attention';
    if (h < 70) return 'Needs attention';
    final dl = p.daysToDeadline;
    if (dl < 0) return 'Past deadline';
    return 'On track · $dl day${dl == 1 ? '' : 's'} left';
  }

  void addNote(Note n) {
    notes.insert(0, n);
    notifyListeners();
    if (companyId != null) {
      _persist(() async {
        final saved = await repo.insertNote(companyId!, n);
        _swap(notes, n.id, saved, (x) => x.id);
        notifyListeners();
      });
    }
  }

  void _addEntity<T>(List<T> list, T item, Future<void> Function() persist) {
    list.add(item);
    notifyListeners();
    if (companyId != null) {
      _persist(() async {
        await persist();
        notifyListeners();
      });
    }
  }

  void _swap<T>(List<T> list, String oldId, T fresh, String Function(T) id) {
    final i = list.indexWhere((x) => id(x) == oldId);
    if (i != -1) list[i] = fresh;
  }

  // ---- Meetings --------------------------------------------------------
  void addMeeting(Meeting m) {
    meetings.insert(0, m);
    notifyListeners();
    if (companyId != null) {
      _persist(() async {
        final saved = await repo.insertMeeting(companyId!, m);
        _swap(meetings, m.id, saved, (x) => x.id);
        notifyListeners();
      });
    }
  }

  void processMeeting(Meeting m) {
    for (final a in m.actionItems) {
      if (!a.done) {
        addTask(Task(
          id: newId('t'),
          title: a.text,
          priority: Priority.medium,
          source: 'Meeting',
        ));
      }
    }
    m.processed = true;
    notifyListeners();
    if (companyId != null) _persist(() => repo.updateMeeting(m));
  }

  void toggleActionItem(ActionItem a) {
    a.done = !a.done;
    notifyListeners();
  }

  // ---- Email sync (Gmail) ----------------------------------------------
  bool get gmailConnected =>
      (AuthService.instance.providerToken ?? '').isNotEmpty;

  Future<void> connectGmail() => AuthService.instance.connectGmail();

  Future<void> syncEmails() async {
    final token = AuthService.instance.providerToken;
    if (token == null || token.isEmpty) {
      emailSyncMessage = 'Connect Gmail first.';
      notifyListeners();
      return;
    }
    emailSyncing = true;
    emailSyncMessage = null;
    notifyListeners();
    try {
      final n = await repo.syncGmail(token);
      if (companyId != null) {
        _replace(emails, await repo.fetchEmails(companyId!));
      }
      emailSyncMessage = n > 0 ? 'Synced $n new email(s).' : 'No new emails.';
    } catch (e) {
      emailSyncMessage = 'Sync failed — reconnect Gmail and try again.';
    } finally {
      emailSyncing = false;
      notifyListeners();
    }
  }

  // ---- Chat ------------------------------------------------------------
  /// Sends a message to the AI. Tries the LLM edge function first and falls
  /// back to the offline rules engine if it's unavailable.
  Future<void> sendChat(String text) async {
    final history = List<ChatMessage>.from(chat);
    chat.add(ChatMessage(text: text, fromUser: true));
    aiThinking = true;
    notifyListeners();

    String reply;
    try {
      final r = await _aiService.chat(message: text, history: history);
      reply = r.text;
      lastAiProvider = r.provider;
    } catch (_) {
      reply = ai.answer(text); // offline fallback
      lastAiProvider = 'offline';
    }

    aiThinking = false;
    chat.add(ChatMessage(text: reply, fromUser: false));
    notifyListeners();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

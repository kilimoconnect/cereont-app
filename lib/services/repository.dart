import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business.dart';
import '../models/project_engine.dart';
import '../models/work.dart';
import 'ai_service.dart';

/// RFC-4122 v4 UUID (so we can set ids client-side and avoid a post-insert
/// read that RLS could block).
String _uuidV4() {
  final rnd = Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = List.generate(16, h).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
      '${s.substring(16, 20)}-${s.substring(20)}';
}

const _priorities = {'critical', 'high', 'medium', 'low'};
const _levels = {'low', 'medium', 'high'};
String _prio(String s) => _priorities.contains(s) ? s : 'medium';
String _lvl(String s) => _levels.contains(s) ? s : 'medium';

/// All reads/writes against the Supabase Postgres tables. Every method is
/// scoped to a single company; RLS enforces that the user is a member.
class CereontRepository {
  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  // ---- Company / membership ------------------------------------------
  /// The first company the current user belongs to, or null if none yet.
  Future<String?> currentCompanyId() async {
    final uid = _uid;
    if (uid == null) return null;
    final rows = await _db
        .from('company_members')
        .select('company_id, created_at')
        .eq('user_id', uid)
        .order('created_at')
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['company_id'] as String;
  }

  Future<Company?> loadCompany(String companyId) async {
    final row = await _db
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();
    return row == null ? null : Company.fromMap(row);
  }

  /// Creates a company owned by the current user and returns its id.
  /// The id is generated client-side so we don't need a post-insert read
  /// (which RLS could reject before the owner-membership trigger is visible).
  Future<String> createCompany(Company c) async {
    // Ensure the owner's profile row exists (companies.owner_id → profiles.id).
    // Harmless if the signup trigger already created it.
    final user = _db.auth.currentUser;
    if (user != null) {
      await _db.from('profiles').upsert(
        {'id': user.id, 'email': user.email},
        onConflict: 'id',
      );
    }
    final id = _uuidV4();
    final map = c.toMap()
      ..['id'] = id
      ..['owner_id'] = _uid;
    await _db.from('companies').insert(map);
    return id;
  }

  Future<void> updateCompany(String companyId, Company c) async {
    await _db.from('companies').update(c.toMap()).eq('id', companyId);
  }

  // ---- Bulk load ------------------------------------------------------
  Future<List<Customer>> fetchCustomers(String cid) async {
    final rows = await _db
        .from('customers')
        .select()
        .eq('company_id', cid)
        .order('lifetime_value', ascending: false);
    return rows.map((e) => Customer.fromMap(e)).toList();
  }

  Future<List<Supplier>> fetchSuppliers(String cid) async {
    final rows = await _db
        .from('suppliers')
        .select()
        .eq('company_id', cid)
        .order('on_time_rate', ascending: false);
    return rows.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<List<Product>> fetchProducts(String cid) async {
    final rows =
        await _db.from('products').select().eq('company_id', cid).order('name');
    return rows.map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Project>> fetchProjects(String cid) async {
    final rows = await _db
        .from('projects')
        .select()
        .eq('company_id', cid)
        .order('deadline');
    return rows.map((e) => Project.fromMap(e)).toList();
  }

  Future<List<Task>> fetchTasks(String cid) async {
    final rows = await _db
        .from('tasks')
        .select()
        .eq('company_id', cid)
        .order('created_at');
    return rows.map((e) => Task.fromMap(e)).toList();
  }

  Future<List<CalendarEvent>> fetchEvents(String cid) async {
    final rows = await _db
        .from('calendar_events')
        .select()
        .eq('company_id', cid)
        .order('start_at');
    return rows.map((e) => CalendarEvent.fromMap(e)).toList();
  }

  Future<List<EmailItem>> fetchEmails(String cid) async {
    final rows = await _db
        .from('emails')
        .select()
        .eq('company_id', cid)
        .order('received_at', ascending: false);
    return rows.map((e) => EmailItem.fromMap(e)).toList();
  }

  Future<List<Meeting>> fetchMeetings(String cid) async {
    final rows = await _db
        .from('meetings')
        .select()
        .eq('company_id', cid)
        .order('meeting_date', ascending: false);
    return rows.map((e) => Meeting.fromMap(e)).toList();
  }

  Future<List<Note>> fetchNotes(String cid) async {
    final rows = await _db
        .from('notes')
        .select()
        .eq('company_id', cid)
        .order('created_at', ascending: false);
    return rows.map((e) => Note.fromMap(e)).toList();
  }

  Future<List<TimelineEvent>> fetchTimeline(String cid) async {
    final rows = await _db
        .from('timeline_events')
        .select()
        .eq('company_id', cid)
        .order('event_date', ascending: false);
    return rows.map((e) => TimelineEvent.fromMap(e)).toList();
  }

  // ---- Tasks ----------------------------------------------------------
  Future<Task> insertTask(String cid, Task t) async {
    final map = t.toMap()
      ..['company_id'] = cid
      ..['created_by'] = _uid;
    final row = await _db.from('tasks').insert(map).select().single();
    return Task.fromMap(row);
  }

  Future<void> updateTask(Task t) =>
      _db.from('tasks').update(t.toMap()).eq('id', t.id);

  Future<void> deleteTask(String id) => _db.from('tasks').delete().eq('id', id);

  // ---- Customers / suppliers / products / projects --------------------
  Future<Customer> insertCustomer(String cid, Customer c) async {
    final map = c.toMap()..['company_id'] = cid;
    final row = await _db.from('customers').insert(map).select().single();
    return Customer.fromMap(row);
  }

  Future<Supplier> insertSupplier(String cid, Supplier s) async {
    final map = s.toMap()..['company_id'] = cid;
    final row = await _db.from('suppliers').insert(map).select().single();
    return Supplier.fromMap(row);
  }

  Future<Product> insertProduct(String cid, Product p) async {
    final map = p.toMap()..['company_id'] = cid;
    final row = await _db.from('products').insert(map).select().single();
    return Product.fromMap(row);
  }

  Future<Project> insertProject(String cid, Project p) async {
    final map = p.toMap()..['company_id'] = cid;
    final row = await _db.from('projects').insert(map).select().single();
    return Project.fromMap(row);
  }

  Future<void> updateProject(Project p) =>
      _db.from('projects').update(p.toMap()).eq('id', p.id);

  // ---- Project engine -------------------------------------------------
  /// Inserts a project plus its AI-generated milestones, tasks and risks.
  Future<Project> createProjectWithPlan(
      String cid, Project base, ProjectPlan plan) async {
    final row = await _db
        .from('projects')
        .insert(base.toMap()..['company_id'] = cid..['owner_id'] = _uid)
        .select()
        .single();
    final project = Project.fromMap(row);

    var order = 0;
    for (final ms in plan.milestones) {
      final mrow = await _db.from('project_milestones').insert({
        'company_id': cid,
        'project_id': project.id,
        'title': ms.title,
        'order_index': order++,
        'status': 'pending',
      }).select('id').single();
      final mid = mrow['id'] as String;
      for (final t in ms.tasks) {
        await _db.from('tasks').insert({
          'company_id': cid,
          'title': t.title,
          'priority': _prio(t.priority),
          'status': 'open',
          'source': 'AI',
          'related_project_id': project.id,
          'milestone_id': mid,
          'created_by': _uid,
        });
      }
    }
    for (final r in plan.risks) {
      await _db.from('project_risks').insert({
        'company_id': cid,
        'project_id': project.id,
        'title': r.title,
        'probability': _lvl(r.probability),
        'impact': _lvl(r.impact),
        'mitigation': r.mitigation,
        'status': 'open',
      });
    }
    return project;
  }

  Future<ProjectDetail> loadProjectDetail(String pid) async {
    final r = await Future.wait([
      _db.from('project_milestones').select().eq('project_id', pid).order('order_index'),
      _db.from('project_risks').select().eq('project_id', pid),
      _db.from('project_resources').select().eq('project_id', pid),
      _db.from('project_budget').select().eq('project_id', pid),
      _db.from('project_decisions').select().eq('project_id', pid).order('created_at', ascending: false),
      _db.from('project_lessons').select().eq('project_id', pid).order('created_at', ascending: false),
      _db.from('project_updates').select().eq('project_id', pid).order('created_at', ascending: false),
    ]);
    return ProjectDetail(
      milestones: (r[0]).map(Milestone.fromMap).toList(),
      risks: (r[1]).map(ProjectRisk.fromMap).toList(),
      resources: (r[2]).map(ProjectResource.fromMap).toList(),
      budget: (r[3]).map(BudgetLine.fromMap).toList(),
      decisions: (r[4]).map(ProjectDecision.fromMap).toList(),
      lessons: (r[5]).map(ProjectLesson.fromMap).toList(),
      updates: (r[6]).map(ProjectUpdate.fromMap).toList(),
    );
  }

  Future<void> updateMilestone(Milestone m) =>
      _db.from('project_milestones').update(m.toMap()).eq('id', m.id);

  Future<Milestone> addMilestone(String cid, String pid, Milestone m) async {
    final row = await _db
        .from('project_milestones')
        .insert(m.toMap()..['company_id'] = cid..['project_id'] = pid)
        .select()
        .single();
    return Milestone.fromMap(row);
  }

  Future<void> updateRisk(ProjectRisk r) =>
      _db.from('project_risks').update(r.toMap()).eq('id', r.id);

  Future<ProjectRisk> addRisk(String cid, String pid, ProjectRisk r) async {
    final row = await _db
        .from('project_risks')
        .insert(r.toMap()..['company_id'] = cid..['project_id'] = pid)
        .select()
        .single();
    return ProjectRisk.fromMap(row);
  }

  Future<T> _insertChild<T>(String table, String cid, String pid,
      Map<String, dynamic> map, T Function(Map<String, dynamic>) f) async {
    final row = await _db
        .from(table)
        .insert(map..['company_id'] = cid..['project_id'] = pid)
        .select()
        .single();
    return f(row);
  }

  Future<ProjectResource> addResource(String cid, String pid, ProjectResource x) =>
      _insertChild('project_resources', cid, pid, x.toMap(), ProjectResource.fromMap);
  Future<BudgetLine> addBudgetLine(String cid, String pid, BudgetLine x) =>
      _insertChild('project_budget', cid, pid, x.toMap(), BudgetLine.fromMap);
  Future<ProjectDecision> addDecision(String cid, String pid, ProjectDecision x) =>
      _insertChild('project_decisions', cid, pid, x.toMap(), ProjectDecision.fromMap);
  Future<ProjectLesson> addLesson(String cid, String pid, ProjectLesson x) =>
      _insertChild('project_lessons', cid, pid, x.toMap(), ProjectLesson.fromMap);
  Future<ProjectUpdate> addUpdate(String cid, String pid, ProjectUpdate x) =>
      _insertChild('project_updates', cid, pid, x.toMap(), ProjectUpdate.fromMap);

  // ---- Notes / meetings / emails --------------------------------------
  Future<Note> insertNote(String cid, Note n) async {
    final map = n.toMap()..['company_id'] = cid;
    final row = await _db.from('notes').insert(map).select().single();
    return Note.fromMap(row);
  }

  Future<Meeting> insertMeeting(String cid, Meeting m) async {
    final map = m.toMap()..['company_id'] = cid;
    final row = await _db.from('meetings').insert(map).select().single();
    return Meeting.fromMap(row);
  }

  Future<void> updateMeeting(Meeting m) =>
      _db.from('meetings').update(m.toMap()).eq('id', m.id);

  Future<void> updateEmail(EmailItem e) =>
      _db.from('emails').update(e.toMap()).eq('id', e.id);

  /// Invokes the `email-sync` edge function with a Google access token.
  /// Returns the number of newly imported emails.
  Future<int> syncGmail(String providerToken) async {
    final res = await _db.functions.invoke(
      'email-sync',
      body: {'providerToken': providerToken},
    );
    final data = res.data;
    if (data is Map && data['synced'] is int) return data['synced'] as int;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return 0;
  }
}

import 'enums.dart';
import 'serial.dart';

/// The user's own company profile — the root of the business memory.
class Company {
  String name;
  String industry;
  String tagline;
  List<String> productsServices;
  List<String> departments;
  List<String> goals;
  String currency;

  Company({
    required this.name,
    required this.industry,
    required this.tagline,
    required this.productsServices,
    required this.departments,
    required this.goals,
    this.currency = '\$',
  });

  factory Company.fromMap(Map<String, dynamic> m) => Company(
        name: m['name'] as String? ?? '',
        industry: m['industry'] as String? ?? '',
        tagline: m['tagline'] as String? ?? '',
        productsServices: strList(m['products_services']),
        departments: strList(m['departments']),
        goals: strList(m['goals']),
        currency: m['currency'] as String? ?? '\$',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'industry': industry,
        'tagline': tagline,
        'products_services': productsServices,
        'departments': departments,
        'goals': goals,
        'currency': currency,
      };
}

class Contact {
  final String name;
  final String role;
  final String email;
  final String phone;

  const Contact({
    required this.name,
    required this.role,
    this.email = '',
    this.phone = '',
  });
}

class Customer {
  final String id;
  String name;
  String segment;
  Contact contact;
  double lifetimeValue;

  /// Typical days between orders — used to detect overdue reorders.
  int reorderCycleDays;
  DateTime lastOrder;
  DateTime? lastContact;
  String notes;
  List<String> tags;

  Customer({
    required this.id,
    required this.name,
    required this.segment,
    required this.contact,
    required this.lifetimeValue,
    required this.reorderCycleDays,
    required this.lastOrder,
    this.lastContact,
    this.notes = '',
    this.tags = const [],
  });

  int get daysSinceLastOrder => DateTime.now().difference(lastOrder).inDays;

  /// How overdue the customer is versus their normal cycle (negative = on time).
  int get reorderOverdueDays => daysSinceLastOrder - reorderCycleDays;

  bool get isReorderDue => reorderOverdueDays > 0;

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        segment: m['segment'] as String? ?? '',
        contact: Contact(
          name: m['contact_name'] as String? ?? '',
          role: m['contact_role'] as String? ?? '',
          email: m['contact_email'] as String? ?? '',
          phone: m['contact_phone'] as String? ?? '',
        ),
        lifetimeValue: toDouble(m['lifetime_value']),
        reorderCycleDays: toInt(m['reorder_cycle_days'], 30),
        lastOrder: parseDate(m['last_order']) ?? DateTime.now(),
        lastContact: parseDate(m['last_contact']),
        notes: m['notes'] as String? ?? '',
        tags: strList(m['tags']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'segment': segment,
        'lifetime_value': lifetimeValue,
        'reorder_cycle_days': reorderCycleDays,
        'last_order': dateStr(lastOrder),
        'last_contact': dateStr(lastContact),
        'notes': notes,
        'tags': tags,
        'contact_name': contact.name,
        'contact_role': contact.role,
        'contact_email': contact.email,
        'contact_phone': contact.phone,
      };
}

class Supplier {
  final String id;
  String name;
  List<String> productsSupplied;
  Contact contact;
  String paymentTerms;
  double onTimeRate; // 0..1
  int leadTimeDays;
  String notes;

  Supplier({
    required this.id,
    required this.name,
    required this.productsSupplied,
    required this.contact,
    required this.paymentTerms,
    required this.onTimeRate,
    required this.leadTimeDays,
    this.notes = '',
  });

  String get performanceLabel {
    if (onTimeRate >= 0.9) return 'Reliable';
    if (onTimeRate >= 0.75) return 'Watch';
    return 'At risk';
  }

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        productsSupplied: strList(m['products_supplied']),
        contact: Contact(
          name: m['contact_name'] as String? ?? '',
          role: m['contact_role'] as String? ?? '',
          email: m['contact_email'] as String? ?? '',
          phone: m['contact_phone'] as String? ?? '',
        ),
        paymentTerms: m['payment_terms'] as String? ?? '',
        onTimeRate: toDouble(m['on_time_rate']),
        leadTimeDays: toInt(m['lead_time_days']),
        notes: m['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'products_supplied': productsSupplied,
        'payment_terms': paymentTerms,
        'on_time_rate': onTimeRate,
        'lead_time_days': leadTimeDays,
        'notes': notes,
        'contact_name': contact.name,
        'contact_role': contact.role,
        'contact_email': contact.email,
        'contact_phone': contact.phone,
      };
}

class Product {
  final String id;
  String name;
  String category;
  double price;
  double cost;
  String unit;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.cost,
    this.unit = 'unit',
  });

  double get margin => price <= 0 ? 0 : (price - cost) / price;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        category: m['category'] as String? ?? '',
        price: toDouble(m['price']),
        cost: toDouble(m['cost']),
        unit: m['unit'] as String? ?? 'unit',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'price': price,
        'cost': cost,
        'unit': unit,
      };
}

class Project {
  final String id;
  String name;
  String status;
  DateTime deadline;
  double progress; // 0..1
  List<String> team;
  String notes;

  // Project-engine fields
  String description;
  String category;
  Priority priority;
  DateTime? startDate;
  String projectType;
  String complexity;
  String objective;
  int? healthScore;
  double? budgetAmount;

  Project({
    required this.id,
    required this.name,
    required this.status,
    required this.deadline,
    required this.progress,
    required this.team,
    this.notes = '',
    this.description = '',
    this.category = '',
    this.priority = Priority.medium,
    this.startDate,
    this.projectType = '',
    this.complexity = '',
    this.objective = '',
    this.healthScore,
    this.budgetAmount,
  });

  int get daysToDeadline => deadline.difference(DateTime.now()).inDays;

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        status: m['status'] as String? ?? 'Planning',
        deadline: parseDate(m['deadline']) ??
            parseDate(m['target_date']) ??
            DateTime.now(),
        progress: toDouble(m['progress']),
        team: strList(m['team']),
        notes: m['notes'] as String? ?? '',
        description: m['description'] as String? ?? '',
        category: m['category'] as String? ?? '',
        priority: PriorityWire.fromWire(m['priority'] as String?),
        startDate: parseDate(m['start_date']),
        projectType: m['project_type'] as String? ?? '',
        complexity: m['complexity'] as String? ?? '',
        objective: m['objective'] as String? ?? '',
        healthScore:
            m['health_score'] == null ? null : toInt(m['health_score']),
        budgetAmount:
            m['budget_amount'] == null ? null : toDouble(m['budget_amount']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'deadline': dateStr(deadline),
        'target_date': dateStr(deadline),
        'progress': progress,
        'team': team,
        'notes': notes,
        'description': description,
        'category': category,
        'priority': priority.wire,
        'start_date': dateStr(startDate),
        'project_type': projectType,
        'complexity': complexity,
        'objective': objective,
        if (budgetAmount != null) 'budget_amount': budgetAmount,
      };
}

class TimelineEvent {
  final String id;
  final TimelineKind kind;
  final String title;
  final String detail;
  final DateTime date;

  const TimelineEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.date,
  });

  factory TimelineEvent.fromMap(Map<String, dynamic> m) => TimelineEvent(
        id: m['id'] as String,
        kind: TimelineKindWire.fromWire(m['kind'] as String?),
        title: m['title'] as String? ?? '',
        detail: m['detail'] as String? ?? '',
        date: parseTs(m['event_date']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'kind': kind.wire,
        'title': title,
        'detail': detail,
        'event_date': tsStr(date),
      };
}

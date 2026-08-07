import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/business.dart';
import '../models/enums.dart';
import '../models/executive_brief.dart';
import '../state/app_state.dart';

class BusinessAlert {
  final AlertKind kind;
  final String title;
  final String detail;
  final IconData icon;
  final Priority priority;

  const BusinessAlert({
    required this.kind,
    required this.title,
    required this.detail,
    required this.icon,
    this.priority = Priority.medium,
  });

  Color get color {
    switch (kind) {
      case AlertKind.risk:
        return const Color(0xFFE5484D);
      case AlertKind.opportunity:
        return const Color(0xFF30A46C);
      case AlertKind.attention:
        return const Color(0xFFF5A524);
    }
  }
}

/// A section of the morning brief.
class BriefSection {
  final String heading;
  final IconData icon;
  final List<String> lines;
  const BriefSection(this.heading, this.icon, this.lines);
}

class DailyBrief {
  final String greeting;
  final String date;
  final List<BriefSection> sections;
  final String advice;
  const DailyBrief({
    required this.greeting,
    required this.date,
    required this.sections,
    required this.advice,
  });
}

/// A lightweight, fully-offline "executive assistant". It reasons over the
/// business memory in [AppState] with deterministic rules — a stand-in for a
/// real LLM that would plug in here.
class AiEngine {
  AiEngine(this.state);
  final AppState state;

  final _money = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0);
  final _dayFmt = DateFormat('EEEE, MMM d');

  String money(num v) => _money.format(v);

  // ---- Alerts ----------------------------------------------------------
  List<BusinessAlert> alerts() {
    final list = <BusinessAlert>[];

    // Unanswered customer inquiries.
    for (final e in state.emails.where(
        (e) => e.kind == EmailKind.customerInquiry && !e.handled)) {
      list.add(BusinessAlert(
        kind: AlertKind.attention,
        title: 'Unanswered: ${e.from}',
        detail: e.aiSummary,
        icon: Icons.mark_email_unread_outlined,
        priority: e.priority,
      ));
    }

    // Overdue invoices.
    for (final e in state.emails
        .where((e) => e.kind == EmailKind.invoice && !e.handled)) {
      list.add(BusinessAlert(
        kind: AlertKind.risk,
        title: 'Overdue invoice',
        detail: e.aiSummary,
        icon: Icons.receipt_long_outlined,
        priority: Priority.critical,
      ));
    }

    // Supplier delays / at-risk performance.
    for (final s in state.suppliers.where((s) => s.onTimeRate < 0.8)) {
      list.add(BusinessAlert(
        kind: AlertKind.risk,
        title: '${s.name} delivery risk',
        detail:
            '${(s.onTimeRate * 100).round()}% on-time. Consider a review or backup supplier.',
        icon: Icons.local_shipping_outlined,
        priority: Priority.high,
      ));
    }

    // Projects at risk / near deadline.
    for (final p in state.projects
        .where((p) => p.status == 'At risk' || p.daysToDeadline <= 10)) {
      list.add(BusinessAlert(
        kind: AlertKind.attention,
        title: 'Project: ${p.name}',
        detail: p.daysToDeadline < 0
            ? 'Past deadline'
            : 'Due in ${p.daysToDeadline} days • ${p.status}',
        icon: Icons.timeline_outlined,
        priority: Priority.high,
      ));
    }

    // Contract renewals within 21 days.
    for (final ev in state.events.where((e) =>
        e.kind == 'Renewal' &&
        e.start.difference(DateTime.now()).inDays <= 21 &&
        e.start.isAfter(DateTime.now()))) {
      final days = ev.start.difference(DateTime.now()).inDays;
      list.add(BusinessAlert(
        kind: AlertKind.attention,
        title: ev.title,
        detail: 'Expires in $days days — start renewal discussion.',
        icon: Icons.event_repeat_outlined,
        priority: Priority.high,
      ));
    }

    list.sort((a, b) => b.priority.weight.compareTo(a.priority.weight));
    return list;
  }

  // ---- Opportunities ---------------------------------------------------
  List<BusinessAlert> opportunities() {
    final list = <BusinessAlert>[];

    // Customers overdue for a reorder based on their normal cycle.
    for (final c in state.customers.where((c) => c.isReorderDue)) {
      list.add(BusinessAlert(
        kind: AlertKind.opportunity,
        title: '${c.name} likely due to reorder',
        detail:
            'Orders every ~${c.reorderCycleDays}d, now ${c.daysSinceLastOrder}d out (${c.reorderOverdueDays}d over). Reach out today.',
        icon: Icons.autorenew_outlined,
        priority: c.reorderOverdueDays > 14 ? Priority.high : Priority.medium,
      ));
    }

    // Growth-tagged accounts.
    for (final c
        in state.customers.where((c) => c.tags.contains('Growth'))) {
      list.add(BusinessAlert(
        kind: AlertKind.opportunity,
        title: '${c.name} is expanding',
        detail: 'Flagged as a growth account — explore an upsell.',
        icon: Icons.trending_up_outlined,
      ));
    }

    return list;
  }

  // ---- Recommendation --------------------------------------------------
  String recommendation() {
    final overdueReorders =
        state.customers.where((c) => c.isReorderDue).toList()
          ..sort((a, b) => b.lifetimeValue.compareTo(a.lifetimeValue));
    if (overdueReorders.isNotEmpty) {
      final c = overdueReorders.first;
      return '${c.name} normally orders every ${c.reorderCycleDays} days and is now '
          '${c.daysSinceLastOrder} days out. As a ${money(c.lifetimeValue)} account, '
          'contacting them today is likely your highest-impact move.';
    }
    if (state.overdueTasks.isNotEmpty) {
      return 'You have ${state.overdueTasks.length} overdue task(s). Clearing the '
          'oldest one first will unblock the most downstream work.';
    }
    return 'Your book of business looks healthy today — focus on advancing your '
        'top project and nurturing key accounts.';
  }

  // ---- Daily brief -----------------------------------------------------
  DailyBrief dailyBrief() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    final focus = state.todaysPriorities.take(3).map((t) {
      final due = t.due == null
          ? ''
          : t.isOverdue
              ? ' (overdue)'
              : '';
      return '${t.title}$due';
    }).toList();

    final risks = <String>[];
    for (final a in alerts().where((a) => a.kind == AlertKind.risk)) {
      risks.add(a.detail);
    }
    if (risks.isEmpty) risks.add('No critical risks flagged right now.');

    final opps = opportunities().map((o) => o.detail).toList();
    if (opps.isEmpty) opps.add('No new opportunities detected today.');

    return DailyBrief(
      greeting: greeting,
      date: _dayFmt.format(DateTime.now()),
      sections: [
        BriefSection("Today's focus", Icons.center_focus_strong_outlined,
            focus.isEmpty ? ['You are all caught up.'] : focus),
        BriefSection('Risks', Icons.warning_amber_outlined, risks.take(3).toList()),
        BriefSection('Opportunities', Icons.lightbulb_outline,
            opps.take(3).toList()),
      ],
      advice: recommendation(),
    );
  }

  // ---- Business health score ------------------------------------------
  /// A 0-100 heuristic used when the LLM is unavailable.
  int businessHealthScore() {
    double s = 100;
    s -= state.overdueTasks.length * 6;
    s -= state.emails
            .where((e) => e.kind == EmailKind.invoice && !e.handled)
            .length *
        10;
    s -= state.suppliers.where((x) => x.onTimeRate < 0.8).length * 8;
    s -= state.projects
            .where((p) => p.status == 'At risk' || p.daysToDeadline < 0)
            .length *
        8;
    s -= state.customers.where((c) => c.isReorderDue).length * 4;
    s -= state.emails
            .where((e) => e.kind == EmailKind.customerInquiry && !e.handled)
            .length *
        3;
    return s.clamp(0, 100).round();
  }

  String _scoreReason(int score) {
    final over = state.overdueTasks.length;
    final due = state.customers.where((c) => c.isReorderDue).length;
    final risky = state.suppliers.where((x) => x.onTimeRate < 0.8).length;
    final parts = <String>[];
    if (over > 0) parts.add('$over overdue task(s)');
    if (due > 0) parts.add('$due follow-up(s) due');
    if (risky > 0) parts.add('$risky supplier risk(s)');
    if (parts.isEmpty) return 'Your book looks clean and on track.';
    return 'Weighed down by ${parts.join(', ')}.';
  }

  String _priorityWhy(t) {
    final c = state.customerById(t.relatedCustomerId);
    if (c != null) {
      final totalLtv =
          state.customers.fold<double>(0, (s, x) => s + x.lifetimeValue);
      final share = totalLtv > 0 ? (c.lifetimeValue / totalLtv * 100).round() : 0;
      if (c.isReorderDue) {
        return '${c.name} is ${c.reorderOverdueDays}d overdue to reorder and is '
            '~$share% of your customer value.';
      }
      return '${c.name} is ~$share% of your customer value.';
    }
    if (t.isOverdue) return 'Overdue — clearing it unblocks downstream work.';
    final s = state.supplierById(t.relatedSupplierId);
    if (s != null) {
      return 'Tied to ${s.name} (${(s.onTimeRate * 100).round()}% on-time).';
    }
    return '${t.priority.label} priority.';
  }

  /// Offline structured brief (fallback when the LLM function is unavailable).
  ExecutiveBrief localBrief() {
    final b = dailyBrief();
    final score = businessHealthScore();
    final priorities = state.todaysPriorities
        .take(3)
        .map((t) => BriefPriority(title: t.title, why: _priorityWhy(t)))
        .toList();
    final risks = alerts()
        .where((a) => a.kind != AlertKind.opportunity)
        .take(3)
        .map((a) => BriefItem(title: a.title, detail: a.detail))
        .toList();
    final opps = opportunities()
        .take(3)
        .map((a) => BriefItem(title: a.title, detail: a.detail))
        .toList();
    return ExecutiveBrief(
      score: score,
      scoreReason: _scoreReason(score),
      greeting: b.greeting,
      headline: recommendation(),
      priorities: priorities,
      risks: risks,
      opportunities: opps,
      recommendation: recommendation(),
      provider: 'offline',
    );
  }

  // ---- Conversational answers -----------------------------------------
  String answer(String raw) {
    final q = raw.toLowerCase().trim();

    bool has(List<String> keys) => keys.any(q.contains);

    // Named customer / supplier lookup.
    for (final c in state.customers) {
      if (q.contains(c.name.toLowerCase().split(' ').first.toLowerCase()) &&
          has(['customer', 'account', 'about', 'tell me', c.name.toLowerCase()])) {
        return _customerSummary(c);
      }
    }

    if (has(['focus', 'today', 'priorit', 'what should i'])) {
      final items = state.todaysPriorities.take(4).toList();
      if (items.isEmpty) return 'You are all caught up — nothing pressing today.';
      final b = StringBuffer("Here's where I'd focus today:\n");
      for (var i = 0; i < items.length; i++) {
        final t = items[i];
        b.writeln('${i + 1}. ${t.title} — ${t.priority.label}'
            '${t.isOverdue ? ' (overdue)' : ''}');
      }
      b.write('\n${recommendation()}');
      return b.toString();
    }

    if (has(['follow', 'reorder', 'overdue customer', 'who needs', 'reach out'])) {
      final due = state.customers.where((c) => c.isReorderDue).toList()
        ..sort((a, b) => b.reorderOverdueDays.compareTo(a.reorderOverdueDays));
      if (due.isEmpty) return 'No customers are overdue for follow-up right now.';
      final b = StringBuffer('These customers are due for follow-up:\n');
      for (final c in due) {
        b.writeln('• ${c.name} — ${c.daysSinceLastOrder}d since last order '
            '(${c.reorderOverdueDays}d over their ${c.reorderCycleDays}d cycle)');
      }
      return b.toString();
    }

    if (has(['supplier', 'vendor'])) {
      final s = state.suppliers.toList()
        ..sort((a, b) => b.onTimeRate.compareTo(a.onTimeRate));
      final b = StringBuffer('Your suppliers by reliability:\n');
      for (final x in s) {
        b.writeln('• ${x.name} — ${(x.onTimeRate * 100).round()}% on-time, '
            '${x.leadTimeDays}d lead, ${x.paymentTerms} (${x.performanceLabel})');
      }
      final weak = s.where((x) => x.onTimeRate < 0.8).toList();
      if (weak.isNotEmpty) {
        b.write('\nWatch: ${weak.map((e) => e.name).join(', ')} '
            'slipping on delivery.');
      }
      return b.toString();
    }

    if (has(['risk', 'worry', 'problem', 'concern'])) {
      final r = alerts().where((a) => a.kind != AlertKind.opportunity).toList();
      if (r.isEmpty) return 'No significant risks flagged right now.';
      final b = StringBuffer('Top things to watch:\n');
      for (final a in r.take(5)) {
        b.writeln('• ${a.title}: ${a.detail}');
      }
      return b.toString();
    }

    if (has(['opportunit', 'grow', 'sales lead', 'upsell'])) {
      final o = opportunities();
      if (o.isEmpty) return 'No new opportunities detected today.';
      final b = StringBuffer('Opportunities worth pursuing:\n');
      for (final a in o) {
        b.writeln('• ${a.title}: ${a.detail}');
      }
      return b.toString();
    }

    if (has(['performance', 'summary', 'how is', 'overview', 'health', 'doing'])) {
      return _performanceSummary();
    }

    if (has(['invoice', 'payment', 'receivable', 'owe', 'cash'])) {
      final inv = state.emails
          .where((e) => e.kind == EmailKind.invoice && !e.handled)
          .toList();
      if (inv.isEmpty) return 'No outstanding invoice issues in your inbox.';
      final b = StringBuffer('Payment items needing attention:\n');
      for (final e in inv) {
        b.writeln('• ${e.aiSummary}');
      }
      return b.toString();
    }

    if (has(['task', 'to-do', 'todo', "to do"])) {
      final open = state.openTasks.length;
      final over = state.overdueTasks.length;
      return 'You have $open open task(s), $over overdue. '
          'Ask me "what should I focus on today?" for a prioritized list.';
    }

    if (has(['meeting'])) {
      final m = state.meetings;
      if (m.isEmpty) return 'No meetings captured yet.';
      final last = m.last;
      return 'Most recent meeting: "${last.title}". '
          '${last.decisions.length} decision(s), '
          '${last.actionItems.length} action item(s). '
          'Summary: ${last.summary}';
    }

    // Fallback.
    return "I'm your Cereont chief of staff. I can help with:\n"
        '• "What should I focus on today?"\n'
        '• "Which customers need follow-up?"\n'
        '• "Who are my most reliable suppliers?"\n'
        '• "What risks should I worry about?"\n'
        '• "Summarize my business performance."';
  }

  String _customerSummary(Customer c) {
    final b = StringBuffer('${c.name} (${c.segment})\n');
    b.writeln('• Contact: ${c.contact.name}, ${c.contact.role}');
    b.writeln('• Lifetime value: ${money(c.lifetimeValue)}');
    b.writeln('• Last order: ${c.daysSinceLastOrder} days ago '
        '(cycle ~${c.reorderCycleDays}d)');
    if (c.isReorderDue) {
      b.writeln('• ⚠ Overdue to reorder by ${c.reorderOverdueDays} days — '
          'good time to reach out.');
    }
    if (c.notes.isNotEmpty) b.writeln('• Notes: ${c.notes}');
    return b.toString();
  }

  String _performanceSummary() {
    final totalLtv =
        state.customers.fold<double>(0, (s, c) => s + c.lifetimeValue);
    final avgMargin = state.products.isEmpty
        ? 0
        : state.products.fold<double>(0, (s, p) => s + p.margin) /
            state.products.length;
    final dueReorders = state.customers.where((c) => c.isReorderDue).length;
    final atRiskSuppliers =
        state.suppliers.where((s) => s.onTimeRate < 0.8).length;
    final b = StringBuffer('Business snapshot for ${state.company.name}:\n');
    b.writeln('• Customers: ${state.customers.length} '
        '(${money(totalLtv)} lifetime value)');
    b.writeln('• Avg product margin: ${(avgMargin * 100).round()}%');
    b.writeln('• Open tasks: ${state.openTasks.length} '
        '(${state.overdueTasks.length} overdue)');
    b.writeln('• Active projects: ${state.projects.length}');
    b.writeln('• Follow-ups due: $dueReorders customer(s)');
    b.writeln('• Supplier risks: $atRiskSuppliers');
    b.write('\n${recommendation()}');
    return b.toString();
  }
}

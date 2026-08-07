import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/related_activity.dart';
import 'entity_forms.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<AppState>().customers.toList()
      ..sort((a, b) => b.lifetimeValue.compareTo(a.lifetimeValue));

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const CustomerEditScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Customer'),
      ),
      body: customers.isEmpty
          ? const EmptyState(
              icon: Icons.people_alt_outlined,
              title: 'No customers yet',
              subtitle: 'Add your first customer to start tracking them.')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: customers.length,
        itemBuilder: (_, i) {
          final c = customers[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(customer: c))),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      InitialsAvatar(c.name, size: 46, color: AppColors.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text('${c.segment} · ${_money(c.lifetimeValue)} LTV',
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (c.isReorderDue)
                        const Pill('Follow up',
                            color: Color(0xFFF5A524),
                            icon: Icons.autorenew_outlined),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _money(num v) =>
      NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0).format(v);
}

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = customer;
    final relatedTasks =
        state.tasks.where((t) => t.relatedCustomerId == c.id).toList();
    final relatedEmails =
        state.emails.where((e) => e.relatedCustomerId == c.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Row(
            children: [
              InitialsAvatar(c.name, size: 60, color: AppColors.accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(c.segment,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (c.isReorderDue)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A524).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFF5A524).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Color(0xFFF5A524), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Overdue to reorder by ${c.reorderOverdueDays} days '
                      '(orders every ~${c.reorderCycleDays}d). Reach out today.',
                      style: const TextStyle(height: 1.3, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          _infoCard(context, [
            _kv('Contact', c.contact.name),
            _kv('Role', c.contact.role),
            if (c.contact.email.isNotEmpty) _kv('Email', c.contact.email),
            if (c.contact.phone.isNotEmpty) _kv('Phone', c.contact.phone),
          ]),
          const SizedBox(height: 12),
          _infoCard(context, [
            _kv('Lifetime value', CustomersScreen._money(c.lifetimeValue)),
            _kv('Reorder cycle', '~${c.reorderCycleDays} days'),
            _kv('Last order', '${c.daysSinceLastOrder} days ago'),
            if (c.lastContact != null)
              _kv('Last contact',
                  DateFormat('MMM d, y').format(c.lastContact!)),
          ]),
          if (c.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(c.notes, style: const TextStyle(height: 1.4)),
              ),
            ),
          ],
          if (c.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: c.tags.map((t) => Pill(t)).toList(),
            ),
          ],
          if (relatedEmails.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader('Related emails'),
            ...relatedEmails.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(e.kind.icon, color: AppColors.brand),
                    title: Text(e.subject,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(e.aiSummary,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                )),
          ],
          if (relatedTasks.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader('Related tasks'),
            ...relatedTasks.map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.flag_outlined,
                        color: t.priority.color),
                    title: Text(t.title),
                    subtitle: Text(t.priority.label),
                  ),
                )),
          ],
          RelatedActivity(name: c.name),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, List<Widget> rows) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: rows),
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

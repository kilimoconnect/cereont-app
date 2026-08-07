import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/related_activity.dart';
import 'entity_forms.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  Color _perfColor(double r) => r >= 0.9
      ? const Color(0xFF30A46C)
      : r >= 0.75
          ? const Color(0xFFF5A524)
          : const Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<AppState>().suppliers.toList()
      ..sort((a, b) => b.onTimeRate.compareTo(a.onTimeRate));

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SupplierEditScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Supplier'),
      ),
      body: suppliers.isEmpty
          ? const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No suppliers yet',
              subtitle: 'Add your first supplier to track performance.')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: suppliers.length,
        itemBuilder: (_, i) {
          final s = suppliers[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SupplierDetailScreen(supplier: s))),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InitialsAvatar(s.name, size: 44),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(s.productsSupplied.join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ],
                            ),
                          ),
                          Pill(s.performanceLabel,
                              color: _perfColor(s.onTimeRate)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _OnTimeBar(rate: s.onTimeRate),
                      const SizedBox(height: 6),
                      Text(
                        '${(s.onTimeRate * 100).round()}% on-time · '
                        '${s.leadTimeDays}d lead · ${s.paymentTerms}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
}

class _OnTimeBar extends StatelessWidget {
  final double rate;
  const _OnTimeBar({required this.rate});
  @override
  Widget build(BuildContext context) {
    final color = rate >= 0.9
        ? const Color(0xFF30A46C)
        : rate >= 0.75
            ? const Color(0xFFF5A524)
            : const Color(0xFFE5484D);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: rate,
        minHeight: 7,
        backgroundColor: Theme.of(context).dividerColor,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class SupplierDetailScreen extends StatelessWidget {
  final Supplier supplier;
  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    final s = supplier;
    final state = context.watch<AppState>();
    final tasks =
        state.tasks.where((t) => t.relatedSupplierId == s.id).toList();
    final emails =
        state.emails.where((e) => e.relatedSupplierId == s.id).toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Row(
            children: [
              InitialsAvatar(s.name, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(s.contact.name.isEmpty
                        ? 'Supplier'
                        : '${s.contact.name} · ${s.contact.role}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _kv('Performance',
                      '${(s.onTimeRate * 100).round()}% on-time (${s.performanceLabel})'),
                  _kv('Lead time', '${s.leadTimeDays} days'),
                  _kv('Payment terms', s.paymentTerms),
                  _kv('Products', s.productsSupplied.join(', ')),
                  if (s.contact.email.isNotEmpty)
                    _kv('Email', s.contact.email),
                ],
              ),
            ),
          ),
          if (s.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(s.notes, style: const TextStyle(height: 1.4)),
              ),
            ),
          ],
          if (emails.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader('Related emails'),
            ...emails.map((e) => Card(
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
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader('Related tasks'),
            ...tasks.map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading:
                        Icon(Icons.flag_outlined, color: t.priority.color),
                    title: Text(t.title),
                    subtitle: Text(t.priority.label),
                  ),
                )),
          ],
          RelatedActivity(name: s.name),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600))),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

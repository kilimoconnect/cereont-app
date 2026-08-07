import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Executive alerts — meaningful, business-intelligence notifications only
/// (silent suppliers, overdue invoices, contracts expiring, reorders due,
/// today's meetings). Not dumb reminders.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ai = state.ai;
    final alerts = ai.alerts();
    final opps = ai.opportunities();
    final today = state.todaysEvents;

    final nothing = alerts.isEmpty && opps.isEmpty && today.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: nothing
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'All clear',
              subtitle: 'No risks, opportunities or meetings need you right now.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                if (today.isNotEmpty) ...[
                  const SectionHeader('Today'),
                  ...today.map((e) => _Row(
                        icon: Icons.event_outlined,
                        color: AppColors.accent,
                        title: e.title,
                        detail:
                            '${DateFormat('h:mm a').format(e.start)} · ${e.kind}',
                      )),
                  const SizedBox(height: 16),
                ],
                if (alerts.isNotEmpty) ...[
                  const SectionHeader('Needs attention'),
                  ...alerts.map((a) => _Row(
                        icon: a.icon,
                        color: a.color,
                        title: a.title,
                        detail: a.detail,
                      )),
                  const SizedBox(height: 16),
                ],
                if (opps.isNotEmpty) ...[
                  const SectionHeader('Opportunities'),
                  ...opps.map((a) => _Row(
                        icon: a.icon,
                        color: a.color,
                        title: a.title,
                        detail: a.detail,
                      )),
                ],
              ],
            ),
    );
  }
}

/// Total count for the bell badge.
int executiveAlertCount(AppState state) {
  final ai = state.ai;
  return ai.alerts().length + ai.opportunities().length;
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  const _Row(
      {required this.icon,
      required this.color,
      required this.title,
      required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(detail,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

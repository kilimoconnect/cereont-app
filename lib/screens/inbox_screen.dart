import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/work.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final emails = state.emails.toList()
      ..sort((a, b) {
        final p = b.priority.weight.compareTo(a.priority.weight);
        if (p != 0) return p;
        return b.received.compareTo(a.received);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Inbox'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                '${state.unreadEmails} unread · AI-triaged by priority',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const _GmailBanner(),
          Expanded(
            child: emails.isEmpty
                ? const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Inbox is empty',
                    subtitle:
                        'Connect Gmail to sync and auto-triage your emails.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: emails.length,
                    itemBuilder: (_, i) => _EmailCard(email: emails[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GmailBanner extends StatelessWidget {
  const _GmailBanner();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final connected = state.gmailConnected;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_read_outlined,
              color: AppColors.brand, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gmail',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  state.emailSyncMessage ??
                      (connected
                          ? 'Sync your inbox — AI triages every email.'
                          : 'Connect to sync and auto-triage your inbox.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state.emailSyncing)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            FilledButton.tonal(
              onPressed: () {
                if (connected) {
                  context.read<AppState>().syncEmails();
                } else {
                  context.read<AppState>().connectGmail();
                }
              },
              child: Text(connected ? 'Sync' : 'Connect'),
            ),
        ],
      ),
    );
  }
}

class _EmailCard extends StatelessWidget {
  final EmailItem email;
  const _EmailCard({required this.email});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(email.from, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!email.read)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                      color: AppColors.brand,
                                      shape: BoxShape.circle),
                                ),
                              Expanded(
                                child: Text(email.from,
                                    style: TextStyle(
                                        fontWeight: email.read
                                            ? FontWeight.w600
                                            : FontWeight.w800)),
                              ),
                              Text(_ago(email.received),
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(email.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // AI intelligence strip.
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.brand.withValues(alpha: 0.20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 13, color: AppColors.brand),
                          const SizedBox(width: 5),
                          const Text('AI',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand)),
                          const Spacer(),
                          if (email.handled)
                            const Pill('Handled',
                                color: Color(0xFF30A46C),
                                icon: Icons.check),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(email.aiSummary,
                          style: const TextStyle(height: 1.35, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Pill(email.kind.label, icon: email.kind.icon),
                    PriorityChip(email.priority, dense: true),
                    if (email.deadline != null)
                      Pill('Due ${DateFormat('MMM d').format(email.deadline!)}',
                          color: const Color(0xFFF5A524),
                          icon: Icons.schedule),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    context.read<AppState>().markEmailRead(email);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EmailSheet(email: email),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _EmailSheet extends StatelessWidget {
  final EmailItem email;
  const _EmailSheet({required this.email});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: [
          Text(email.subject,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              InitialsAvatar(email.from, size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email.from,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(email.fromAddress,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(email.kind.label, icon: email.kind.icon),
              PriorityChip(email.priority, dense: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(email.body, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome,
                        size: 15, color: AppColors.brand),
                    SizedBox(width: 6),
                    Text('AI intelligence',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand)),
                  ],
                ),
                const SizedBox(height: 8),
                _kv('Summary', email.aiSummary),
                if (email.aiAction != null)
                  _kv('Action required', email.aiAction!),
                if (email.deadline != null)
                  _kv('Deadline',
                      DateFormat('EEEE, MMM d').format(email.deadline!)),
                _kv(
                    'Related',
                    state.customerById(email.relatedCustomerId)?.name ??
                        state.supplierById(email.relatedSupplierId)?.name ??
                        'None'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final t = state.createTaskFromEmail(email);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Task created: ${t.title}')));
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('Create task'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    state.toggleEmailHandled(email);
                    Navigator.pop(context);
                  },
                  icon: Icon(email.handled
                      ? Icons.undo
                      : Icons.check_circle_outline),
                  label: Text(email.handled ? 'Reopen' : 'Mark handled'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.brand)),
            const SizedBox(height: 2),
            Text(v, style: const TextStyle(height: 1.35)),
          ],
        ),
      );
}

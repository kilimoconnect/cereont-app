import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/ai_engine.dart';
import '../models/enums.dart';
import '../models/executive_brief.dart';
import '../models/work.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'alerts_screen.dart';
import 'auth/account_sheet.dart';
import 'brief_screen.dart';
import 'home_shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ai = state.ai;
    final alerts = ai.alerts();
    final opps = ai.opportunities();
    final priorities = state.todaysPriorities.take(4).toList();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d')
                                .format(DateTime.now())
                                .toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color),
                          ),
                          const SizedBox(height: 2),
                          Text('$greeting.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall),
                          Text(state.company.name,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const _AlertsBell(),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => AccountSheet.show(context),
                      child: const _BrandMark(),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _healthHero(context, state.brief),
                  const SizedBox(height: 20),
                  _stats(context, state),
                  const SizedBox(height: 24),
                  const SectionHeader("Today's priorities"),
                  if (priorities.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('You are all caught up. 🎉'),
                      ),
                    )
                  else
                    ...priorities.map((t) => _PriorityRow(task: t)),
                  const SizedBox(height: 24),
                  const SectionHeader('Business alerts'),
                  if (alerts.isEmpty)
                    _muted(context, 'No alerts — everything looks steady.')
                  else
                    ...alerts.take(4).map((a) => _AlertCard(alert: a)),
                  const SizedBox(height: 24),
                  const SectionHeader('Opportunities'),
                  if (opps.isEmpty)
                    _muted(context, 'No new opportunities detected today.')
                  else
                    ...opps.take(3).map((a) => _AlertCard(alert: a)),
                  const SizedBox(height: 24),
                  _recommendation(context, ai, state.brief),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthHero(BuildContext context, ExecutiveBrief? brief) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const BriefScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandDeep, AppColors.brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (brief != null)
              ScoreRing(score: brief.score, size: 76, light: true)
            else
              const SizedBox(
                width: 76,
                height: 76,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BUSINESS HEALTH',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 2),
                  Text(brief?.scoreLabel ?? 'Analyzing…',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    brief?.headline.isNotEmpty == true
                        ? brief!.headline
                        : 'Your focus, risks and opportunities — one tap.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _stats(BuildContext context, AppState state) {
    final due = state.customers.where((c) => c.isReorderDue).length;
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '${state.overdueTasks.length}',
            label: 'Overdue tasks',
            icon: Icons.pending_actions_outlined,
            accent: const Color(0xFFE5484D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            value: '${state.unreadEmails}',
            label: 'Unread emails',
            icon: Icons.mark_email_unread_outlined,
            accent: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            value: '$due',
            label: 'Follow-ups due',
            icon: Icons.autorenew_outlined,
            accent: const Color(0xFF30A46C),
          ),
        ),
      ],
    );
  }

  Widget _recommendation(
      BuildContext context, AiEngine ai, ExecutiveBrief? brief) {
    final text = (brief != null && brief.recommendation.isNotEmpty)
        ? brief.recommendation
        : ai.recommendation();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.brand, size: 18),
              SizedBox(width: 8),
              Text('AI recommendation',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(height: 1.4, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _muted(BuildContext context, String text) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      );
}

class _AlertsBell extends StatelessWidget {
  const _AlertsBell();

  @override
  Widget build(BuildContext context) {
    final count = context.select<AppState, int>(executiveAlertCount);
    return IconButton(
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
      icon: count > 0
          ? Badge(
              label: Text('$count'),
              child: const Icon(Icons.notifications_none),
            )
          : const Icon(Icons.notifications_none),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.brand, AppColors.accent]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.hub, color: Colors.white, size: 22),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final Task task;
  const _PriorityRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HomeNavigation.of(context)?.goToTab(3);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => state.toggleTask(task),
                  child: Icon(
                    task.isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.isDone
                        ? AppColors.brand
                        : task.priority.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          PriorityChip(task.priority, dense: true),
                          const SizedBox(width: 8),
                          if (task.due != null)
                            Text(
                              task.isOverdue
                                  ? 'Overdue'
                                  : _dueLabel(task.due!),
                              style: TextStyle(
                                fontSize: 11,
                                color: task.isOverdue
                                    ? const Color(0xFFE5484D)
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dueLabel(DateTime due) {
    final days = due.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }
}

class _AlertCard extends StatelessWidget {
  final BusinessAlert alert;
  const _AlertCard({required this.alert});

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
                  color: alert.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(alert.icon, color: alert.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(alert.detail,
                        style: Theme.of(context).textTheme.bodySmall,
                        // allow multi-line reasoning
                        ),
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

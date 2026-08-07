import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/work.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final events = state.eventsOn(_selected);
    final tasks = state.tasksDueOn(_selected);
    final today = DateTime.now();
    final days = List.generate(
        14, (i) => DateTime(today.year, today.month, today.day + i));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final d = days[i];
                final selected = d.day == _selected.day &&
                    d.month == _selected.month &&
                    d.year == _selected.year;
                final hasItems = state.eventsOn(d).isNotEmpty ||
                    state.tasksDueOn(d).isNotEmpty;
                return GestureDetector(
                  onTap: () => setState(() => _selected = d),
                  child: Container(
                    width: 54,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brand
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? AppColors.brand
                              : Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(d),
                            style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? Colors.white70
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color)),
                        const SizedBox(height: 4),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : null)),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasItems
                                ? (selected
                                    ? Colors.white
                                    : AppColors.brand)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: (events.isEmpty && tasks.isEmpty)
                ? const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'Nothing scheduled',
                    subtitle: 'No meetings or deadlines on this day.')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: [
                      Text(DateFormat('EEEE, MMMM d').format(_selected),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      if (events.isNotEmpty) ...[
                        const SectionHeader('Schedule'),
                        ...events.map((e) => _EventTile(event: e)),
                        const SizedBox(height: 16),
                      ],
                      if (tasks.isNotEmpty) ...[
                        const SectionHeader('Due'),
                        ...tasks.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  leading: Icon(Icons.flag_outlined,
                                      color: t.priority.color),
                                  title: Text(t.title),
                                  subtitle: Text('${t.priority.label} priority'),
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  const _EventTile({required this.event});

  IconData get _icon {
    switch (event.kind) {
      case 'Renewal':
        return Icons.event_repeat_outlined;
      case 'Deadline':
        return Icons.timer_outlined;
      case 'Follow-up':
        return Icons.call_outlined;
      default:
        return Icons.groups_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: AppColors.brand, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormat('h:mm a').format(event.start)} · ${event.kind}',
                      style: Theme.of(context).textTheme.bodySmall,
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../models/enums.dart';
import '../../services/ai_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _ai = AiService();
  String? _narrative;
  bool _loading = false;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _narrative = null;
    });
    try {
      final r = await _ai.chat(
        message:
            'Based on my business timeline and current data, summarise how the '
            'business has evolved. Give 3–4 short, specific insights about trends, '
            'shifts and momentum (e.g. "supplier meetings doubled", "a project '
            'slipped"). Be concrete; no preamble.',
        history: const [],
      );
      if (mounted) setState(() => _narrative = r.text);
    } catch (_) {
      if (mounted) {
        setState(() => _narrative =
            'AI is unavailable right now. Deploy the ai function or try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppState>().timeline.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Business Timeline')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _aiCard(context),
          const SizedBox(height: 20),
          for (int i = 0; i < events.length; i++)
            _EventRow(event: events[i], isLast: i == events.length - 1),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No timeline events yet.',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }

  Widget _aiCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.brand),
              SizedBox(width: 6),
              Text('Timeline intelligence',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text('Reading your history…',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )
          else if (_narrative != null)
            Text(_narrative!, style: const TextStyle(height: 1.45))
          else
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Summarise what changed'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;
  const _EventRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final e = event;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(e.kind.icon, color: AppColors.brand, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM d, y').format(e.date),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.brand)),
                  const SizedBox(height: 4),
                  Text(e.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(e.detail, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(e.kind.label,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

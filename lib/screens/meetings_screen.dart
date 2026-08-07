import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/work.dart';
import '../services/ai_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meetings = context.watch<AppState>().meetings.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _capture(context),
        icon: const Icon(Icons.mic_none),
        label: const Text('Capture'),
      ),
      body: meetings.isEmpty
          ? const EmptyState(
              icon: Icons.record_voice_over_outlined,
              title: 'No meetings yet',
              subtitle: 'Capture a meeting to generate a summary and tasks.')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: meetings.length,
              itemBuilder: (_, i) => _MeetingCard(meeting: meetings[i]),
            ),
    );
  }

  void _capture(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CaptureSheet(),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final m = meeting;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(m.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Text(DateFormat('MMM d').format(m.date),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              Text('Attendees: ${m.attendees.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: const [
                      Icon(Icons.auto_awesome,
                          size: 13, color: AppColors.brand),
                      SizedBox(width: 5),
                      Text('AI summary',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand)),
                    ]),
                    const SizedBox(height: 6),
                    Text(m.summary,
                        style: const TextStyle(height: 1.35, fontSize: 13)),
                  ],
                ),
              ),
              if (m.decisions.isNotEmpty) ...[
                const SizedBox(height: 14),
                const _MiniHeader('Decisions', Icons.gavel_outlined),
                ...m.decisions.map((d) => _bullet(context, d)),
              ],
              if (m.actionItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _MiniHeader('Action items', Icons.task_alt),
                ...m.actionItems.map((a) => InkWell(
                      onTap: () => state.toggleActionItem(a),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                                a.done
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 18,
                                color: a.done
                                    ? AppColors.brand
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(a.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    decoration: a.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 12),
              if (!m.processed)
                FilledButton.tonalIcon(
                  onPressed: () {
                    state.processMeeting(m);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Open action items converted to tasks.')));
                  },
                  icon: const Icon(Icons.playlist_add_check, size: 18),
                  label: const Text('Convert actions to tasks'),
                )
              else
                Row(children: const [
                  Icon(Icons.check_circle,
                      size: 16, color: Color(0xFF30A46C)),
                  SizedBox(width: 6),
                  Text('Processed into tasks',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF30A46C),
                          fontWeight: FontWeight.w600)),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 8),
              child: Icon(Icons.circle, size: 5, color: AppColors.brand),
            ),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _MiniHeader extends StatelessWidget {
  final String text;
  final IconData icon;
  const _MiniHeader(this.text, this.icon);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(text.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.brand)),
          ],
        ),
      );
}

/// Paste a transcript / type notes → AI summarises + extracts decisions & tasks.
class _CaptureSheet extends StatefulWidget {
  const _CaptureSheet();
  @override
  State<_CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<_CaptureSheet> {
  final _text = TextEditingController();
  final _ai = AiService();
  bool _processing = false;
  ParsedMeeting? _result;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    setState(() => _processing = true);
    final state = context.read<AppState>();
    try {
      final r = await _ai.meeting(t);
      state.addMeeting(Meeting(
        id: state.newId('mt'),
        title: r.title,
        date: DateTime.now(),
        attendees: const ['You'],
        summary: r.summary,
        decisions: r.decisions,
        actionItems: r.actions.map((a) => ActionItem(a)).toList(),
      ));
      if (mounted) setState(() => _result = r);
    } catch (_) {
      // Offline fallback — keep the notes so nothing is lost.
      state.addMeeting(Meeting(
        id: state.newId('mt'),
        title: 'Captured meeting',
        date: DateTime.now(),
        attendees: const ['You'],
        summary: t,
        decisions: const [],
        actionItems: const [],
      ));
      if (mounted) {
        setState(() => _result = const ParsedMeeting(
              title: 'Captured meeting',
              summary: 'Saved your notes. AI processing was unavailable — '
                  'deploy the ai function to auto-summarise.',
              decisions: [],
              actions: [],
            ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _result != null ? _success(context) : _input(context),
    );
  }

  Widget _input(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Capture meeting',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Paste a transcript or type your notes — Cereont will summarise it '
          'and pull out decisions and action items.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Paste transcript or notes…',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _processing ? null : _process,
          icon: _processing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome),
          label: Text(_processing ? 'Processing…' : 'Generate summary & tasks'),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ],
    );
  }

  Widget _success(BuildContext context) {
    final r = _result!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.check_circle, size: 54, color: Color(0xFF30A46C)),
        const SizedBox(height: 12),
        Text(r.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          '${r.decisions.length} decision(s) · ${r.actions.length} action item(s) captured.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(r.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4)),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Text('Done'),
            ),
          ),
        ),
      ],
    );
  }
}

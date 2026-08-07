import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Shows meetings, timeline events and notes that mention [name] — the
/// "everything related to X" view for a customer or supplier.
class RelatedActivity extends StatelessWidget {
  final String name;
  const RelatedActivity({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final meetings = state.meetingsMentioning(name);
    final timeline = state.timelineMentioning(name);
    final notes = state.notesMentioning(name);

    if (meetings.isEmpty && timeline.isEmpty && notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meetings.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader('Related meetings'),
          ...meetings.map((m) => _tile(
                context,
                icon: Icons.record_voice_over_outlined,
                title: m.title,
                subtitle:
                    '${DateFormat('MMM d').format(m.date)} · ${m.summary}',
              )),
        ],
        if (timeline.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader('On the timeline'),
          ...timeline.map((e) => _tile(
                context,
                icon: e.kind.icon,
                title: e.title,
                subtitle:
                    '${DateFormat('MMM d, y').format(e.date)} · ${e.detail}',
              )),
        ],
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionHeader('Related notes'),
          ...notes.map((n) => _tile(
                context,
                icon: Icons.sticky_note_2_outlined,
                title: n.title,
                subtitle: n.body,
              )),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brand),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

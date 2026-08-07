import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../services/ai_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'memory/customers_screen.dart';
import 'memory/suppliers_screen.dart';

class _Result {
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final VoidCallback? onTap;
  _Result(this.title, this.subtitle, this.icon, this.category, {this.onTap});
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _ai = AiService();
  String _query = '';
  String _aiAnswerFor = '';
  String? _aiAnswer;
  bool _aiLoading = false;

  Future<void> _askAi() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    setState(() {
      _aiLoading = true;
      _aiAnswer = null;
      _aiAnswerFor = q;
    });
    try {
      final r = await _ai.chat(message: q, history: const []);
      if (mounted) setState(() => _aiAnswer = r.text);
    } catch (_) {
      if (mounted) {
        setState(() => _aiAnswer =
            'AI is unavailable right now. Deploy the ai function or try again.');
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  List<_Result> _search(AppState s, BuildContext context) {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final r = <_Result>[];

    bool m(String? text) => text != null && text.toLowerCase().contains(q);

    for (final c in s.customers) {
      if (m(c.name) || m(c.segment) || m(c.notes) || m(c.contact.name)) {
        r.add(_Result(c.name, '${c.segment} · Customer', Icons.person_outline,
            'Customers', onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: c)));
        }));
      }
    }
    for (final sup in s.suppliers) {
      if (m(sup.name) ||
          m(sup.notes) ||
          sup.productsSupplied.any((p) => p.toLowerCase().contains(q))) {
        r.add(_Result(sup.name, 'Supplier', Icons.local_shipping_outlined,
            'Suppliers', onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SupplierDetailScreen(supplier: sup)));
        }));
      }
    }
    for (final p in s.products) {
      if (m(p.name) || m(p.category)) {
        r.add(_Result(p.name, '${p.category} · Product',
            Icons.inventory_2_outlined, 'Products'));
      }
    }
    for (final p in s.projects) {
      if (m(p.name) || m(p.notes) || m(p.status)) {
        r.add(_Result(p.name, '${p.status} · Project',
            Icons.folder_outlined, 'Projects'));
      }
    }
    for (final t in s.tasks) {
      if (m(t.title) || m(t.notes)) {
        r.add(_Result(t.title, '${t.priority.label} · Task',
            Icons.check_circle_outline, 'Tasks'));
      }
    }
    for (final e in s.emails) {
      if (m(e.subject) || m(e.body) || m(e.from) || m(e.aiSummary)) {
        r.add(_Result(e.subject, '${e.from} · Email', e.kind.icon, 'Emails'));
      }
    }
    for (final mt in s.meetings) {
      if (m(mt.title) || m(mt.summary)) {
        r.add(_Result(mt.title, 'Meeting',
            Icons.record_voice_over_outlined, 'Meetings'));
      }
    }
    for (final n in s.notes) {
      if (m(n.title) || m(n.body)) {
        r.add(_Result(n.title, 'Note', Icons.sticky_note_2_outlined, 'Notes'));
      }
    }
    for (final tl in s.timeline) {
      if (m(tl.title) || m(tl.detail)) {
        r.add(_Result(tl.title, 'Timeline event', tl.kind.icon, 'Timeline'));
      }
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = _search(state, context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search customers, emails, tasks…',
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.trim().isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: 'Search everything',
              subtitle:
                  'Customers, suppliers, products, projects, tasks, emails, meetings, notes and timeline — or ask a question.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                _aiCard(context),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No direct matches for "$_query".',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  )
                else
                  ...results.map(_resultTile),
              ],
            ),
    );
  }

  Widget _aiCard(BuildContext context) {
    final q = _query.trim();
    final answered = _aiAnswer != null && _aiAnswerFor == q;
    final loading = _aiLoading && _aiAnswerFor == q;
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text('Ask Cereont',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.brand)),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text('Thinking…',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )
          else if (answered)
            Text(_aiAnswer!, style: const TextStyle(height: 1.4))
          else
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _askAi,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  q.length > 40 ? 'Ask about “${q.substring(0, 40)}…”' : 'Ask: “$q”',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultTile(_Result res) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(res.icon, color: AppColors.brand, size: 18),
          ),
          title: Text(res.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(res.subtitle),
          trailing:
              res.onTap != null ? const Icon(Icons.chevron_right) : null,
          onTap: res.onTap,
        ),
      ),
    );
  }
}

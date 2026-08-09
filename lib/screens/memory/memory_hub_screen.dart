import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../calendar_screen.dart';
import '../meetings_screen.dart';
import 'company_profile_screen.dart';
import 'customers_screen.dart';
import 'products_screen.dart';
import 'projects_screen.dart';
import 'suppliers_screen.dart';
import 'timeline_screen.dart';

class MemoryHubScreen extends StatelessWidget {
  const MemoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ai = state.ai;

    final tiles = <_HubTile>[
      _HubTile('Customers', Icons.people_alt_outlined, '${state.customers.length}',
          const Color(0xFF2563EB), const CustomersScreen()),
      _HubTile('Suppliers', Icons.local_shipping_outlined,
          '${state.suppliers.length}', const Color(0xFF38BDF8),
          const SuppliersScreen()),
      _HubTile('Products', Icons.inventory_2_outlined,
          '${state.products.length}', const Color(0xFFF59E0B),
          const ProductsScreen()),
      _HubTile('Projects', Icons.folder_special_outlined,
          '${state.projects.length}', const Color(0xFF22C55E),
          const ProjectsScreen()),
      _HubTile('Meetings', Icons.record_voice_over_outlined,
          '${state.meetings.length}', const Color(0xFFEF4444),
          const MeetingsScreen()),
      _HubTile('Calendar', Icons.calendar_month_outlined,
          '${state.todaysEvents.length}', const Color(0xFF8B5CF6),
          const CalendarScreen()),
      _HubTile('Timeline', Icons.history_outlined,
          '${state.timeline.length}', const Color(0xFF0EA5E9),
          const TimelineScreen()),
      _HubTile('Company', Icons.business_outlined, '',
          const Color(0xFF94A3B8), const CompanyProfileScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Business Memory')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          // Company card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CompanyProfileScreen())),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.brand, AppColors.accent]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.hub,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.company.name,
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(state.company.industry,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Explore'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: tiles.map((t) => _HubCard(tile: t)).toList(),
          ),
          const SizedBox(height: 20),
          const SectionHeader('AI snapshot'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
            ),
            child: Text(ai.answer('summarize my business performance'),
                style: const TextStyle(height: 1.4)),
          ),
          const SizedBox(height: 12),
          Text(
            'Last synced ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HubTile {
  final String label;
  final IconData icon;
  final String value;
  final Color color;
  final Widget screen;
  _HubTile(this.label, this.icon, this.value, this.color, this.screen);
}

class _HubCard extends StatelessWidget {
  final _HubTile tile;
  const _HubCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => tile.screen)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tile.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(tile.icon, color: tile.color, size: 20),
                  ),
                  const Spacer(),
                  if (tile.value.isNotEmpty)
                    Text(tile.value,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const Spacer(),
              Text(tile.label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

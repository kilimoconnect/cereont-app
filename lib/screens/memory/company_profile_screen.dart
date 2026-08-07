import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final company = context.watch<AppState>().company;

    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.brand, AppColors.accent]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.hub, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 12),
                Text(company.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(company.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Overview'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _kv(context, 'Industry', company.industry),
                  _kv(context, 'Currency', company.currency),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _chipsSection(context, 'Products & Services',
              company.productsServices, Icons.sell_outlined),
          const SizedBox(height: 20),
          _chipsSection(
              context, 'Departments', company.departments, Icons.apartment),
          const SizedBox(height: 20),
          const SectionHeader('Business goals'),
          ...company.goals.map((g) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading:
                      const Icon(Icons.flag_outlined, color: AppColors.brand),
                  title: Text(g),
                ),
              )),
        ],
      ),
    );
  }

  Widget _chipsSection(
      BuildContext context, String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) => Pill(e, icon: icon)).toList(),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
                width: 100,
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600))),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

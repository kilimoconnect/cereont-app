import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'entity_forms.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppState>().products;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ProductEditScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              subtitle: 'Add products to track pricing and margins.')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p = products[i];
          final marginPct = (p.margin * 100).round();
          final good = p.margin >= 0.3;
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
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.brand),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(
                            '${p.category} · ${_money.format(p.price)} / ${p.unit} · cost ${_money.format(p.cost)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$marginPct%',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: good
                                    ? const Color(0xFF30A46C)
                                    : const Color(0xFFF5A524))),
                        Text('margin',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

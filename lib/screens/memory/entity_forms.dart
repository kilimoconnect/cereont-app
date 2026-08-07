import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../state/app_state.dart';

List<String> _csv(String v) => v
    .split(',')
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

double _num(String v) => double.tryParse(v.trim()) ?? 0;
int _int(String v) => int.tryParse(v.trim()) ?? 0;

/// Shared scaffold for the simple "add" forms.
class _FormScaffold extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;
  const _FormScaffold(
      {required this.title, required this.fields, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          ...fields,
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(onPressed: onSave, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

Widget _field(TextEditingController c, String label,
    {TextInputType? keyboard, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      textCapitalization: keyboard == null
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

// --------------------------------------------------------------------------
class CustomerEditScreen extends StatefulWidget {
  const CustomerEditScreen({super.key});
  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _name = TextEditingController();
  final _segment = TextEditingController();
  final _cName = TextEditingController();
  final _cRole = TextEditingController();
  final _cEmail = TextEditingController();
  final _cPhone = TextEditingController();
  final _ltv = TextEditingController();
  final _cycle = TextEditingController(text: '30');
  final _notes = TextEditingController();

  void _save() {
    if (_name.text.trim().isEmpty) return _warn(context);
    final state = context.read<AppState>();
    state.addCustomer(Customer(
      id: state.newId('c'),
      name: _name.text.trim(),
      segment: _segment.text.trim(),
      contact: Contact(
        name: _cName.text.trim(),
        role: _cRole.text.trim(),
        email: _cEmail.text.trim(),
        phone: _cPhone.text.trim(),
      ),
      lifetimeValue: _num(_ltv.text),
      reorderCycleDays: _int(_cycle.text) == 0 ? 30 : _int(_cycle.text),
      lastOrder: DateTime.now(),
      notes: _notes.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _FormScaffold(
        title: 'New customer',
        onSave: _save,
        fields: [
          _field(_name, 'Name'),
          _field(_segment, 'Segment (e.g. Wholesaler)'),
          _field(_cName, 'Contact name'),
          _field(_cRole, 'Contact role'),
          _field(_cEmail, 'Contact email', keyboard: TextInputType.emailAddress),
          _field(_cPhone, 'Contact phone', keyboard: TextInputType.phone),
          _field(_ltv, 'Lifetime value', keyboard: TextInputType.number),
          _field(_cycle, 'Reorder cycle (days)', keyboard: TextInputType.number),
          _field(_notes, 'Notes', maxLines: 3),
        ],
      );
}

// --------------------------------------------------------------------------
class SupplierEditScreen extends StatefulWidget {
  const SupplierEditScreen({super.key});
  @override
  State<SupplierEditScreen> createState() => _SupplierEditScreenState();
}

class _SupplierEditScreenState extends State<SupplierEditScreen> {
  final _name = TextEditingController();
  final _products = TextEditingController();
  final _terms = TextEditingController();
  final _onTime = TextEditingController(text: '90');
  final _lead = TextEditingController(text: '30');
  final _cName = TextEditingController();
  final _cEmail = TextEditingController();
  final _notes = TextEditingController();

  void _save() {
    if (_name.text.trim().isEmpty) return _warn(context);
    final state = context.read<AppState>();
    final pct = _num(_onTime.text).clamp(0, 100) / 100.0;
    state.addSupplier(Supplier(
      id: state.newId('s'),
      name: _name.text.trim(),
      productsSupplied: _csv(_products.text),
      contact: Contact(name: _cName.text.trim(), role: '', email: _cEmail.text.trim()),
      paymentTerms: _terms.text.trim(),
      onTimeRate: pct,
      leadTimeDays: _int(_lead.text),
      notes: _notes.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _FormScaffold(
        title: 'New supplier',
        onSave: _save,
        fields: [
          _field(_name, 'Name'),
          _field(_products, 'Products supplied (comma-separated)'),
          _field(_terms, 'Payment terms (e.g. Net 30)'),
          _field(_onTime, 'On-time rate (%)', keyboard: TextInputType.number),
          _field(_lead, 'Lead time (days)', keyboard: TextInputType.number),
          _field(_cName, 'Contact name'),
          _field(_cEmail, 'Contact email', keyboard: TextInputType.emailAddress),
          _field(_notes, 'Notes', maxLines: 3),
        ],
      );
}

// --------------------------------------------------------------------------
class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({super.key});
  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _cost = TextEditingController();
  final _unit = TextEditingController(text: 'unit');

  void _save() {
    if (_name.text.trim().isEmpty) return _warn(context);
    final state = context.read<AppState>();
    state.addProduct(Product(
      id: state.newId('p'),
      name: _name.text.trim(),
      category: _category.text.trim(),
      price: _num(_price.text),
      cost: _num(_cost.text),
      unit: _unit.text.trim().isEmpty ? 'unit' : _unit.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _FormScaffold(
        title: 'New product',
        onSave: _save,
        fields: [
          _field(_name, 'Name'),
          _field(_category, 'Category'),
          _field(_price, 'Price', keyboard: TextInputType.number),
          _field(_cost, 'Cost', keyboard: TextInputType.number),
          _field(_unit, 'Unit (e.g. bag, kg)'),
        ],
      );
}

// --------------------------------------------------------------------------
class ProjectEditScreen extends StatefulWidget {
  const ProjectEditScreen({super.key});
  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _team = TextEditingController();
  String _status = 'Planning';
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  double _progress = 0;

  void _save() {
    if (_name.text.trim().isEmpty) return _warn(context);
    final state = context.read<AppState>();
    state.addProject(Project(
      id: state.newId('pr'),
      name: _name.text.trim(),
      status: _status,
      deadline: _deadline,
      progress: _progress,
      team: _csv(_team.text),
      notes: _notes.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _FormScaffold(
        title: 'New project',
        onSave: _save,
        fields: [
          _field(_name, 'Name'),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 8,
              children: ['Planning', 'On track', 'At risk']
                  .map((s) => ChoiceChip(
                        label: Text(s),
                        selected: _status == s,
                        onSelected: (_) => setState(() => _status = s),
                      ))
                  .toList(),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text('Deadline: ${_deadline.toString().split(' ').first}'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deadline,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 1095)),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text('Progress'),
                Expanded(
                  child: Slider(
                    value: _progress,
                    onChanged: (v) => setState(() => _progress = v),
                  ),
                ),
                Text('${(_progress * 100).round()}%'),
              ],
            ),
          ),
          _field(_team, 'Team (comma-separated)'),
          _field(_notes, 'Notes', maxLines: 3),
        ],
      );
}

void _warn(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Give it a name first.')));
}

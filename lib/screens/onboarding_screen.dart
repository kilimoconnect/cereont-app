import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// First-run screen: the signed-in user sets up their company workspace.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _industry = TextEditingController();
  final _tagline = TextEditingController();
  String _currency = r'$';
  bool _saving = false;
  String? _error;

  static const _currencies = [r'$', '€', '£', '₦', 'KSh', '₹', 'R', 'د.إ'];

  @override
  void dispose() {
    _name.dispose();
    _industry.dispose();
    _tagline.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AppState>().createCompany(Company(
            name: _name.text.trim(),
            industry: _industry.text.trim(),
            tagline: _tagline.text.trim(),
            productsServices: const [],
            departments: const [],
            goals: const [],
            currency: _currency,
          ));
    } catch (e) {
      setState(() => _error = 'Could not create your company. $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => AuthService.instance.signOut(),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Sign out'),
                      style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.brand, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.hub, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Set up your workspace',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Tell Cereont about your business so it can start working '
                    'as your chief of staff.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        height: 1.4),
                  ),
                  const SizedBox(height: 28),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Field(
                            label: 'Company name',
                            hint: 'Acme Trading Co.',
                            controller: _name,
                            icon: Icons.apartment_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your company name'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          _Field(
                            label: 'Industry',
                            hint: 'Import & distribution',
                            controller: _industry,
                            icon: Icons.workspaces_outline,
                          ),
                          const SizedBox(height: 18),
                          _Field(
                            label: 'What does your business do?',
                            hint: 'Sourcing quality goods across markets',
                            controller: _tagline,
                            icon: Icons.description_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 18),
                          Text('CURRENCY',
                              style: _labelStyle(context)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _currencies
                                .map((c) => ChoiceChip(
                                      label: Text(c),
                                      selected: _currency == c,
                                      onSelected: (_) =>
                                          setState(() => _currency = c),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5484D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFFE5484D).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFE5484D), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _saving ? null : _create,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Create workspace',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('You can refine all of this later in Settings.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _labelStyle(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).textTheme.bodySmall?.color,
      );
}

/// A labeled text field with an icon — consistent, professional styling.
class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.sentences,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).textTheme.bodySmall?.color,
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

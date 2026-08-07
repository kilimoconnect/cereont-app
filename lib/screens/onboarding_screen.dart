import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../screens/auth/auth_common.dart';

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
  final _currency = TextEditingController(text: '\$');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _industry.dispose();
    _tagline.dispose();
    _currency.dispose();
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
            currency: _currency.text.trim().isEmpty
                ? '\$'
                : _currency.text.trim(),
          ));
      // WorkspaceLoader rebuilds into the app once the company exists.
    } catch (e) {
      setState(() => _error = 'Could not create your company. $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const AuthHeader(
                    title: 'Set up your workspace',
                    subtitle:
                        'Tell Cereont about your business so it can start '
                        'working as your chief of staff.',
                  ),
                  const SizedBox(height: 30),
                  if (_error != null) AuthErrorBanner(_error!),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Company name',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your company name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _industry,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Industry',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _tagline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'What does your business do?',
                            prefixIcon: Icon(Icons.short_text),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Currency symbol',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
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
                          : const Text('Create workspace',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

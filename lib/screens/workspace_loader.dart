import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

/// Shown once a user is signed in. Bootstraps their company data from Supabase
/// and routes to onboarding (no company yet) or the app.
class WorkspaceLoader extends StatefulWidget {
  const WorkspaceLoader({super.key});

  @override
  State<WorkspaceLoader> createState() => _WorkspaceLoaderState();
}

class _WorkspaceLoaderState extends State<WorkspaceLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading) return const _Splash(message: 'Loading your workspace…');

    if (state.loadError != null) {
      return _ErrorView(
        error: state.loadError!,
        onRetry: () => context.read<AppState>().bootstrap(),
      );
    }

    if (!state.hasCompany) return const OnboardingScreen();

    return const HomeShell();
  }
}

class _Splash extends StatelessWidget {
  final String message;
  const _Splash({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.accent]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.hub, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final schemaMissing = error.contains('does not exist') ||
        error.contains('PGRST') ||
        error.contains('42P01') ||
        error.contains('404');
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 46, color: Color(0xFFE5484D)),
              const SizedBox(height: 14),
              Text(
                schemaMissing
                    ? "Couldn't reach your tables"
                    : "Couldn't load your workspace",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                schemaMissing
                    ? 'Run supabase/schema.sql in your Supabase SQL editor, then retry.'
                    : error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

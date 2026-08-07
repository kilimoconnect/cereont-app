import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import '../workspace_loader.dart';
import 'auth_common.dart';
import 'signin_screen.dart';

/// Decides what the app shows based on auth state:
/// - Supabase not configured  → setup instructions
/// - no session               → sign-in screen
/// - signed in                → the app
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) return const SupabaseSetupScreen();

    return StreamBuilder<AuthState>(
      stream: AuthService.instance.onAuthStateChange,
      builder: (context, snapshot) {
        // currentSession is the source of truth; the stream just triggers rebuilds.
        final signedIn = AuthService.instance.isSignedIn;
        return signedIn ? const WorkspaceLoader() : const SignInScreen();
      },
    );
  }
}

/// Shown when the app is launched without Supabase credentials.
class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const AuthHeader(
                    title: 'Connect Supabase',
                    subtitle:
                        'Add your Supabase project credentials to enable sign in.',
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _Step(
                            n: '1',
                            text:
                                'Open lib/config/supabase_config.dart and paste your Project URL and anon key (Supabase → Project Settings → API).',
                          ),
                          _Step(
                            n: '2',
                            text:
                                'In Supabase → Authentication → Providers → Email, turn OFF "Confirm email".',
                          ),
                          _Step(
                            n: '3',
                            text:
                                'In Authentication → Providers → Google, enable it and paste your Google OAuth client ID and secret.',
                          ),
                          _Step(
                            n: '4',
                            text: 'Restart the app.',
                            last: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tip: you can also pass credentials with\n'
                    '--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _Step extends StatelessWidget {
  final String n;
  final String text;
  final bool last;
  const _Step({required this.n, required this.text, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(n,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: const TextStyle(height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}

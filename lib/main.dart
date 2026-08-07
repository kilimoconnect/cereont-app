import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Supabase when real credentials are present so the app can
  // still launch (into a setup screen) before it is configured.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // A legacy "anon" key or a newer "publishable" key both work here.
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const CereontApp());
}

class CereontApp extends StatelessWidget {
  const CereontApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Cereont',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const AuthGate(),
      ),
    );
  }
}

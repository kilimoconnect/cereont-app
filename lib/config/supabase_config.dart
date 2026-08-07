/// Supabase connection settings.
///
/// Fill in the two values below with your project's credentials from
/// Supabase → Project Settings → API. The `anonKey` is a *public* client key
/// and is safe to ship in a client app.
///
/// You can also leave these as-is and pass them at build/run time instead:
///
///   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
///
class SupabaseConfig {
  /// Your project URL, e.g. https://abcdefgh.supabase.co
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ckrmgjxoxscdcprakbzc.supabase.co',
  );

  /// Your project's public anon key.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrcm1nanhveHNjZGNwcmFrYnpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYwMjU5MjQsImV4cCI6MjEwMTYwMTkyNH0.Plw1PgD8lwUrAVx38mVB6KiHRMbKf4ILbQOjPQ7g5_g',
  );

  /// Deep-link that Google OAuth redirects back to on mobile/desktop.
  /// Must be registered in Supabase → Authentication → URL Configuration →
  /// Redirect URLs, and in the native platform config (already added to the
  /// Android manifest and iOS Info.plist).
  static const String oauthCallback = 'io.supabase.cereont://login-callback/';

  /// True once real credentials have been provided.
  static bool get isConfigured =>
      !url.contains('YOUR-PROJECT-REF') &&
      anonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      url.isNotEmpty &&
      anonKey.isNotEmpty;
}

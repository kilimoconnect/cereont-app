import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thin wrapper around Supabase auth so the UI never touches the SDK directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  GoTrueClient get _auth => _client.auth;

  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentSession != null;

  /// Emits on every sign-in / sign-out / token refresh.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Sign up with email + password. With email confirmation disabled in the
  /// Supabase dashboard, this returns an active session immediately.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _auth.signUp(
      email: email.trim(),
      password: password,
      // Where the email-confirmation link returns the user. On web this
      // defaults to the project's Site URL; on mobile/desktop it deep-links
      // back into the app.
      emailRedirectTo: kIsWeb ? null : SupabaseConfig.oauthCallback,
      data: fullName == null || fullName.trim().isEmpty
          ? null
          : {'full_name': fullName.trim()},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Google sign-in via OAuth. On web this performs a same-tab redirect; on
  /// mobile/desktop it opens an external browser and returns via the deep link.
  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : SupabaseConfig.oauthCallback,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  /// Google's OAuth access token for the current session (used to call Gmail).
  /// Present after signing in / connecting with a Google scope.
  String? get providerToken => currentSession?.providerToken;

  /// Re-authorizes with Google including the Gmail read-only scope so the app
  /// can sync the inbox. On web this is a same-tab redirect; on mobile it opens
  /// an external browser and returns via the deep link.
  Future<bool> connectGmail() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      scopes: 'https://www.googleapis.com/auth/gmail.readonly',
      redirectTo: kIsWeb ? null : SupabaseConfig.oauthCallback,
      queryParams: const {'access_type': 'offline', 'prompt': 'consent'},
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// A friendly display name for the signed-in user.
  String get displayName {
    final u = currentUser;
    if (u == null) return 'Guest';
    final name = u.userMetadata?['full_name'] ?? u.userMetadata?['name'];
    if (name is String && name.trim().isNotEmpty) return name;
    return u.email ?? 'Signed in';
  }
}

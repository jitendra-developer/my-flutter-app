import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleESign {
  final supabase = Supabase.instance.client;

  Future<void> signInWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.inAppWebView,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
    } catch (e) {
      // This will catch any errors during the launch of the webview.
      // The actual sign-in errors will be handled by the auth stream listener.
      debugPrint('Error launching Google Sign-In: $e');
    }
  }
}

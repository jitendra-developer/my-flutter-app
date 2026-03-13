import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/services/api_service.dart';

class GoogleESign {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional: add scopes here if needed later (e.g., 'email', 'profile')
  );

  GoogleESign();

  Future<void> signInWithGoogle() async {
    developer.log('Starting Google Sign-In flow');
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        developer.log('User canceled Google Sign-In');
        throw Exception('Sign-In canceled by user.');
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to retrieve ID token from Google.');
      }

      developer.log('Successfully retrieved Google ID token');

      // 3. Send the ID token to our Laravel backend via ApiService
      final apiService = ApiService();
      await apiService.loginWithGoogle(idToken);
      
      developer.log('Successfully authenticated with backend via Google');

    } catch (e) {
      developer.log('Google Sign-In Error: $e', error: e);
      // Ensure we clean up native state on error
      await signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      developer.log('Error signing out from Google: $e', error: e);
    }
  }
}

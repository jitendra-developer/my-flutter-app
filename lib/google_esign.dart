import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class GoogleESign {
  GoogleESign();

  Future<void> signInWithGoogle() async {
    developer.log('Google Sign-In is temporarily disabled.');
    throw Exception('Google Sign-In is not currently available via the new API.');
  }

  Future<void> signOut() async {
    //
  }
}

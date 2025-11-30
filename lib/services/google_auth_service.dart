import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import '../services/db_service.dart';

class GoogleAuthService {
  /// ⚠️ IMPORTANT: Replace this with your actual Web Client ID from Google Cloud Console.
  /// Even for Android/iOS apps, Supabase requires the *Web* Client ID to verify the token.
  static const String _webClientId = '488626880312-lvas0u2e4d8e3v116shbv5vkgmq53bh5.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId, // Required for Supabase to verify the ID token
    scopes: ['email', 'profile'],
  );

  // Access Supabase Client
  final supabase = Supabase.instance.client;

  Future<AuthResponse?> signInWithGoogle(BuildContext context) async {
    try {
      // 1. Trigger the native Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // User canceled the login
      if (googleUser == null) return null;

      // 2. Obtain the auth details (Access Token & ID Token)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found. Please check your Web Client ID configuration.';
      }

      // 3. Sign in to Supabase using the ID Token
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 4. Save to SQLite (Your existing logic)
      // Note: Supabase user data is now in 'response.user'
      await DBService().saveUserData(
        email: googleUser.email,
        name: googleUser.displayName ?? "Google User",
        provider: 'google',
      );

      dev.log("✅ Google login success: ${googleUser.email}", name: 'GoogleAuth');
      return response;

    } catch (e) {
      dev.log("❌ Google login error: $e", name: 'GoogleAuth');
      
      // Show error to user (optional)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login Failed: $e')),
        );
      }
      return null;
    }
  }

  Future<void> signOut() async {
    // 1. Sign out from Supabase
    await supabase.auth.signOut();
    
    // 2. Sign out from Google (so account chooser appears next time)
    await _googleSignIn.signOut();
    
    // 3. Clear SQLite
    await DBService().clearUserData();
    
    dev.log("✅ Signed out from Google & Supabase", name: 'GoogleAuth');
  }
}
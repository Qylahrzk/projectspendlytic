import 'dart:developer' as dev;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:projectspendlytic/services/db_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Attempts Google Sign-In.
  /// Returns the GoogleSignInAccount on success, or null if cancelled/fails.
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        dev.log("❌ Google Sign-In cancelled", name: 'GoogleAuthService');
        return null;
      }

      dev.log("✅ Google Sign-In success: ${account.email}", name: 'GoogleAuthService');
      return account;
    } catch (e) {
      dev.log("❌ Google Sign-In error: $e", name: 'GoogleAuthService');
      return null;
    }
  }

  /// Signs out the Google user and clears local DB data.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await DBService().clearUserData();
      dev.log("✅ Local Google user signed out", name: 'GoogleAuthService');
    } catch (e) {
      dev.log("❌ Google sign-out error: $e", name: 'GoogleAuthService');
    }
  }
}

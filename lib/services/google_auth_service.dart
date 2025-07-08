import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/db_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<void> signInWithGoogle(BuildContext context) async {
    final account = await _googleSignIn.signIn();

    if (account == null) return;

    await DBService().saveUserData(
      email: account.email,
      name: account.displayName ?? "Google User",
      provider: 'google',
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await DBService().clearUserData();
  }
}

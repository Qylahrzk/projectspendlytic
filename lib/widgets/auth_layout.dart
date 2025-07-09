import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth/get_started_screen.dart';       // Screen shown to new/unauthenticated users
import '../navigation/app_loading_page.dart';           // Loading spinner while checking state
import '../navigation/app_navigation_layout.dart';      // Main app layout after login
import '../services/db_service.dart';                   // Local SQLite session checker

/// AuthLayout handles app startup authentication flow:
/// 
/// - First checks FirebaseAuth (stream-based) to see if a user is logged in.
/// - If not logged into Firebase, it checks if a local session exists in SQLite.
/// - Based on login state, it shows either:
///     • AppNavigationLayout (main app)
///     • GetStartedScreen (login/signup)
///     • or a custom fallback screen [pageIfNotConnected] if provided
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  /// Optional fallback widget if user is unauthenticated
  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    // Listen to FirebaseAuth login state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, firebaseSnapshot) {
        // While Firebase is still determining auth state, show loading
        if (firebaseSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage(); // could be CircularProgressIndicator, etc.
        }

        final firebaseUser = firebaseSnapshot.data;

        // If Firebase has a logged-in user, proceed to app
        if (firebaseUser != null) {
          return const AppNavigationLayout();
        } else {
          // If Firebase user is null, fallback to checking local DB for session
          return FutureBuilder<bool>(
            future: DBService().hasSession(),
            builder: (context, sqliteSnapshot) {
              // While checking SQLite session, show loading screen
              if (sqliteSnapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingPage();
              }

              // If session exists in local DB, treat user as logged in
              if (sqliteSnapshot.data == true) {
                return const AppNavigationLayout();
              } else {
                // Otherwise, show onboarding/login screen or provided fallback
                return pageIfNotConnected ?? const GetStartedScreen();
              }
            },
          );
        }
      },
    );
  }
}

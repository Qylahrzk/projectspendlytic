import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth/get_started_screen.dart';
import '../navigation/app_loading_page.dart';
import '../navigation/app_navigation_layout.dart';
import '../services/db_service.dart';

/// AuthLayout determines:
/// - If user is logged in via Firebase
/// - Otherwise checks SQLite for local Google login
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});
  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, firebaseSnapshot) {
        if (firebaseSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage();
        }

        final firebaseUser = firebaseSnapshot.data;

        if (firebaseUser != null) {
          return const AppNavigationLayout();
        } else {
          return FutureBuilder<bool>(
            future: DBService().hasSession(),
            builder: (context, sqliteSnapshot) {
              if (sqliteSnapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingPage();
              }

              if (sqliteSnapshot.data == true) {
                return const AppNavigationLayout();
              } else {
                return pageIfNotConnected ?? const GetStartedScreen();
              }
            },
          );
        }
      },
    );
  }
}

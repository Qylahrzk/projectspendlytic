import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';

import '../screens/auth/get_started_screen.dart';
import '../navigation/app_loading_page.dart';
import '../navigation/app_navigation_layout.dart';
import '../services/db_service.dart';

class AuthLayout extends StatefulWidget {
  const AuthLayout({super.key});

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isBiometricAvailable = false;
  bool _isBiometricVerified = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// 🔍 Check if device supports biometrics
  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = canCheck && isSupported;
        });
      }
    } catch (e) {
      debugPrint('Biometric availability error: $e');
    }
  }

  /// 🔐 Trigger fingerprint / face unlock
  Future<void> _authenticateUser() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Spendlytic',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        setState(() {
          _isBiometricVerified = true;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, firebaseSnapshot) {
        // ⏳ Loading Firebase auth state
        if (firebaseSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage();
        }

        final firebaseUser = firebaseSnapshot.data;

        // =====================================================
        // 🚪 NOT LOGGED IN
        // =====================================================
        if (firebaseUser == null) {
          _isBiometricVerified = false;
          return const GetStartedScreen();
        }

        // =====================================================
        // ✅ LOGGED IN + BIOMETRIC VERIFIED
        // =====================================================
        if (_isBiometricVerified || !_isBiometricAvailable) {
          return const AppNavigationLayout();
        }

        // =====================================================
        // 🔐 NEED BIOMETRIC VERIFICATION
        // =====================================================
        if (firebaseSnapshot.connectionState == ConnectionState.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isBiometricVerified) {
              _authenticateUser();
            }
          });
        }

        return _buildLockScreen();
      },
    );
  }

  /// 🔒 Lock Screen UI
  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Spendlytic Locked',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please authenticate to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: _authenticateUser,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock with Biometrics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await DBService().clearUserData();
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

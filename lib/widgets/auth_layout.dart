import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart'; // 🔒 Biometrics

// Import your app screens
import '../screens/auth/get_started_screen.dart'; // Login Screen
import '../navigation/app_loading_page.dart';     // Loading Spinner
import '../navigation/app_navigation_layout.dart';  // Main Dashboard
import '../services/db_service.dart';             // Local Database

class AuthLayout extends StatefulWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  // Biometric State Management
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricVerified = false;  // Has the user scanned their finger yet?
  bool _isBiometricAvailable = false; // Does the phone actually have a scanner?

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// 1. Check if the device has hardware support (Fingerprint/Face)
  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (mounted) {
        setState(() {
          _isBiometricAvailable = canCheckBiometrics && isDeviceSupported;
        });
      }
    } catch (e) {
      debugPrint("Biometric Check Error: $e");
    }
  }

  /// 2. Trigger the Native Fingerprint Prompt
  Future<void> _authenticateUser() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to access Spendlytic',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keeps the prompt open if app goes to background
          biometricOnly: true, // Don't allow PIN/Pattern fallback (stricter security)
        ),
      );

      if (didAuthenticate && mounted) {
        setState(() {
          _isBiometricVerified = true; // ✅ UNLOCK THE APP
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Biometric Error: $e");
      // If the user cancels or fails too many times, they stay on the lock screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎧 Listen to Supabase Auth State Changes (Login/Logout)
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        
        // A. Loading State (Checking session...)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage();
        }

        final session = snapshot.data?.session;

        // ============================================================
        // CASE 1: USER IS NOT LOGGED IN (Session is Null)
        // ============================================================
        if (session == null) {
          // Reset biometric state so they have to scan again next time they login
          _isBiometricVerified = false; 
          
          // Show the Login/Signup Screen
          return widget.pageIfNotConnected ?? const GetStartedScreen();
        }

        // ============================================================
        // CASE 2: USER IS LOGGED IN (Session Exists)
        // ============================================================

        // A. If they have already passed the fingerprint check:
        if (_isBiometricVerified) {
          return const AppNavigationLayout(); // 🚀 Show Dashboard
        }

        // B. If the device DOES NOT have a scanner (Emulator or old phone):
        if (!_isBiometricAvailable) {
           // Auto-allow them (or you could force a PIN code here)
           return const AppNavigationLayout(); 
        }

        // C. If they haven't scanned yet:
        // We trigger the biometric popup immediately when the screen loads
        if (snapshot.connectionState == ConnectionState.active) {
            // Use a post-frame callback to ensure we don't trigger it during a build
            WidgetsBinding.instance.addPostFrameCallback((_) {
               // Only trigger if we aren't already verified and no dialog is open
               if (!_isBiometricVerified) {
                 _authenticateUser();
               }
            });
        }

        // Show the "Lock Screen" while waiting for the scan
        return _buildLockScreen();
      },
    );
  }

  /// 🔒 The UI shown behind the fingerprint dialog
  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                "Spendlytic Locked",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "For your security, please authenticate to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              
              // Manual Retry Button (in case they cancelled the dialog)
              ElevatedButton.icon(
                onPressed: _authenticateUser, 
                icon: const Icon(Icons.fingerprint),
                label: const Text("Unlock with Biometrics"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button (In case they are stuck or want to switch accounts)
              TextButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  await DBService().clearUserData();
                },
                child: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
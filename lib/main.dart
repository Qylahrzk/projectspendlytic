import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔔 NEW: For Push Notifications
import 'package:supabase_flutter/supabase_flutter.dart';     // 🚀 NEW: For Auth & DB
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'firebase_options.dart';              // Firebase configuration (Keep this for Messaging)
import 'services/db_service.dart';           // Local SQLite DB service
import 'providers/theme_notifier.dart';      // Theme management provider
import 'screens/settings/settings_screen.dart';
import 'screens/account/account_screen.dart';
import 'widgets/auth_layout.dart';           // Entry point widget

// 🔔 BACKGROUND NOTIFICATION HANDLER
// This must be a top-level function (outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to do something when app is closed and notification arrives:
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  // Ensure Flutter widget binding is initialized before Firebase/Supabase/DB init
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  try {
    // 1. Initialize Firebase (REQUIRED for Cloud Messaging)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up background notification listener
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Initialize Supabase (YOUR NEW BACKEND)
    await Supabase.initialize(
      url: 'https://nqdiqjhgslizuqzwopzi.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xZGlxamhnc2xpenVxendvcHppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0Mjg5ODAsImV4cCI6MjA4MDAwNDk4MH0.4d8OT1rgrHYc2QBQorSLrYr2bS56zSBsLrlkHk7Cf5U',
    );

    // 3. Initialize SQLite database
    await DBService().database;

  } catch (e) {
    debugPrint("Initialization error: $e");
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ms'), Locale('zh')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: const SpendlyticApp(),
      ),
    ),
  );
}

class SpendlyticApp extends StatelessWidget {
  const SpendlyticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          title: 'Spendlytic',
          debugShowCheckedModeBanner: false,

          // Theme Logic
          themeMode: themeNotifier.currentTheme,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFF5F4FA),
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 188, 147, 255),
              secondary: Color.fromARGB(255, 217, 191, 250),
              surface: Colors.white,
              onPrimary: Colors.black,
              onSurface: Color(0xFF333333),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFBF00FF),
              secondary: Color.fromARGB(255, 196, 48, 255),
              surface: Color(0xFF1E1E1E),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
          ),

          // Localization
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,

          // Routes
          routes: {
            '/settings': (context) => const SettingsScreen(),
            '/account_settings': (context) => const AccountScreen(),
          },

          // 🔒 The Gatekeeper: Decides if we show Login, Biometrics, or Dashboard
          home: const AuthLayout(),
        );
      },
    );
  }
}
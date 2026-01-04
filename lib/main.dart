import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔔 NEW: For Push Notifications
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
    
     // Initialize SQLite database via your DBService singleton

    // 3. Initialize SQLite database
    await DBService().database;

  } catch (e) {
    // Log or handle initialization errors
    debugPrint("Initialization error: $e");
    // Optionally show an error screen here if initialization fails
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ms'), Locale('zh')],
      path: 'assets/lang',                    // Path to your translation files
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

          // 🌸 LIGHT THEME (Pastel "Love Yourself" Palette)
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Roboto',
            // Lightest Blue background
            scaffoldBackgroundColor: const Color(0xFFF7FAFF), 
            
            colorScheme: const ColorScheme.light(
              // Lavender (#cbb8d6)
              primary: Color(0xFFCBB8D6), 
              // Sky Blue (#a4c6e9)
              secondary: Color(0xFFA4C6E9), 
              // Soft Pink (#efa8c8)
              tertiary: Color(0xFFEFA8C8),
              
              surface: Colors.white,
              onPrimary: Colors.white,
              onSurface: Color(0xFF4A4A4A), // Soft dark grey text
            ),

            // 🎨 Inject Gradient Extension
            extensions: <ThemeExtension<dynamic>>[
              const AppGradients(
                // Pastel Gradient: Peach -> Pink -> Lavender -> Blue
                primaryGradient: LinearGradient(
                  colors: [
                    Color(0xFFF8C9B7), 
                    Color(0xFFF2B4BF), 
                    Color(0xFFCBB8D6), 
                    Color(0xFFA4C6E9), 
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                cardGradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFF8F9FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          ),

          // ⚡ DARK THEME (Neon Version)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Roboto',
            // Deep Black background
            scaffoldBackgroundColor: const Color(0xFF0F0F0F), 
            
            colorScheme: const ColorScheme.dark(
              // Neon Purple
              primary: Color(0xFFD900FF), 
              // Neon Cyan
              secondary: Color(0xFF00E5FF), 
              // Neon Hot Pink
              tertiary: Color(0xFFFF0080),
              
              surface: Color(0xFF1E1E1E),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),

            // 🎨 Inject Gradient Extension
            extensions: <ThemeExtension<dynamic>>[
              const AppGradients(
                // Neon Gradient: Hot Pink -> Electric Purple -> Cyan
                primaryGradient: LinearGradient(
                  colors: [
                    Color(0xFFFF0080), 
                    Color(0xFFD900FF), 
                    Color(0xFF00E5FF), 
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                cardGradient: LinearGradient(
                  colors: [Color(0xFF252525), Color(0xFF1E1E1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ],
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

// ==========================================
// 🎨 CUSTOM THEME EXTENSION (FOR GRADIENTS)
// ==========================================
@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  final Gradient primaryGradient;
  final Gradient cardGradient;

  const AppGradients({
    required this.primaryGradient,
    required this.cardGradient,
  });

  @override
  AppGradients copyWith({Gradient? primaryGradient, Gradient? cardGradient}) {
    return AppGradients(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      cardGradient: cardGradient ?? this.cardGradient,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t)!,
      cardGradient: Gradient.lerp(cardGradient, other.cardGradient, t)!,
    );
  }
}
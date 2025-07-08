import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/db_service.dart';
import 'widgets/auth_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await DBService().database;
  runApp(const SpendlyticApp());
}

class SpendlyticApp extends StatelessWidget {
  const SpendlyticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendlytic',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F4FA),
        colorScheme: ColorScheme.light(
          primary: Color.fromARGB(255, 188, 147, 255),          // pastel purple
          secondary: Color.fromARGB(255, 217, 191, 250),        // periwinkle
          surface: Colors.white,
          onPrimary: Colors.black,
          onSurface: Color(0xFF333333),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFBF00FF),          // Electric Purple
          secondary: Color.fromARGB(255, 196, 48, 255),        // Neon Purple
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      home: const AuthLayout(),
    );
  }
}

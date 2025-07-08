import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'signup_screen.dart';
import '../home/home_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final auth = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  Database? _db;

  bool isLoading = false;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dailyquest.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE userData (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT,
          email TEXT,
          name TEXT,
          provider TEXT
        )
      ''');
    });
  }

  Future<void> loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      await auth.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;

      Navigator.pushReplacement(
        context as BuildContext,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _db?.delete('userData');
        await _db?.insert('userData', {
          'uid': null,
          'email': account.email,
          'name': account.displayName,
          'provider': 'google',
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context as BuildContext,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text("Google login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/images/spendlytic_logo.png', height: 150),
                const SizedBox(height: 24),
                const Text(
                  "Welcome back!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: emailController,
                  validator: (val) => val!.contains('@') ? null : 'Enter valid email',
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  validator: (val) => val!.length >= 6 ? null : 'Min 6 characters',
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LOGIN WITH EMAIL', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: loginWithGoogle,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text("Sign in with Google", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    "Don’t have an account? Sign Up",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/db_service.dart';
// ignore: unused_import
import '../home/home_screen.dart';
import 'signup_screen.dart';
import '../../widgets/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final auth = AuthService();
  final googleAuth = GoogleAuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Email login flow
  Future<void> loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final cred = await auth.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await DBService().saveUserData(
        email: cred.user?.email ?? '',
        name: cred.user?.displayName ?? '',
        provider: 'firebase',
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthLayout()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Google login flow
  Future<void> loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      await googleAuth.signInWithGoogle(context);
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthLayout()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google login failed: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/spendlytic_logo.png',
                  height: 120,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  "Welcome back!",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                /// Email field
                TextFormField(
                  controller: emailController,
                  validator:
                      (val) => val!.contains('@') ? null : 'Enter valid email',
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    context,
                    hint: 'Email',
                    icon: Icons.email,
                  ),
                ),
                const SizedBox(height: 16),

                /// Password field
                TextFormField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  validator:
                      (val) => val!.length >= 6 ? null : 'Min 6 characters',
                  decoration: _inputDecoration(
                    context,
                    hint: 'Password',
                    icon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                        color: colorScheme.primary,
                      ),
                      onPressed:
                          () => setState(() => showPassword = !showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                /// Email login button
                ElevatedButton(
                  onPressed: isLoading ? null : loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'LOGIN WITH EMAIL',
                            style: TextStyle(color: Colors.white),
                          ),
                ),

                const SizedBox(height: 16),

                /// Google login button
                ElevatedButton.icon(
                  onPressed: isLoading ? null : loginWithGoogle,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    "Sign in with Google",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// Sign up
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: Text(
                    "Don’t have an account? Sign Up",
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
    );
  }
}

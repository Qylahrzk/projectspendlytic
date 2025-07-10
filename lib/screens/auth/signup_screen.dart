import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../home/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final auth = AuthService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (passController.text.trim() != confirmPassController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final cred = await auth.createAccount(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      // Save user to SQLite using DBService
      await DBService().saveUserData(
        email: cred.user?.email ?? '',
        name: nameController.text.trim(),
        provider: 'firebase',
      );

      if (!mounted) return;

      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sign-up failed: $e")));
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
                  "Let’s get started!",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                /// Full Name
                TextFormField(
                  controller: nameController,
                  validator:
                      (val) => val!.trim().isEmpty ? 'Enter your name' : null,
                  decoration: _inputDecoration(
                    context,
                    hint: 'Full Name',
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(height: 16),

                /// Email
                TextFormField(
                  controller: emailController,
                  validator:
                      (val) =>
                          val!.contains('@') ? null : 'Enter a valid email',
                  decoration: _inputDecoration(
                    context,
                    hint: 'Email',
                    icon: Icons.email,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                /// Password
                TextFormField(
                  controller: passController,
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
                const SizedBox(height: 16),

                /// Confirm Password
                TextFormField(
                  controller: confirmPassController,
                  obscureText: !showConfirmPassword,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (val != passController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    context,
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.primary,
                      ),
                      onPressed:
                          () => setState(
                            () => showConfirmPassword = !showConfirmPassword,
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : signUp,
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
                            'SIGN UP',
                            style: TextStyle(color: Colors.white),
                          ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Already have an account? Log In",
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

  /// Helper for consistent input styling
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

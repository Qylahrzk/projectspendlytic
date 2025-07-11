import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../services/auth_service.dart';
import '../../providers/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isNotificationOn = true;
  String selectedLanguage = 'English';

  // Language options
  final Map<String, Locale> localeMap = {
    'English': const Locale('en'),
    'Malay': const Locale('ms'),
    'Chinese': const Locale('zh'),
  };

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  // Load user preferences (theme, notifications, language)
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    setState(() {
      isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      isNotificationOn = prefs.getBool('notifications_enabled') ?? true;
      selectedLanguage = prefs.getString('selected_language') ?? 'English';
    });

    themeNotifier.toggleTheme(isDarkMode);
    context.setLocale(localeMap[selectedLanguage]!);
  }

  Future<void> saveDarkModePref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
  }

  Future<void> saveNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> saveLanguagePref(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', language);
  }

  /// Show dialog for changing password
  Future<void> showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await _authService.resetPasswordFromCurrentPassword(
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                  email: _authService.currentUser?.email ?? '',
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Show dialog for deleting the account
  Future<void> showDeleteAccountDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your credentials to confirm account deletion.'),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await _authService.deleteAccount(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                );
                if (mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.pushReplacementNamed(context, '/get_started');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog before logging out
  Future<void> showLogoutConfirmation() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacementNamed(context, '/get_started');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
            title: const Text(
              "SETTINGS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: color.primary,
            foregroundColor: color.onPrimary,
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            settingsContainer(context, colorScheme),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Container with all the settings options
  Widget settingsContainer(BuildContext context, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          buildToggleRow(
            icon: Icons.nightlight_round,
            color: colorScheme.primary,
            label: 'Dark Mode'.tr(),
            value: isDarkMode,
            onChanged: (value) {
              setState(() => isDarkMode = value);
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(value);
              saveDarkModePref(value);
            },
          ),
          const SizedBox(height: 10),
          buildToggleRow(
            icon: Icons.notifications,
            color: colorScheme.primary,
            label: 'Notifications'.tr(),
            value: isNotificationOn,
            onChanged: (value) {
              setState(() => isNotificationOn = value);
              saveNotificationPref(value);
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.language, color: colorScheme.primary),
            title: Text(
              'Language'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              dropdownColor: colorScheme.primary,
              style: const TextStyle(fontSize: 14),
              underline: Container(),
              items: localeMap.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                setState(() => selectedLanguage = newValue);
                context.setLocale(localeMap[newValue]!);
                saveLanguagePref(newValue);
              },
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.lock, color: colorScheme.primary),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: showChangePasswordDialog,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: showDeleteAccountDialog,
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: showLogoutConfirmation,
          ),
        ],
      ),
    );
  }

  /// Helper widget for toggles (dark mode, notifications)
  Widget buildToggleRow({
    required IconData icon,
    required Color color,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Switch(activeColor: color, value: value, onChanged: onChanged),
      ],
    );
  }
}

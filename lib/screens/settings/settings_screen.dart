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

  final Map<String, Locale> localeMap = {
    'English': const Locale('en'),
    'Malay': const Locale('ms'),
    'Chinese': const Locale('zh'),
  };

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    setState(() {
      isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      isNotificationOn = prefs.getBool('notifications_enabled') ?? true;
      selectedLanguage = prefs.getString('selected_language') ?? 'English';

      themeNotifier.toggleTheme(isDarkMode);
      context.setLocale(localeMap[selectedLanguage]!);
    });
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Text(
          'Settings'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
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
              Provider.of<ThemeNotifier>(
                context,
                listen: false,
              ).toggleTheme(value);
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
              items:
                  localeMap.keys.map((String value) {
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
            leading: Icon(Icons.person, color: colorScheme.primary),
            title: Text(
              'Account Settings'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/account_settings');
            },
          ),
        ],
      ),
    );
  }

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

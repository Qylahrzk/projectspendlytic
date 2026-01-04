import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../services/db_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../models/user_model.dart';
import '../../widgets/auth_layout.dart';
import '../../providers/theme_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ================= SERVICES =================
  final DBService _dbService = DBService();
  final AuthService _authService = AuthService();

  // ================= USER INFO =================
  String userName = 'Treasurer';
  String location = 'Malaysia';

  // ================= CURRENCY =================
  String currencySymbol = "RM";
  double currencyRate = 1.0;

  // ================= FINANCIAL DATA =================
  double budget = 0;
  double spend = 0;
  double balance = 0;
  bool isOverBudget = false;

  Map<String, double> categoryTotals = {};
  List<Map<String, dynamic>> recentTransactions = [];

  // ================= DATE =================
  String formattedDate = '';
  String dayOfWeek = '';

  // ================= ICONS =================
  final Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Shopping': Icons.shopping_cart,
    'Transportation': Icons.directions_car,
    'Presents': Icons.card_giftcard,
    'General': Icons.receipt_long,
  };

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _saveDeviceToken();
    _loadDate();
    _loadUserData();
    _loadHomeData();
  }

  // ================= FIREBASE FCM =================
  Future<void> _saveDeviceToken() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final token = await FirebaseMessaging.instance.getToken();

      if (userId != null && token != null) {
        await _dbService.saveDeviceToken(
          userId: userId,
          token: token,
        );
        debugPrint("✅ FCM Token saved");
      }
    } catch (e) {
      debugPrint("❌ FCM error: $e");
    }
  }

  // ================= DATE =================
  Future<void> _loadDate() async {
    final now = DateTime.now();
    formattedDate = DateFormat('dd MMMM').format(now);
    dayOfWeek = DateFormat('EEEE').format(now);
    if (mounted) setState(() {});
  }

  // ================= USER DATA =================
  Future<void> _loadUserData() async {
    try {
      final UserModel? user = await _dbService.getUser();
      if (user != null) {
        setState(() {
          userName = user.name;
          currencySymbol = CurrencyService.getSymbol(user.defaultCurrency);
          currencyRate =
              CurrencyService.conversionRates[user.defaultCurrency] ?? 1.0;
        });
      }
    } catch (e) {
      debugPrint("❌ User data error: $e");
    }
  }

  // ================= HOME DATA =================
  Future<void> _loadHomeData() async {
    try {
      final totalBudget = await _dbService.getTotalBudget();
      final totalSpend = await _dbService.getTotalSpend();
      final recent = await _dbService.getRecentExpenses(5);
      final categories = await _dbService.getCategoryTotals();

      setState(() {
        budget = totalBudget;
        spend = totalSpend;
        balance = totalBudget - totalSpend;
        categoryTotals = categories;
        recentTransactions = recent;
        isOverBudget = totalSpend > totalBudget;
      });
    } catch (e) {
      debugPrint("❌ Home data error: $e");
    }
  }

  // ================= UTILS =================
  String formatCurrency(double amountInMYR) {
    final converted = amountInMYR * currencyRate;
    return "$currencySymbol ${converted.toStringAsFixed(2)}";
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthLayout()),
      (_) => false,
    );
  }

  // ================= DRAWER =================
  void _showDrawerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("Account"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/account_settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= NOTIFICATION =================
  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notifications"),
        content: isOverBudget
            ? Text("⚠️ You’ve exceeded your budget of ${formatCurrency(budget)}.")
            : const Text("No new notifications."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isOverBudget) _buildOverBudgetBanner(),
            _buildHeader(colorScheme),
            _buildBalanceCard(colorScheme),
            _buildExpenseOverview(colorScheme),
            _buildRecentTransactions(colorScheme),
          ],
        ),
      ),
    );
  }

  // ================= WIDGETS =================
  Widget _buildOverBudgetBanner() {
    return Container(
      width: double.infinity,
      color: Colors.redAccent,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Over budget! You spent ${formatCurrency(spend)}.",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/images/app_logo.png",
                  height: 36, color: Colors.white),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: _showNotificationDialog,
                  ),
                  Consumer<ThemeNotifier>(
                    builder: (_, theme, __) => IconButton(
                      icon: Icon(
                        theme.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          theme.toggleTheme(!theme.isDarkMode),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: _showDrawerMenu,
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back - $userName",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Text(
                      "$formattedDate | $dayOfWeek",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Lottie.asset("assets/animations/money.json", height: 140),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _balanceItem("Budget", budget),
          _balanceItem("Spend", spend),
          _balanceItem("Balance", balance),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(formatCurrency(value),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExpenseOverview(ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: categoryTotals.entries.map((entry) {
            return Column(
              children: [
                CircleAvatar(
                  backgroundColor:
                      colorScheme.primary.withOpacity(0.1),
                  child: Icon(categoryIcons[entry.key],
                      color: colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(entry.key),
                Text(
                  "-${formatCurrency(entry.value)}",
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: recentTransactions.map((tx) {
          return ListTile(
            leading: Icon(categoryIcons[tx['category']]),
            title: Text(tx['title']),
            trailing: Text(
              "-${formatCurrency(tx['amount'])}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }).toList(),
      ),
    );
  }
}

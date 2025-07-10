import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';

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
  String currencySymbol = "RM";
  double currencyRate = 1.0;

  String userName = 'Treasurer';
  String location = 'Malaysia';
  double balance = 0;
  double spend = 0;
  double budget = 0;
  bool isOverBudget = false;
  Map<String, double> categoryTotals = {};
  List<Map<String, dynamic>> recentTransactions = [];
  String formattedDate = '';
  String dayOfWeek = '';

  final DBService _dbService = DBService();
  final AuthService _authService = AuthService();

  /// Map categories to icons
  final Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Shopping': Icons.shopping_cart,
    'Transportation': Icons.directions_car,
    'Presents': Icons.card_giftcard,
    'General': Icons.receipt_long,
  };

  @override
  void initState() {
    super.initState();
    _loadDate();
    _loadUserData();
    _loadHomeData();
  }

  Future<void> _loadDate() async {
    final now = DateTime.now();
    formattedDate = DateFormat('dd MMMM').format(now);
    dayOfWeek = DateFormat('EEEE').format(now);
    if (mounted) setState(() {});
  }

  Future<void> _loadUserData() async {
    try {
      final UserModel? userData = await _dbService.getUser();
      if (userData != null) {
        setState(() {
          userName = userData.name;
          if (userData.defaultCurrency.isNotEmpty) {
            currencySymbol = CurrencyService.getSymbol(userData.defaultCurrency);
            currencyRate = CurrencyService.conversionRates[
              userData.defaultCurrency
            ] ?? 1.0;
          } else {
            currencySymbol = "RM";
            currencyRate = 1.0;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

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
      debugPrint("Error loading home data: $e");
    }
  }

  String formatCurrency(double amountInMYR) {
    double converted = amountInMYR * currencyRate;
    return "$currencySymbol ${converted.toStringAsFixed(2)}";
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthLayout()),
      (route) => false,
    );
  }

  void _showDrawerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
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
        );
      },
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notifications"),
        content: isOverBudget
            ? Text(
                "⚠️ You’ve exceeded your monthly budget of ${formatCurrency(budget)}.",
              )
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isOverBudget) _buildOverBudgetBanner(colorScheme),
            _buildPurpleHeader(colorScheme),
            _buildBalanceCard(colorScheme),
            _buildExpenseOverview(colorScheme),
            _buildRecentTransactions(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverBudgetBanner(ColorScheme colorScheme) {
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
              "Over budget! You’ve spent ${formatCurrency(spend)} "
              "which exceeds your budget of ${formatCurrency(budget)}.",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurpleHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                "assets/images/app_logo.png",
                height: 35,
                color: Colors.white,
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: _showNotificationDialog,
                      ),
                      if (isOverBudget)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  Consumer<ThemeNotifier>(
                    builder: (context, themeNotifier, _) {
                      return IconButton(
                        icon: Icon(
                          themeNotifier.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          themeNotifier.toggleTheme(!themeNotifier.isDarkMode);
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: _showDrawerMenu,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back - $userName",
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${formattedDate.toUpperCase()} | ${dayOfWeek.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Lottie.asset(
                "assets/animations/money.json",
                height: 140,
                width: 180,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          formatCurrency(value),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildExpenseOverview(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Expenses - Daily Overview",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              categoryTotals.isEmpty
                  ? Text("No expenses found.", style: TextStyle(color: colorScheme.onSurface))
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: categoryTotals.entries.map((entry) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Color.lerp(colorScheme.primary, Colors.transparent, 0.8),
                              child: Icon(
                                categoryIcons[entry.key] ?? Icons.receipt_long,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(entry.key, style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
                            Text(
                              "-${formatCurrency(entry.value)}",
                              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recent Expenses",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              recentTransactions.isEmpty
                  ? Text("No expenses found.", style: TextStyle(color: colorScheme.onSurface))
                  : Column(
                      children: recentTransactions.map((tx) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: Icon(
                            categoryIcons[tx["category"]] ?? Icons.receipt_long,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            tx["title"] ?? "",
                            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            tx["category"] ?? "Uncategorized",
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          trailing: Text(
                            "-${formatCurrency((tx["amount"] ?? 0).toDouble())}",
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

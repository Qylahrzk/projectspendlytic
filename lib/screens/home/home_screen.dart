import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/db_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'Treasurer';
  String location = 'Malaysia';
  double balance = 0;
  double spend = 0;
  double profit = 0;
  Map<String, double> categoryTotals = {};
  List<Map<String, dynamic>> recentTransactions = [];
  String formattedDate = '';
  String dayOfWeek = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHomeData();
    _loadDate();
  }

  /// Load current date and day
  Future<void> _loadDate() async {
    final now = DateTime.now();
    formattedDate = DateFormat('dd MMMM').format(now);
    dayOfWeek = DateFormat('EEEE').format(now);
    setState(() {});
  }

  /// Load user name from local DB
  Future<void> _loadUserData() async {
    final userData = await DBService().getUserData();
    setState(() {
      userName = userData?['name'] ?? 'Treasurer';
    });
  }

  /// Load home data from local DB
  Future<void> _loadHomeData() async {
    final homeData = await DBService().getHomeData();
    setState(() {
      balance = homeData['balance'] ?? 0;
      spend = homeData['spend'] ?? 0;
      profit = homeData['profit'] ?? 0;
      categoryTotals =
          Map<String, double>.from(homeData['categories'] ?? {});
      recentTransactions = List<Map<String, dynamic>>.from(
        homeData['recentTransactions'] ?? [],
      );
    });
  }

  /// Handle logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    await DBService().clearUserData();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Show bottom drawer with logout option
  void _showDrawerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

  /// Navigate to notifications page (dummy page for now)
  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _NotificationScreen(),
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
            _buildPurpleHeader(colorScheme),
            _buildBalanceCard(colorScheme),
            _buildExpenseOverview(colorScheme),
            _buildRecentTransactions(colorScheme),
          ],
        ),
      ),
    );
  }

  /// Header with purple background and layout
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
          // Top row
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
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: _goToNotifications,
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: _showDrawerMenu,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),

          // Second row
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
                      "$formattedDate | ${dayOfWeek.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Lottie.asset(
                "assets/animations/coin.json",
                height: 120,
                width: 120,
              )
            ],
          )
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
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _balanceItem("My Balance", balance),
          _balanceItem("Spend", spend),
          _balanceItem("Profit", profit),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "RM ${value.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        )
      ],
    );
  }

  Widget _buildExpenseOverview(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Expenses - Daily Overview",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              categoryTotals.isEmpty
                  ? Text(
                      "No expenses found.",
                      style: TextStyle(color: colorScheme.onSurface),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: categoryTotals.entries.map((entry) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Color.lerp(
                                colorScheme.primary,
                                Colors.transparent,
                                0.8,
                              ),
                              child: Icon(
                                Icons.pie_chart,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              "-RM ${entry.value.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    )
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recent Transactions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              recentTransactions.isEmpty
                  ? Text(
                      "No transactions found.",
                      style: TextStyle(color: colorScheme.onSurface),
                    )
                  : Column(
                      children: recentTransactions.map((tx) {
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Icon(Icons.receipt_long,
                              color: colorScheme.primary),
                          title: Text(
                            tx["title"] ?? "",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            tx["category"] ?? "Uncategorized",
                            style:
                                TextStyle(color: colorScheme.onSurface),
                          ),
                          trailing: Text(
                            "-RM ${tx["amount"].toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.redAccent),
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

/// Dummy notification screen
class _NotificationScreen extends StatelessWidget {
  // ignore: unused_element_parameter
  const _NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: const Center(
        child: Text("No notifications yet."),
      ),
    );
  }
}

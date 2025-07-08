import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
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

  Future<void> _loadDate() async {
    final now = DateTime.now();
    formattedDate = DateFormat('dd MMMM').format(now);
    dayOfWeek = DateFormat('EEEE').format(now);
    setState(() {});
  }

  Future<void> _loadUserData() async {
    final userData = await DBService().getUserData();
    setState(() {
      userName = userData?['name'] ?? 'Treasurer';
    });
  }

  Future<void> _loadHomeData() async {
    final homeData = await DBService().getHomeData();
    setState(() {
      balance = homeData['balance'] ?? 0;
      spend = homeData['spend'] ?? 0;
      profit = homeData['profit'] ?? 0;
      categoryTotals = Map<String, double>.from(homeData['categories'] ?? {});
      recentTransactions = List<Map<String, dynamic>>.from(
        homeData['recentTransactions'] ?? [],
      );
    });
  }

  void _logout() async {
    await DBService().clearUserData();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPurpleHeader(),
            _buildBalanceCard(balance, spend, profit),
            _buildExpenseOverview(categoryTotals),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  /// New Purple Header with rounded bottom and complete layout
  Widget _buildPurpleHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF6C63FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW: Logo + Notification + Hamburger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // App Logo
              Image.asset(
                "assets/images/app_logo.png",
                height: 35,
              ),
              // Notification + Hamburger
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: () {
                      // handle notification
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

          // SECOND ROW: Text info + Lottie
          Row(
            children: [
              // Left: text info
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
              // Right: Coin Lottie animation
              Lottie.asset(
                "assets/animations/coin.json",
                height: 120,
                width: 120,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double spend, double profit) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B5DE5)],
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

  Widget _buildExpenseOverview(Map<String, double> categoryTotals) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Expenses - Daily Overview",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              categoryTotals.isEmpty
                  ? const Text("No expenses found.")
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: categoryTotals.entries.map((entry) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.deepPurple.shade50,
                              child: const Icon(
                                Icons.pie_chart,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
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

  Widget _buildRecentTransactions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              recentTransactions.isEmpty
                  ? const Text("No transactions found.")
                  : Column(
                      children: recentTransactions.map((tx) {
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: const Icon(Icons.receipt_long,
                              color: Colors.deepPurple),
                          title: Text(
                            tx["title"] ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              Text(tx["category"] ?? "Uncategorized"),
                          trailing: Text(
                            "-RM ${tx["amount"].toStringAsFixed(2)}",
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

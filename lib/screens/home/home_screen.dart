import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // For Lottie animations
import 'package:intl/intl.dart'; // For date formatting
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase user (if using Firebase auth)

// Local imports for services and widgets
import '../../services/db_service.dart'; // Database service for local data storage
import '../../services/auth_service.dart'; // Authentication service for logout
import '../../models/user_model.dart'; // User model for local user data
import '../../widgets/auth_layout.dart'; // Layout for authentication screens

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables to hold home screen data
  String userName = 'Treasurer'; // Default user name
  String location = 'Malaysia'; // Default location (could be user-configurable)
  double balance = 0; // User's total balance
  double spend = 0; // Total spending
  double profit = 0; // Total profit
  Map<String, double> categoryTotals =
      {}; // Map to store total spend per category
  List<Map<String, dynamic>> recentTransactions =
      []; // List of recent transactions
  String formattedDate = ''; // Formatted current date (e.g., "09 JULY")
  String dayOfWeek = ''; // Current day of the week (e.g., "WEDNESDAY")

  // Instantiate DBService and AuthService for use in this state
  final DBService _dbService = DBService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Load date, user data, and home financial data when the screen initializes
    _loadDate();
    _loadUserData();
    _loadHomeData();
  }

  /// Disposes controllers and other disposable resources when the widget is removed
  @override
  void dispose() {
    // No specific controllers to dispose in this screen based on current implementation
    super.dispose();
  }

  /// Loads and formats the current date and day of the week.
  Future<void> _loadDate() async {
    final now = DateTime.now();
    formattedDate = DateFormat('dd MMMM').format(now);
    dayOfWeek = DateFormat('EEEE').format(now);
    // Update the UI if the widget is still mounted
    if (mounted) setState(() {});
  }

  /// Loads user's name from the local SQLite database.
  /// It now expects a `UserModel` from `DBService().getUserData()`.
  Future<void> _loadUserData() async {
    try {
      final UserModel? userData = (await _dbService.getUser()); // Get UserModel
      if (userData != null) {
        setState(() {
          // Update userName from the UserModel's name property
          userName = userData.name; // Use null-aware operator for safety
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e"); // Log any errors
    }
  }

  /// Loads aggregated financial data (balance, spend, profit, categories, transactions)
  /// from the local SQLite database.
  Future<void> _loadHomeData() async {
    try {
      // Assuming DBService().getHomeData() is designed to return a Map of aggregated data
      final Map<String, dynamic> homeData = await _dbService.getHomeData();
      setState(() {
        balance = homeData['balance'] ?? 0;
        spend = homeData['spend'] ?? 0;
        profit = homeData['profit'] ?? 0;
        // Ensure type safety when casting to Map<String, double>
        categoryTotals = Map<String, double>.from(homeData['categories'] ?? {});
        // Ensure type safety when casting to List<Map<String, dynamic>>
        recentTransactions = List<Map<String, dynamic>>.from(
          homeData['recentTransactions'] ?? [],
        );
      });
    } catch (e) {
      debugPrint("Error loading home data: $e"); // Log any errors
    }
  }

  /// Logs out the current user from Firebase and clears local user data.
  /// Navigates the user back to the authentication layout.
  Future<void> _logout() async {
    // Sign out from Firebase
    await _authService.signOut(); // Use the AuthService for sign out logic

    // Ensure the widget is still in the tree before attempting navigation
    if (!mounted) return;

    // Navigate to AuthLayout and remove all previous routes from the stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthLayout()),
      (route) =>
          false, // This predicate ensures all previous routes are removed
    );
  }

  /// Shows a modal bottom sheet containing menu options, specifically a logout option.
  void _showDrawerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings), // Settings icon
                title: const Text("Settings"),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.pushNamed(
                    context,
                    '/settings',
                  ); // Navigate to settings screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout), // Logout icon
                title: const Text("Logout"),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _logout(); // Perform logout
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigates to a dummy notification screen.
  void _goToNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme's color scheme for consistent styling
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Set background color
      body: SingleChildScrollView(
        // Makes the content scrollable if it exceeds screen height
        child: Column(
          children: [
            // Build the purple header section
            _buildPurpleHeader(colorScheme),
            // Build the balance summary card
            _buildBalanceCard(colorScheme),
            // Build the daily expense overview section
            _buildExpenseOverview(colorScheme),
            // Build the recent transactions section
            _buildRecentTransactions(colorScheme),
          ],
        ),
      ),
    );
  }

  /// Builds the top purple header section of the home screen.
  /// Includes app logo, notification icon, menu icon, welcome message,
  /// current location, date, and a money animation.
  Widget _buildPurpleHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity, // Takes full width
      decoration: BoxDecoration(
        color: colorScheme.primary, // Primary color background
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        16,
        48,
        16,
        24,
      ), // Padding around content
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align children to the start
        children: [
          // Top row containing app logo and action icons
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Space items evenly
            children: [
              Image.asset(
                "assets/images/app_logo.png", // Path to app logo asset
                height: 35,
                color: Colors.white, // Tint logo white
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white, // White icon for notifications
                    ),
                    onPressed: _goToNotifications, // Navigate to notifications
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                    ), // White menu icon
                    onPressed: _showDrawerMenu, // Show drawer/bottom sheet menu
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16), // Spacer
          // Second row containing welcome message, location, date, and Lottie animation
          Row(
            children: [
              Expanded(
                // Takes available space for text content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back - $userName", // Dynamic welcome message
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location, // Dynamic location display
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70, // Slightly transparent white
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${formattedDate.toUpperCase()} | ${dayOfWeek.toUpperCase()}", // Dynamic date display
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
                "assets/animations/money.json", // Lottie animation asset
                height: 140,
                width: 180,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the balance overview card displaying total balance, spend, and profit.
  Widget _buildBalanceCard(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16), // Margin around the card
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Rounded corners
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ], // Gradient background
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 24,
      ), // Padding inside the card
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space items evenly
        children: [
          _balanceItem(
            "My Balance",
            balance,
          ), // Individual balance item for total
          _balanceItem("Spend", spend), // Individual balance item for spend
          _balanceItem("Profit", profit), // Individual balance item for profit
        ],
      ),
    );
  }

  /// Helper widget to display a single balance item (label and value).
  Widget _balanceItem(String label, double value) {
    return Column(
      children: [
        Text(
          label, // Label (e.g., "My Balance")
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6), // Spacer
        Text(
          "RM ${value.toStringAsFixed(2)}", // Formatted currency value
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Builds the "Expenses - Daily Overview" section, showing category-wise spending.
  Widget _buildExpenseOverview(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16), // Margin around the card
      child: Card(
        color: colorScheme.surface, // Card background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ), // Rounded corners
        child: Padding(
          padding: const EdgeInsets.all(16), // Padding inside the card
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the start
            children: [
              Text(
                "Expenses - Daily Overview", // Section title
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface, // Text color based on theme
                ),
              ),
              const SizedBox(height: 12), // Spacer
              // Conditional rendering based on whether categoryTotals is empty
              categoryTotals.isEmpty
                  ? Text(
                    "No expenses found.", // Message if no expenses
                    style: TextStyle(color: colorScheme.onSurface),
                  )
                  : Wrap(
                    spacing: 16, // Horizontal spacing between items
                    runSpacing: 16, // Vertical spacing between lines of items
                    children:
                        categoryTotals.entries.map((entry) {
                          return Column(
                            mainAxisSize:
                                MainAxisSize
                                    .min, // Shrink column to content size
                            children: [
                              CircleAvatar(
                                radius: 24,
                                // Blended color for the circle avatar background
                                backgroundColor: Color.lerp(
                                  colorScheme.primary,
                                  Colors.transparent,
                                  0.8, // 80% transparent primary color
                                ),
                                child: Icon(
                                  Icons.pie_chart, // Icon for categories
                                  color: colorScheme.primary, // Icon color
                                ),
                              ),
                              const SizedBox(height: 4), // Spacer
                              Text(
                                entry.key, // Category name
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface, // Text color
                                ),
                              ),
                              Text(
                                "-RM ${entry.value.toStringAsFixed(2)}", // Formatted expense amount
                                style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors
                                          .redAccent, // Red color for expenses
                                ),
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

  /// Builds the "Recent Transactions" section, displaying a list of latest transactions.
  Widget _buildRecentTransactions(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16), // Margin around the card
      child: Card(
        color: colorScheme.surface, // Card background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ), // Rounded corners
        child: Padding(
          padding: const EdgeInsets.all(16), // Padding inside the card
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the start
            children: [
              Text(
                "Recent Transactions", // Section title
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface, // Text color
                ),
              ),
              const SizedBox(height: 12), // Spacer
              // Conditional rendering based on whether recentTransactions is empty
              recentTransactions.isEmpty
                  ? Text(
                    "No transactions found.", // Message if no transactions
                    style: TextStyle(color: colorScheme.onSurface),
                  )
                  : Column(
                    children:
                        recentTransactions.map((tx) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ), // Padding for list tile content
                            leading: Icon(
                              Icons.receipt_long, // Icon for transactions
                              color: colorScheme.primary, // Icon color
                            ),
                            title: Text(
                              tx["title"] ?? "", // Transaction title
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface, // Text color
                              ),
                            ),
                            subtitle: Text(
                              tx["category"] ??
                                  "Uncategorized", // Transaction category
                              style: TextStyle(
                                color: colorScheme.onSurface,
                              ), // Text color
                            ),
                            trailing: Text(
                              "-RM ${tx["amount"].toStringAsFixed(2)}", // Formatted transaction amount
                              style: const TextStyle(
                                color: Colors.redAccent,
                              ), // Red color for amount
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

/// A dummy screen for notifications, used for navigation example.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")), // AppBar with title
      body: const Center(child: Text("No notifications yet.")), // Centered text
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BudgetTrackingScreen extends StatefulWidget {
  const BudgetTrackingScreen({super.key});

  @override
  State<BudgetTrackingScreen> createState() => _BudgetTrackingScreenState();
}

class _BudgetTrackingScreenState extends State<BudgetTrackingScreen> {
  late Map<String, double> _expensesByCategory;
  late Map<String, double> _budgets;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _expensesByCategory = {};
    _budgets = {};
    _initializeNotifications();
    _loadData();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'budget_channel',
      'Budget Alerts',
      channelDescription: 'Notifications for budget tracking status',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Budget Reminder',
      message,
      platformChannelSpecifics,
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesString = prefs.getString('expensesByCategory');
    final budgetsString = prefs.getString('budgets');

    setState(() {
      _expensesByCategory = expensesString != null
          ? Map<String, double>.from(json.decode(expensesString))
          : {};

      _budgets = budgetsString != null
          ? Map<String, double>.from(json.decode(budgetsString))
          : {};
    });

    _checkAndNotifyStatus();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expensesByCategory', json.encode(_expensesByCategory));
    await prefs.setString('budgets', json.encode(_budgets));
    _checkAndNotifyStatus();
  }

  void _addExpense(String category, double amount) {
    setState(() {
      _expensesByCategory[category] = (_expensesByCategory[category] ?? 0) + amount;
    });
    _saveData();
  }

  void _setBudget(String category, double newBudget) {
    setState(() {
      _budgets[category] = newBudget;
      _expensesByCategory.putIfAbsent(category, () => 0);
    });
    _saveData();
  }

  Future<void> _showSetBudgetDialog() async {
    final categoryController = TextEditingController();
    final budgetController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set a New Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Budget Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final category = categoryController.text.trim();
                final budget = double.tryParse(budgetController.text);
                if (category.isNotEmpty && budget != null) {
                  _setBudget(category, budget);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddExpenseDialog() async {
    String? selectedCategory;
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                items: _budgets.keys.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value;
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (selectedCategory != null && amount != null) {
                  _addExpense(selectedCategory!, amount);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearData() async {
    setState(() {
      _expensesByCategory.clear();
      _budgets.clear();
    });
    _saveData();
  }

  double _getTotalBudget() => _budgets.values.fold(0.0, (sum, item) => sum + item);
  double _getTotalSpent() => _expensesByCategory.values.fold(0.0, (sum, item) => sum + item);

  void _checkAndNotifyStatus() {
    final totalBudget = _getTotalBudget();
    final totalSpent = _getTotalSpent();

    if (totalBudget == 0) return;

    if (totalSpent > totalBudget) {
      _showNotification("You've gone over your total budget!");
    } else {
      _showNotification("You're on track with your budget!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalBudget = _getTotalBudget();
    final totalSpent = _getTotalSpent();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text('Budget Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearData,
          ),
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: _showSetBudgetDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: colorScheme.surface,
              child: ListTile(
                title: const Text('Overall Budget Summary'),
                subtitle: Text(
                  'Total Budget: RM${totalBudget.toStringAsFixed(2)}\nTotal Spent: RM${totalSpent.toStringAsFixed(2)}',
                ),
                trailing: Text(
                  totalSpent > totalBudget ? 'Over Budget!' : 'On Track',
                  style: TextStyle(
                    color: totalSpent > totalBudget ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _budgets.isEmpty
                  ? Center(
                      child: Text(
                        'No budgets set yet. Tap the + icon to get started!',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    )
                  : ListView(
                      children: _budgets.keys.map((category) {
                        final spent = _expensesByCategory[category] ?? 0.0;
                        final budget = _budgets[category]!;
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(category),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (spent / budget).clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    spent > budget ? Colors.red : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Spent: RM${spent.toStringAsFixed(2)} / Budget: RM${budget.toStringAsFixed(2)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _showAddExpenseDialog,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

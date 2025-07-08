import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../../services/db_service.dart';

class LogExpensesScreen extends StatefulWidget {
  const LogExpensesScreen({super.key});

  @override
  State<LogExpensesScreen> createState() => _LogExpensesScreenState();
}

class _LogExpensesScreenState extends State<LogExpensesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Food', 'Transportation', 'Shopping'];

  List<Map<String, dynamic>> _expenses = [];

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    final db = await DBService().database;
    final data = await db.query('expenses', orderBy: 'date DESC');
    setState(() {
      _expenses = data;
    });
  }

  Future<void> _addExpense(String title, double amount, String category) async {
    final db = await DBService().database;
    final expense = {
      'title': title,
      'amount': amount,
      'category': category,
      'date': DateTime.now().toIso8601String(),
    };
    await db.insert('expenses', expense);
    _fetchExpenses();
  }

  Future<void> _clearExpenses() async {
    final db = await DBService().database;
    await db.delete('expenses');
    _fetchExpenses();
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All expenses have been cleared!')),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/budget_track');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/review_insights');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/account');
        break;
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final title = _titleController.text.trim();
              final amountText = _amountController.text.trim();
              if (title.isNotEmpty && amountText.isNotEmpty) {
                final amount = double.tryParse(amountText);
                if (amount != null) {
                  _addExpense(title, amount, _selectedCategory);
                  _titleController.clear();
                  _amountController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid amount entered!')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final inputImage = InputImage.fromFilePath(image.path);
      // ignore: deprecated_member_use
      final textDetector = GoogleMlKit.vision.textRecognizer();
      final recognizedText = await textDetector.processImage(inputImage);
      String scannedText = recognizedText.text;
      _showScannedTextDialog(scannedText);
    }
  }

  void _showScannedTextDialog(String scannedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanned Receipt'),
        content: SingleChildScrollView(child: Text(scannedText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _processScannedText(scannedText);
              Navigator.pop(context);
            },
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  void _processScannedText(String text) {
    final title = _extractTitleFromText(text);
    final amount = _extractAmountFromText(text);
    if (title != null && amount != null) {
      _addExpense(title, amount, 'General');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract title or amount.')),
      );
    }
  }

  String? _extractTitleFromText(String text) {
    final lines = text.split('\n');
    return lines.isNotEmpty ? lines[0].trim() : null;
  }

  double? _extractAmountFromText(String text) {
    final regex = RegExp(r'RM\s?\d+(\.\d{1,2})?');
    final match = regex.firstMatch(text);
    if (match != null) {
      final clean = match.group(0)?.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(clean ?? '');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        title: const Text('Spendlytic - Expenses'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Expenses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.delete), onPressed: _clearExpenses),
                    IconButton(icon: const Icon(Icons.camera_alt), onPressed: _pickReceiptImage),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text('No expenses logged yet.'))
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final exp = _expenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(exp['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${exp['category']} - ${DateFormat.yMMMd().format(DateTime.parse(exp['date']))}'),
                          trailing: Text('RM ${exp['amount'].toStringAsFixed(2)}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }
}

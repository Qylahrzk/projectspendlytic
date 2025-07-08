import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  // Singleton instance
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static const String _dbName = 'spendlytic.db';
  static const String _userTable = 'userData';
  static const String _balanceTable = 'balance';
  static const String _transactionTable = 'transactions';

  Database? _db;

  /// Lazily initializes the database
  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  /// Initializes the SQLite database
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create userData table
        await db.execute('''
          CREATE TABLE $_userTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            name TEXT,
            provider TEXT
          );
        ''');

        // Create balance table
        await db.execute('''
          CREATE TABLE $_balanceTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total_balance REAL DEFAULT 0
          );
        ''');

        // Create transactions table
        await db.execute('''
          CREATE TABLE $_transactionTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            category TEXT,
            type TEXT,
            date TEXT
          );
        ''');
      },
    );
  }

  /// Save user data to userData table
  Future<void> saveUserData({
    required String email,
    String? name,
    String? provider,
  }) async {
    final db = await database;

    try {
      await db.insert(_userTable, {
        'email': email,
        'name': name ?? '',
        'provider': provider ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  /// Update user name (for profile updates)
  Future<void> updateUserName(String newName) async {
    final db = await database;
    try {
      await db.update(_userTable, {'name': newName}, where: 'name IS NOT NULL');
    } catch (e) {
      print("Error updating user name: $e");
    }
  }

  /// Retrieve single user session info
  Future<Map<String, dynamic>?> getUserData() async {
    final db = await database;
    try {
      final result = await db.query(_userTable, limit: 1);
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  /// Deletes all user info for logout
  Future<void> clearUserData() async {
    final db = await database;
    try {
      await db.delete(_userTable);
      // Optionally clear session-related data from other tables, like balance and transactions
      await db.delete(_balanceTable);
      await db.delete(_transactionTable);
    } catch (e) {
      print("Error clearing user data: $e");
    }
  }

  /// Checks if a user session exists locally
  Future<bool> hasSession() async {
    final db = await database;
    try {
      final result = await db.query(_userTable, limit: 1);
      return result.isNotEmpty;
    } catch (e) {
      print("Error checking session: $e");
      return false;
    }
  }

  /// Loads home screen data:
  /// - balance
  /// - total spend
  /// - total income
  /// - expenses grouped by category
  Future<Map<String, dynamic>> getHomeData() async {
    final db = await database;

    double balance = 0;
    double totalSpend = 0;
    double totalIncome = 0;
    Map<String, double> categoryTotals = {};

    try {
      // Get total balance (defaults to 0 if no record)
      final balanceResult = await db.query(_balanceTable, limit: 1);
      if (balanceResult.isNotEmpty) {
        balance =
            (balanceResult.first['total_balance'] as num?)?.toDouble() ?? 0;
      }

      // Get total spend (expenses)
      final spendResult = await db.rawQuery("""
        SELECT SUM(amount) as total_spend
        FROM $_transactionTable
        WHERE type = 'expense'
      """);
      if (spendResult.isNotEmpty && spendResult.first['total_spend'] != null) {
        totalSpend = (spendResult.first['total_spend'] as num).toDouble();
      }

      // Get total income
      final incomeResult = await db.rawQuery("""
        SELECT SUM(amount) as total_income
        FROM $_transactionTable
        WHERE type = 'income'
      """);
      if (incomeResult.isNotEmpty &&
          incomeResult.first['total_income'] != null) {
        totalIncome = (incomeResult.first['total_income'] as num).toDouble();
      }

      // Get expenses grouped by category
      final categoryResults = await db.rawQuery("""
        SELECT category, SUM(amount) as total
        FROM $_transactionTable
        WHERE type = 'expense'
        GROUP BY category
      """);

      for (var row in categoryResults) {
        categoryTotals[row['category'] as String] =
            (row['total'] as num?)?.toDouble() ?? 0;
      }
    } catch (e) {
      print("Error loading home data: $e");
    }

    return {
      'balance': balance,
      'spend': totalSpend,
      'profit': totalIncome,
      'categories': categoryTotals,
    };
  }
}

import 'package:projectspendlytic/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static const String _dbName = 'spendlytic.db';
  static const String _userTable = 'userData';
  static const String _balanceTable = 'balance';
  static const String transactionTable = 'transactions';
  static const String budgetTable = 'budgets';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS $_userTable');
          await _createTables(db);
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $budgetTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT UNIQUE,
              amount REAL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        name TEXT,
        provider TEXT,
        defaultCurrency TEXT,
        sorting TEXT,
        summary TEXT,
        profilePicturePath TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_balanceTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_balance REAL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $transactionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        category TEXT,
        type TEXT,
        date TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $budgetTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT UNIQUE,
        amount REAL
      )
    ''');
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
    if (kDebugMode) {
      debugPrint("Database deleted.");
    }
  }

  Future<void> saveUserData({
    required String email,
    String? name,
    String? provider,
    String? defaultCurrency,
    String? sorting,
    String? summary,
    String? profilePicturePath,
  }) async {
    final db = await database;
    await db.insert(
      _userTable,
      {
        'email': email,
        'name': name ?? '',
        'provider': provider ?? '',
        'defaultCurrency': defaultCurrency ?? '',
        'sorting': sorting ?? '',
        'summary': summary ?? '',
        'profilePicturePath': profilePicturePath ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUserName(String newName) async {
    final db = await database;
    await db.update(
      _userTable,
      {'name': newName},
      where: 'name IS NOT NULL',
    );
  }

  Future<UserModel?> getUser() async {
    final db = await database;
    final result = await db.query(_userTable, limit: 1);
    if (result.isNotEmpty) {
      try {
        return UserModel.fromMap(result.first);
      } catch (e) {
        debugPrint("Error parsing user data: $e");
        return null;
      }
    }
    return null;
  }

  Future<void> saveOrUpdateUser(UserModel newUser) async {
    final db = await database;
    await db.insert(
      _userTable,
      newUser.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearUserData() async {
    final db = await database;
    await db.delete(_userTable);
    await db.delete(_balanceTable);
    await db.delete(transactionTable);
    await db.delete(budgetTable);
  }

  Future<bool> hasSession() async {
    final db = await database;
    final result = await db.query(_userTable, limit: 1);
    return result.isNotEmpty;
  }

  // ✅ NEW METHODS FOR HOME SCREEN

  /// Get total budget across all categories
  Future<double> getTotalBudget() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM $budgetTable');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total expense transactions
  Future<double> getTotalSpend() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $transactionTable
      WHERE type = 'expense'
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Fetch recent expense transactions
  Future<List<Map<String, dynamic>>> getRecentExpenses(int limit) async {
    final db = await database;
    final result = await db.query(
      transactionTable,
      where: 'type = ?',
      whereArgs: ['expense'],
      orderBy: 'date DESC',
      limit: limit,
    );
    return result;
  }

  /// Group expenses by category
  Future<Map<String, double>> getCategoryTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM $transactionTable
      WHERE type = 'expense'
      GROUP BY category
    ''');
    Map<String, double> totals = {};
    for (var row in result) {
      final category = row['category'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (category != null) {
        totals[category] = total;
      }
    }
    return totals;
  }

  /// Get default currency
  Future<String> getDefaultCurrency() async {
    final user = await getUser();
    return user?.defaultCurrency ?? 'MYR (RM)';
  }

  /// Get daily sums of expenses
  Future<Map<DateTime, double>> getDailyExpenseSums() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DATE(date) as day, SUM(amount) as total
      FROM $transactionTable
      WHERE type = 'expense'
      GROUP BY DATE(date)
    ''');

    Map<DateTime, double> sums = {};
    for (final row in result) {
      final dayStr = row['day'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final day = DateTime.parse(dayStr);
      sums[DateTime(day.year, day.month, day.day)] = total;
    }
    return sums;
  }

  /// Save or update a budget for a category
  Future<void> setBudget(String category, double amount) async {
    final db = await database;
    await db.insert(
      budgetTable,
      {
        'category': category,
        'amount': amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all budgets
  Future<Map<String, double>> getBudgets() async {
    final db = await database;
    final result = await db.query(budgetTable);
    return {
      for (var row in result)
        row['category'] as String: (row['amount'] as num?)?.toDouble() ?? 0.0
    };
  }
}

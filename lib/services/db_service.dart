import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  // Singleton pattern
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  // Database name
  static const String _dbName = 'spendlytic.db';

  // Table names
  static const String _userTable = 'userData';
  static const String _balanceTable = 'balance';
  static const String transactionTable = 'transactions';

  Database? _db;

  /// Returns the database instance (lazily opens if needed)
  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  /// Initializes the database and handles upgrades
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 2, // BUMPED VERSION from 1 → 2
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add missing tables if upgrading from v1
          await _createTables(db);
        }
      },
    );
  }

  /// Creates all tables needed for Spendlytic
  Future<void> _createTables(Database db) async {
    // Create userData table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        name TEXT,
        provider TEXT
      );
    ''');

    // Create balance table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_balanceTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_balance REAL DEFAULT 0
      );
    ''');

    // Create transactions table
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
  }

  /// Deletes the entire database (for dev reset)
  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
    print("Database deleted.");
  }

  /// Save a user record
  Future<void> saveUserData({
    required String email,
    String? name,
    String? provider,
  }) async {
    final db = await database;
    await db.insert(
      _userTable,
      {
        'email': email,
        'name': name ?? '',
        'provider': provider ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update user name
  Future<void> updateUserName(String newName) async {
    final db = await database;
    await db.update(
      _userTable,
      {'name': newName},
      where: 'name IS NOT NULL',
    );
  }

  /// Returns the first user record
  Future<Map<String, dynamic>?> getUserData() async {
    final db = await database;
    final result = await db.query(_userTable, limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  /// Deletes all user-related data
  Future<void> clearUserData() async {
    final db = await database;
    await db.delete(_userTable);
    await db.delete(_balanceTable);
    await db.delete(transactionTable);
  }

  /// Checks if user session exists
  Future<bool> hasSession() async {
    final db = await database;
    final result = await db.query(_userTable, limit: 1);
    return result.isNotEmpty;
  }

  /// Loads home data summary for dashboard
  ///
  /// Returns a map like:
  /// {
  ///   'balance': double,
  ///   'spend': double,
  ///   'profit': double,
  ///   'categories': Map<String, double>
  /// }
  Future<Map<String, dynamic>> getHomeData() async {
    final db = await database;

    double balance = 0;
    double totalSpend = 0;
    double totalIncome = 0;
    Map<String, double> categoryTotals = {};

    try {
      // Read balance
      final balanceResult = await db.query(_balanceTable, limit: 1);
      if (balanceResult.isNotEmpty) {
        balance =
            (balanceResult.first['total_balance'] as num?)?.toDouble() ?? 0;
      }

      // Total expenses
      final spendResult = await db.rawQuery('''
        SELECT SUM(amount) as total_spend
        FROM $transactionTable
        WHERE type = 'expense'
      ''');
      if (spendResult.isNotEmpty &&
          spendResult.first['total_spend'] != null) {
        totalSpend = (spendResult.first['total_spend'] as num).toDouble();
      }

      // Total income
      final incomeResult = await db.rawQuery('''
        SELECT SUM(amount) as total_income
        FROM $transactionTable
        WHERE type = 'income'
      ''');
      if (incomeResult.isNotEmpty &&
          incomeResult.first['total_income'] != null) {
        totalIncome = (incomeResult.first['total_income'] as num).toDouble();
      }

      // Expenses by category
      final categoryResults = await db.rawQuery('''
        SELECT category, SUM(amount) as total
        FROM $transactionTable
        WHERE type = 'expense'
        GROUP BY category
      ''');

      for (var row in categoryResults) {
        final cat = row['category'] as String?;
        final total = (row['total'] as num?)?.toDouble() ?? 0;
        if (cat != null) {
          categoryTotals[cat] = total;
        }
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

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static const String _dbName = 'spendlytic.db';
  static const String _tableName = 'userData';

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            name TEXT,
            provider TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE balance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total_balance REAL
          );
        ''');

        await db.execute('''
          CREATE TABLE transactions (
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

  Future<void> saveUserData({
    required String email,
    String? name,
    String? provider,
  }) async {
    final db = await database;
    await db.insert(
      _tableName,
      {
        'email': email,
        'name': name,
        'provider': provider,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final db = await database;
    final result = await db.query(_tableName, limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> clearUserData() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Future<bool> hasSession() async {
    final db = await database;
    final result = await db.query(_tableName, limit: 1);
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>> getHomeData() async {
    final db = await database;

    final balanceResult = await db.query('balance', limit: 1);
    double balance = 0;
    if (balanceResult.isNotEmpty) {
      balance = (balanceResult.first['total_balance'] as num?)?.toDouble() ?? 0;
    }

    final spendResult = await db.rawQuery("""
      SELECT SUM(amount) as total_spend
      FROM transactions
      WHERE type = 'expense'
    """);

    double totalSpend = 0;
    if (spendResult.isNotEmpty && spendResult.first['total_spend'] != null) {
      totalSpend = (spendResult.first['total_spend'] as num).toDouble();
    }

    final incomeResult = await db.rawQuery("""
      SELECT SUM(amount) as total_income
      FROM transactions
      WHERE type = 'income'
    """);

    double totalIncome = 0;
    if (incomeResult.isNotEmpty && incomeResult.first['total_income'] != null) {
      totalIncome = (incomeResult.first['total_income'] as num).toDouble();
    }

    final categoryResults = await db.rawQuery("""
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE type = 'expense'
      GROUP BY category
    """);

    Map<String, double> categoryTotals = {};
    for (var row in categoryResults) {
      categoryTotals[row['category'] as String] =
          (row['total'] as num?)?.toDouble() ?? 0;
    }

    return {
      'balance': balance,
      'spend': totalSpend,
      'profit': totalIncome,
      'categories': categoryTotals,
    };
  }
}

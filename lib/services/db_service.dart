import 'package:projectspendlytic/models/user_model.dart';
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
  static const String transactionTable = 'transactions';

  Database? _db;

  /// Lazy-loaded database instance
  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  /// Initializes and upgrades the database schema
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS $_userTable');
          await _createTables(db);
        }
      },
    );
  }

  /// Creates all required tables
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
  }

  /// Deletes the entire local DB
  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
    print("Database deleted.");
  }

  /// Saves a user record (with optional extra fields)
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

  /// Updates user name (if any existing record found)
  Future<void> updateUserName(String newName) async {
    final db = await database;
    await db.update(
      _userTable,
      {'name': newName},
      where: 'name IS NOT NULL',
    );
  }

  /// Gets the first user record as a UserModel
  Future<UserModel?> getUser() async {
    final db = await database;
    final result = await db.query(_userTable, limit: 1);
    if (result.isNotEmpty) {
      try {
        return UserModel.fromMap(result.first);
      } catch (e) {
        print("Error parsing user data: $e");
        return null;
      }
    }
    return null;
  }

  /// Saves or updates a full UserModel object
  Future<void> saveOrUpdateUser(UserModel newUser) async {
    final db = await database;
    await db.insert(
      _userTable,
      newUser.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes all local user and financial data
  Future<void> clearUserData() async {
    final db = await database;
    await db.delete(_userTable);
    await db.delete(_balanceTable);
    await db.delete(transactionTable);
  }

  /// Checks whether a user session exists
  Future<bool> hasSession() async {
    final db = await database;
    final result = await db.query(_userTable, limit: 1);
    return result.isNotEmpty;
  }

  /// Returns home summary data for dashboard
  Future<Map<String, dynamic>> getHomeData() async {
    final db = await database;

    double balance = 0;
    double totalSpend = 0;
    double totalIncome = 0;
    Map<String, double> categoryTotals = {};

    try {
      // Read current balance
      final balanceResult = await db.query(_balanceTable, limit: 1);
      if (balanceResult.isNotEmpty) {
        balance =
            (balanceResult.first['total_balance'] as num?)?.toDouble() ?? 0;
      }

      // Sum of expenses
      final spendResult = await db.rawQuery('''
        SELECT SUM(amount) as total_spend
        FROM $transactionTable
        WHERE type = 'expense'
      ''');
      if (spendResult.first['total_spend'] != null) {
        totalSpend = (spendResult.first['total_spend'] as num).toDouble();
      }

      // Sum of incomes
      final incomeResult = await db.rawQuery('''
        SELECT SUM(amount) as total_income
        FROM $transactionTable
        WHERE type = 'income'
      ''');
      if (incomeResult.first['total_income'] != null) {
        totalIncome = (incomeResult.first['total_income'] as num).toDouble();
      }

      // Category-wise spend
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

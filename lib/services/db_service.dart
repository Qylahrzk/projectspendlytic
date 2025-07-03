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
}

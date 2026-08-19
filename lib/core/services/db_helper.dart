import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finex.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        type TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL,
        budget REAL NOT NULL,
        spent REAL NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
  }

  // --- Accounts Queries ---

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await database;
    return await db.query('accounts');
  }

  static Future<void> insertAccount(Map<String, dynamic> account) async {
    final db = await database;
    await db.insert(
      'accounts',
      account,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Categories Queries ---

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  static Future<void> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert(
      'categories',
      category,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Backup & Restore Helpers ---

  static Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await database;
    final accounts = await db.query('accounts');
    final categories = await db.query('categories');

    return {
      'accounts': accounts,
      'categories': categories,
    };
  }

  static Future<void> restoreAllData(Map<String, dynamic> data) async {
    final db = await database;
    
    // Wrap in a transaction to guarantee data integrity
    await db.transaction((txn) async {
      await txn.delete('accounts');
      await txn.delete('categories');

      final accounts = data['accounts'] as List<dynamic>?;
      if (accounts != null) {
        for (var acc in accounts) {
          await txn.insert('accounts', Map<String, dynamic>.from(acc));
        }
      }

      final categories = data['categories'] as List<dynamic>?;
      if (categories != null) {
        for (var cat in categories) {
          await txn.insert('categories', Map<String, dynamic>.from(cat));
        }
      }
    });
  }

  static Future<void> clearAllTables() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('accounts');
      await txn.delete('categories');
    });
  }
}

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'security_key_service.dart';

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
        final encryptionKey = await SecurityKeyService.getDatabaseEncryptionKey();

        try {
            final db = await openDatabase(
                path,
                password: encryptionKey,
                version: 4,
                onCreate: _onCreate,
                onUpgrade: _onUpgrade,
                onOpen: (db) async {
                    await db.execute('PRAGMA foreign_keys = ON');
                },
            );
            // Verify access
            await db.rawQuery('SELECT count(*) FROM sqlite_master');
            return db;
        } catch (e) {
            // If encrypted open fails (e.g. existing plaintext database from before encryption),
            // attempt transparent rekeying to encrypt existing database
            try {
                final plainDb = await openDatabase(
                    path,
                    version: 4,
                    onCreate: _onCreate,
                    onUpgrade: _onUpgrade,
                );
                await plainDb.rawQuery("PRAGMA rekey = '$encryptionKey'");
                await plainDb.close();

                final encDb = await openDatabase(
                    path,
                    password: encryptionKey,
                    version: 4,
                    onCreate: _onCreate,
                    onUpgrade: _onUpgrade,
                    onOpen: (db) async {
                        await db.execute('PRAGMA foreign_keys = ON');
                    },
                );
                return encDb;
            } catch (_) {
                // If migration fails due to corrupted/mismatched ciphertext, delete and recreate fresh
                try {
                    await deleteDatabase(path);
                } catch (_) {}

                return await openDatabase(
                    path,
                    password: encryptionKey,
                    version: 4,
                    onCreate: _onCreate,
                    onUpgrade: _onUpgrade,
                    onOpen: (db) async {
                        await db.execute('PRAGMA foreign_keys = ON');
                    },
                );
            }
        }
    }

  static Future<void> _onCreate(Database db, int version) async {
    // Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        type TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
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
        color INTEGER NOT NULL,
        category_type TEXT NOT NULL,
        parent_id TEXT,
        is_essential INTEGER NOT NULL DEFAULT 1,
        is_default INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        flow_direction TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT,
        account_id TEXT NOT NULL,
        transfer_target_account_id TEXT,
        base_currency_amount REAL NOT NULL,
        exchange_rate REAL NOT NULL,
        timestamp TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (transfer_target_account_id) REFERENCES accounts (id) ON DELETE SET NULL
      )
    ''');

    // Transaction Splits Table
    await db.execute('''
      CREATE TABLE transaction_splits (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        flow_direction TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Upgrade categories table to contain category_type and parent_id columns
      await db.execute("ALTER TABLE categories ADD COLUMN category_type TEXT NOT NULL DEFAULT 'EXPENSE'");
      await db.execute("ALTER TABLE categories ADD COLUMN parent_id TEXT REFERENCES categories(id) ON DELETE SET NULL");

      // 2. Create transactions table
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          flow_direction TEXT NOT NULL,
          transaction_type TEXT NOT NULL,
          amount REAL NOT NULL,
          category_id TEXT,
          account_id TEXT NOT NULL,
          transfer_target_account_id TEXT,
          base_currency_amount REAL NOT NULL,
          exchange_rate REAL NOT NULL,
          timestamp TEXT NOT NULL,
          description TEXT,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
          FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
          FOREIGN KEY (transfer_target_account_id) REFERENCES accounts (id) ON DELETE SET NULL
        )
      ''');

      // 3. Create transaction_splits table
      await db.execute('''
        CREATE TABLE transaction_splits (
          id TEXT PRIMARY KEY,
          transaction_id TEXT NOT NULL,
          category_id TEXT NOT NULL,
          amount REAL NOT NULL,
          flow_direction TEXT NOT NULL,
          description TEXT,
          FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute("ALTER TABLE categories ADD COLUMN is_essential INTEGER NOT NULL DEFAULT 1");
      await db.execute("ALTER TABLE categories ADD COLUMN is_default INTEGER NOT NULL DEFAULT 0");
    }

    if (oldVersion < 4) {
      await db.execute("ALTER TABLE accounts ADD COLUMN is_default INTEGER NOT NULL DEFAULT 0");
    }
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

  static Future<void> updateAccount(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'accounts',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> setDefaultAccount(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('accounts', {'is_default': 0});
      await txn.update('accounts', {'is_default': 1}, where: 'id = ?', whereArgs: [id]);
    });
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

  static Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    final db = await database;
    return await db.query(
      'categories',
      where: 'category_type = ?',
      whereArgs: [type],
    );
  }

  static Future<void> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert(
      'categories',
      category,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearDefaultCategory(String categoryType) async {
    final db = await database;
    await db.update(
      'categories',
      {'is_default': 0},
      where: 'category_type = ?',
      whereArgs: [categoryType],
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

  // --- Transactions & Splits Queries (With Balance Reconciliation) ---

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'timestamp DESC');
  }

  static Future<List<Map<String, dynamic>>> getTransactionSplits(String txId) async {
    final db = await database;
    return await db.query(
      'transaction_splits',
      where: 'transaction_id = ?',
      whereArgs: [txId],
    );
  }

  static Future<void> insertTransactionWithReconciliation(
    Map<String, dynamic> tx,
    List<Map<String, dynamic>> splits,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Insert parent transaction
      await txn.insert('transactions', tx, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Insert splits. If empty, create default split referencing parent category
      if (splits.isEmpty) {
        final categoryId = tx['category_id'];
        if (categoryId != null) {
          await txn.insert('transaction_splits', {
            'id': '${tx['id']}_default_split',
            'transaction_id': tx['id'],
            'category_id': categoryId,
            'amount': tx['amount'],
            'flow_direction': tx['flow_direction'],
            'description': tx['description'],
          });
        }
      } else {
        for (var split in splits) {
          await txn.insert('transaction_splits', split, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 3. Reconcile base account balances
      final direction = tx['flow_direction'] as String;
      final amount = tx['amount'] as double;
      final accountId = tx['account_id'] as String;

      if (direction == 'INFLOW') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, accountId],
        );
      } else if (direction == 'OUTFLOW') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [amount, accountId],
        );
      } else if (direction == 'TRANSFER') {
        final targetAccountId = tx['transfer_target_account_id'] as String?;
        if (targetAccountId == null) {
          throw ArgumentError('Transfer target account ID is required for transfer flows.');
        }
        // Deduct from source account
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [amount, accountId],
        );
        // Deposit to target account
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, targetAccountId],
        );
      }
    });
  }

  static Future<void> deleteTransactionWithReconciliation(String txId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Fetch transaction record to get reconciliation details
      final List<Map<String, dynamic>> txList = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [txId],
      );
      if (txList.isEmpty) return;

      final tx = txList.first;
      final direction = tx['flow_direction'] as String;
      final amount = tx['amount'] as double;
      final accountId = tx['account_id'] as String;

      // 2. Revert account balance changes
      if (direction == 'INFLOW') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [amount, accountId],
        );
      } else if (direction == 'OUTFLOW') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, accountId],
        );
      } else if (direction == 'TRANSFER') {
        final targetAccountId = tx['transfer_target_account_id'] as String?;
        if (targetAccountId != null) {
          // Revert: Source gets back, target loses deposit
          await txn.rawUpdate(
            'UPDATE accounts SET balance = balance + ? WHERE id = ?',
            [amount, accountId],
          );
          await txn.rawUpdate(
            'UPDATE accounts SET balance = balance - ? WHERE id = ?',
            [amount, targetAccountId],
          );
        }
      }

      // 3. Delete parent transaction (cascades to splits)
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [txId],
      );
    });
  }

  // --- Analytics Queries ---

  static Future<double> getNetCashFlow(String startTime, String endTime) async {
    final db = await database;

    final inflowResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE flow_direction = 'INFLOW' AND timestamp BETWEEN ? AND ?",
      [startTime, endTime],
    );
    final double inflow = (inflowResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final outflowResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE flow_direction = 'OUTFLOW' AND timestamp BETWEEN ? AND ?",
      [startTime, endTime],
    );
    final double outflow = (outflowResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return inflow - outflow;
  }

  static Future<List<Map<String, dynamic>>> getCategoryBreakdown(String startTime, String endTime) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        c.id as category_id,
        c.name as category_name,
        c.color as category_color,
        c.icon as category_icon,
        c.category_type as category_type,
        SUM(ts.amount) as total_amount
      FROM transaction_splits ts
      JOIN transactions t ON ts.transaction_id = t.id
      JOIN categories c ON ts.category_id = c.id
      WHERE t.timestamp BETWEEN ? AND ? AND t.flow_direction != 'TRANSFER'
      GROUP BY c.id
      ORDER BY total_amount DESC
    ''', [startTime, endTime]);
  }

  // --- Backup & Restore Helpers ---

  static Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await database;
    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final transactionSplits = await db.query('transaction_splits');

    return {
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'transaction_splits': transactionSplits,
    };
  }

  static Future<void> restoreAllData(Map<String, dynamic> data) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete('transaction_splits');
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('accounts');

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

      final transactions = data['transactions'] as List<dynamic>?;
      if (transactions != null) {
        for (var tx in transactions) {
          await txn.insert('transactions', Map<String, dynamic>.from(tx));
        }
      }

      final transactionSplits = data['transaction_splits'] as List<dynamic>?;
      if (transactionSplits != null) {
        for (var split in transactionSplits) {
          await txn.insert('transaction_splits', Map<String, dynamic>.from(split));
        }
      }
    });
  }

  static Future<void> clearAllTables() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transaction_splits');
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('accounts');
    });
  }
}

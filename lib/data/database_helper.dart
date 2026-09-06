import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/store_settings.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('jayaneth_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      path = inMemoryDatabasePath;
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      path = join(dbFolder.path, filePath);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT,
        name TEXT NOT NULL,
        category_id INTEGER,
        retail_price REAL NOT NULL,
        wsale_price REAL,
        cost_price REAL NOT NULL DEFAULT 0.0,
        old_stock_price REAL,
        new_stock_price REAL,
        stock INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        image_base64 TEXT,
        unit TEXT DEFAULT 'pcs',
        stock_batches_json TEXT,
        sync_id TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        sync_id TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sales Table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_no TEXT NOT NULL,
        sale_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        paid_amount REAL DEFAULT 0.0,
        change_amount REAL DEFAULT 0.0,
        items_json TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        cashier_name TEXT,
        device_id TEXT,
        created_at INTEGER NOT NULL,
        sync_id TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Held Bills Table
    await db.execute('''
      CREATE TABLE held_bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_no TEXT NOT NULL,
        sale_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        total REAL NOT NULL,
        items_json TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT,
        cashier_name TEXT,
        device_id TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        total_due REAL DEFAULT 0.0,
        sync_id TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Repairs Table
    await db.execute('''
      CREATE TABLE repairs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_no TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        device_model TEXT NOT NULL,
        issue_description TEXT NOT NULL,
        estimated_cost REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Returns Table
    await db.execute('''
      CREATE TABLE returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_bill_no TEXT NOT NULL,
        returned_items_json TEXT NOT NULL,
        refund_amount REAL NOT NULL,
        reason TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Store Settings Table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        currency TEXT NOT NULL DEFAULT 'Rs.',
        receipt_header TEXT,
        receipt_footer TEXT,
        printer_type TEXT DEFAULT 'system',
        paper_size TEXT DEFAULT '80mm',
        is_dark_mode INTEGER DEFAULT 1,
        admin_pin TEXT DEFAULT '1234',
        low_stock_alert INTEGER DEFAULT 5,
        firebase_rtdb_url TEXT,
        auto_print INTEGER DEFAULT 1
      )
    ''');

    // Insert initial default settings row
    await db.insert('settings', StoreSettings().toMap());
    // NOTE: Zero dummy products or categories inserted as requested by user.
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE products ADD COLUMN old_stock_price REAL");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE products ADD COLUMN new_stock_price REAL");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE products ADD COLUMN image_base64 TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE products ADD COLUMN unit TEXT DEFAULT 'pcs'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE products ADD COLUMN stock_batches_json TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE settings ADD COLUMN admin_pin TEXT DEFAULT '1234'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE settings ADD COLUMN low_stock_alert INTEGER DEFAULT 5");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE settings ADD COLUMN firebase_rtdb_url TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE settings ADD COLUMN auto_print INTEGER DEFAULT 1");
      } catch (_) {}
    }
  }
}

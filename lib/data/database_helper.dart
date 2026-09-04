import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/store_settings.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Cross-platform FFI initialization for Windows/macOS/Linux
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      path = join(dbFolder.path, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
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
        stock INTEGER NOT NULL DEFAULT 0,
        description TEXT
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0
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
        created_at INTEGER NOT NULL
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
        total_due REAL DEFAULT 0.0
      )
    ''');

    // Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
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
        is_dark_mode INTEGER DEFAULT 1
      )
    ''');

    // Seed Initial Demo / Sample Data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Default Settings
    await db.insert('settings', StoreSettings().toMap());

    // Default Categories
    final cat1 = await db.insert('categories', Category(name: 'General', icon: 'tag', color: '#00D4FF').toMap());
    final cat2 = await db.insert('categories', Category(name: 'Electronics', icon: 'smartphone', color: '#6366F1').toMap());
    final cat3 = await db.insert('categories', Category(name: 'Accessories', icon: 'headphones', color: '#10B981').toMap());

    // Default Products
    await db.insert('products', Product(
      barcode: '8901234567890',
      name: 'USB-C Fast Cable 1m',
      categoryId: cat3,
      retailPrice: 850.0,
      wsalePrice: 650.0,
      costPrice: 400.0,
      stock: 45,
      description: 'High quality braided 60W cable',
    ).toMap());

    await db.insert('products', Product(
      barcode: '8901234567891',
      name: 'Wireless Earbuds TWS Pro',
      categoryId: cat2,
      retailPrice: 3500.0,
      wsalePrice: 2800.0,
      costPrice: 2000.0,
      stock: 18,
      description: 'Bluetooth 5.3 earbuds with ENC',
    ).toMap());

    await db.insert('products', Product(
      barcode: '8901234567892',
      name: '20W PD Fast Charger Adapter',
      categoryId: cat2,
      retailPrice: 1650.0,
      wsalePrice: 1300.0,
      costPrice: 850.0,
      stock: 25,
      description: 'Dual port Type-C & USB charger',
    ).toMap());

    await db.insert('products', Product(
      barcode: '8901234567893',
      name: 'Tempered Glass Screen Guard',
      categoryId: cat3,
      retailPrice: 500.0,
      wsalePrice: 300.0,
      costPrice: 150.0,
      stock: 100,
      description: '9H hardness full glue guard',
    ).toMap());

    // Default Customers
    await db.insert('customers', Customer(
      name: 'Kamal Perera',
      phone: '0771234567',
      address: 'Kandy Road, Colombo',
      totalDue: 1500.0,
    ).toMap());

    await db.insert('customers', Customer(
      name: 'Nimal Silva (Wholesale)',
      phone: '0719876543',
      address: 'Main Market, Negombo',
      totalDue: 0.0,
    ).toMap());
  }
}

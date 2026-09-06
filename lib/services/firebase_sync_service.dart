import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../data/database_helper.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/repair_job.dart';

enum SyncStatus { offline, syncing, ok, error }

class FirebaseSyncService {
  static final FirebaseSyncService instance = FirebaseSyncService._internal();
  FirebaseSyncService._internal();

  Timer? _pollTimer;
  bool _isSyncing = false;
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(SyncStatus.offline);
  final ValueNotifier<String> statusMessage = ValueNotifier('Offline');

  void startPeriodicSync(String? firebaseUrl) {
    _pollTimer?.cancel();
    if (firebaseUrl == null || firebaseUrl.trim().isEmpty) {
      syncStatus.value = SyncStatus.offline;
      statusMessage.value = 'Not Configured';
      return;
    }

    // Trigger initial sync immediately
    syncAll(firebaseUrl);

    // Periodic sync every 25 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      syncAll(firebaseUrl);
    });
  }

  void stopPeriodicSync() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Full bi-directional sync: Pull remote data and push pending local changes
  Future<void> syncAll(String rawUrl) async {
    if (_isSyncing) return;
    _isSyncing = true;
    syncStatus.value = SyncStatus.syncing;
    statusMessage.value = 'Syncing...';

    String baseUrl = rawUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    if (baseUrl.endsWith('.json')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5);
    }

    try {
      // 1. Pull data from remote Firebase into local SQLite
      await _pullRemoteData(baseUrl);

      // 2. Push unsynced local data to remote Firebase
      await _pushLocalData(baseUrl);

      syncStatus.value = SyncStatus.ok;
      statusMessage.value = 'Cloud Synced';
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      statusMessage.value = 'Sync Failed: $e';
    } finally {
      _isSyncing = false;
    }
  }

  /// PULL: Fetches categories, items, customers, sales, repairs from Firebase
  Future<void> _pullRemoteData(String baseUrl) async {
    final db = await DatabaseHelper.instance.database;

    // Categories
    try {
      final res = await http.get(Uri.parse('$baseUrl/categories.json')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.body != 'null') {
        final data = jsonDecode(res.body);
        final list = _parseObjectList(data);
        for (var item in list) {
          final cat = Category.fromMap(item);
          final existing = await db.query('categories', where: 'sync_id = ?', whereArgs: [cat.syncId]);
          if (existing.isEmpty) {
            await db.insert('categories', cat.toMap()..['synced'] = 1);
          }
        }
      }
    } catch (_) {}

    // Products / Items
    try {
      final res = await http.get(Uri.parse('$baseUrl/items.json')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.body != 'null') {
        final data = jsonDecode(res.body);
        final list = _parseObjectList(data);
        for (var item in list) {
          final prod = Product.fromMap(item);
          final existing = await db.query('products', where: 'sync_id = ?', whereArgs: [prod.syncId]);
          if (existing.isEmpty) {
            await db.insert('products', prod.toMap()..['synced'] = 1);
          } else {
            // Update existing with cloud data
            await db.update('products', prod.toMap()..['synced'] = 1, where: 'sync_id = ?', whereArgs: [prod.syncId]);
          }
        }
      }
    } catch (_) {}

    // Customers
    try {
      final res = await http.get(Uri.parse('$baseUrl/customers.json')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.body != 'null') {
        final data = jsonDecode(res.body);
        final list = _parseObjectList(data);
        for (var item in list) {
          final cust = Customer.fromMap(item);
          final existing = await db.query('customers', where: 'sync_id = ?', whereArgs: [cust.syncId]);
          if (existing.isEmpty) {
            await db.insert('customers', cust.toMap()..['synced'] = 1);
          } else {
            await db.update('customers', cust.toMap()..['synced'] = 1, where: 'sync_id = ?', whereArgs: [cust.syncId]);
          }
        }
      }
    } catch (_) {}

    // Repairs
    try {
      final res = await http.get(Uri.parse('$baseUrl/repairs.json')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.body != 'null') {
        final data = jsonDecode(res.body);
        final list = _parseObjectList(data);
        for (var item in list) {
          final rep = RepairJob.fromMap(item);
          final existing = await db.query('repairs', where: 'job_no = ?', whereArgs: [rep.jobNo]);
          if (existing.isEmpty) {
            await db.insert('repairs', rep.toMap());
          }
        }
      }
    } catch (_) {}
  }

  /// PUSH: Uploads pending local records (synced == 0) to Firebase
  Future<void> _pushLocalData(String baseUrl) async {
    final db = await DatabaseHelper.instance.database;

    // Unsynced Categories
    final unsyncedCats = await db.query('categories', where: 'synced = 0');
    for (var row in unsyncedCats) {
      final cat = Category.fromMap(row);
      final url = Uri.parse('$baseUrl/categories/${cat.syncId}.json');
      final res = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(cat.toMap()));
      if (res.statusCode == 200) {
        await db.update('categories', {'synced': 1}, where: 'sync_id = ?', whereArgs: [cat.syncId]);
      }
    }

    // Unsynced Products
    final unsyncedProds = await db.query('products', where: 'synced = 0');
    for (var row in unsyncedProds) {
      final prod = Product.fromMap(row);
      final url = Uri.parse('$baseUrl/items/${prod.syncId}.json');
      final res = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(prod.toMap()));
      if (res.statusCode == 200) {
        await db.update('products', {'synced': 1}, where: 'sync_id = ?', whereArgs: [prod.syncId]);
      }
    }

    // Unsynced Customers
    final unsyncedCusts = await db.query('customers', where: 'synced = 0');
    for (var row in unsyncedCusts) {
      final cust = Customer.fromMap(row);
      final url = Uri.parse('$baseUrl/customers/${cust.syncId}.json');
      final res = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(cust.toMap()));
      if (res.statusCode == 200) {
        await db.update('customers', {'synced': 1}, where: 'sync_id = ?', whereArgs: [cust.syncId]);
      }
    }

    // Unsynced Sales
    final unsyncedSales = await db.query('sales', where: 'synced = 0');
    for (var row in unsyncedSales) {
      final sale = Sale.fromMap(row);
      final url = Uri.parse('$baseUrl/sales/${sale.syncId}.json');
      final res = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(sale.toMap()));
      if (res.statusCode == 200) {
        await db.update('sales', {'synced': 1}, where: 'sync_id = ?', whereArgs: [sale.syncId]);
      }
    }
  }

  List<Map<String, dynamic>> _parseObjectList(dynamic data) {
    List<Map<String, dynamic>> result = [];
    if (data is Map) {
      data.forEach((k, v) {
        if (v is Map) {
          final m = Map<String, dynamic>.from(v);
          if (!m.containsKey('sync_id') && !m.containsKey('syncId')) {
            m['sync_id'] = k.toString();
          }
          result.add(m);
        }
      });
    } else if (data is List) {
      for (var v in data) {
        if (v is Map) {
          result.add(Map<String, dynamic>.from(v));
        }
      }
    }
    return result;
  }
}

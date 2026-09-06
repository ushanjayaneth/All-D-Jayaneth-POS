import 'dart:convert';
import '../data/database_helper.dart';

class BackupService {
  /// Exports all tables from local SQLite database into a JSON string
  static Future<String> generateBackupJson() async {
    final db = await DatabaseHelper.instance.database;

    final products = await db.query('products');
    final categories = await db.query('categories');
    final sales = await db.query('sales');
    final heldBills = await db.query('held_bills');
    final customers = await db.query('customers');
    final expenses = await db.query('expenses');
    final repairs = await db.query('repairs');
    final returns = await db.query('returns');
    final settings = await db.query('settings');

    final backupData = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'products': products,
      'categories': categories,
      'sales': sales,
      'heldBills': heldBills,
      'customers': customers,
      'expenses': expenses,
      'repairs': repairs,
      'returns': returns,
      'settings': settings,
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Restores all tables from JSON backup into local SQLite database
  static Future<bool> restoreFromBackupJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      if (data is! Map) return false;

      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // Clear existing tables
        await txn.delete('products');
        await txn.delete('categories');
        await txn.delete('sales');
        await txn.delete('held_bills');
        await txn.delete('customers');
        await txn.delete('expenses');
        await txn.delete('repairs');
        await txn.delete('returns');
        await txn.delete('settings');

        // Insert restored rows
        if (data['products'] is List) {
          for (var p in data['products']) {
            await txn.insert('products', Map<String, dynamic>.from(p));
          }
        }
        if (data['categories'] is List) {
          for (var c in data['categories']) {
            await txn.insert('categories', Map<String, dynamic>.from(c));
          }
        }
        if (data['sales'] is List) {
          for (var s in data['sales']) {
            await txn.insert('sales', Map<String, dynamic>.from(s));
          }
        }
        if (data['heldBills'] is List) {
          for (var h in data['heldBills']) {
            await txn.insert('held_bills', Map<String, dynamic>.from(h));
          }
        }
        if (data['customers'] is List) {
          for (var cu in data['customers']) {
            await txn.insert('customers', Map<String, dynamic>.from(cu));
          }
        }
        if (data['expenses'] is List) {
          for (var e in data['expenses']) {
            await txn.insert('expenses', Map<String, dynamic>.from(e));
          }
        }
        if (data['repairs'] is List) {
          for (var r in data['repairs']) {
            await txn.insert('repairs', Map<String, dynamic>.from(r));
          }
        }
        if (data['returns'] is List) {
          for (var re in data['returns']) {
            await txn.insert('returns', Map<String, dynamic>.from(re));
          }
        }
        if (data['settings'] is List) {
          for (var se in data['settings']) {
            await txn.insert('settings', Map<String, dynamic>.from(se));
          }
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// System Factory Reset: Clears all business data safely
  static Future<void> factoryReset() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('products');
      await txn.delete('categories');
      await txn.delete('sales');
      await txn.delete('held_bills');
      await txn.delete('customers');
      await txn.delete('expenses');
      await txn.delete('repairs');
      await txn.delete('returns');
    });
  }
}

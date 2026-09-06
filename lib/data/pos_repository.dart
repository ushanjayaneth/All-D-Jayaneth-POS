import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/stock_batch.dart';
import '../models/category.dart';
import '../models/sale.dart';
import '../models/held_bill.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/repair_job.dart';
import '../models/return_bill.dart';
import '../models/store_settings.dart';
import 'database_helper.dart';

class PosRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Products
  Future<List<Product>> getProducts() async {
    final db = await _dbHelper.database;
    final res = await db.query('products', orderBy: 'name ASC');
    return res.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProductStock(int productId, double qtyChange, {String? batchId}) async {
    final db = await _dbHelper.database;
    final res = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    if (res.isEmpty) return;

    final prod = Product.fromMap(res.first);
    final batches = List<StockBatch>.from(prod.stockBatches);

    if (batches.isNotEmpty) {
      if (batchId != null) {
        final bIndex = batches.indexWhere((b) => b.batchId == batchId);
        if (bIndex != -1) {
          batches[bIndex].quantity = (batches[bIndex].quantity + qtyChange).clamp(0.0, 999999.0);
        }
      } else {
        // Deduct FIFO
        double remainingToDeduct = -qtyChange;
        for (var b in batches) {
          if (remainingToDeduct <= 0) break;
          if (b.quantity > 0) {
            double used = b.quantity.clamp(0.0, remainingToDeduct);
            b.quantity -= used;
            remainingToDeduct -= used;
          }
        }
      }
    }

    final newStock = (prod.stock + qtyChange.toInt()).clamp(0, 999999);
    await db.update(
      'products',
      {
        'stock': newStock,
        'stock_batches_json': jsonEncode(batches.map((b) => b.toMap()).toList()),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    final res = await db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return res.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Sales
  Future<List<Sale>> getSales({int? startTime, int? endTime}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? args;
    if (startTime != null && endTime != null) {
      where = 'created_at >= ? AND created_at <= ?';
      args = [startTime, endTime];
    }
    final res = await db.query('sales', where: where, whereArgs: args, orderBy: 'created_at DESC');
    return res.map((e) => Sale.fromMap(e)).toList();
  }

  Future<int> insertSale(Sale sale) async {
    final db = await _dbHelper.database;
    final id = await db.insert('sales', sale.toMap());

    // Deduct stock for sold items from their respective batches
    for (var item in sale.items) {
      await updateProductStock(item.productId, -item.qty, batchId: item.batchId);
    }

    // If Loan/Credit sale, update customer due balance
    if ((sale.paymentMethod == 'loan' || sale.paymentMethod == 'credit') && sale.customerId != null) {
      await db.rawUpdate(
        'UPDATE customers SET total_due = total_due + ?, synced = 0 WHERE id = ?',
        [sale.total, sale.customerId],
      );
    }
    return id;
  }

  // Held Bills
  Future<List<HeldBill>> getHeldBills() async {
    final db = await _dbHelper.database;
    final res = await db.query('held_bills', orderBy: 'created_at DESC');
    return res.map((e) => HeldBill.fromMap(e)).toList();
  }

  Future<int> insertHeldBill(HeldBill bill) async {
    final db = await _dbHelper.database;
    return await db.insert('held_bills', bill.toMap());
  }

  Future<int> deleteHeldBill(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('held_bills', where: 'id = ?', whereArgs: [id]);
  }

  // Customers
  Future<List<Customer>> getCustomers() async {
    final db = await _dbHelper.database;
    final res = await db.query('customers', orderBy: 'name ASC');
    return res.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> collectCustomerPayment(int customerId, double amount) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE customers SET total_due = MAX(0.0, total_due - ?), synced = 0 WHERE id = ?',
      [amount, customerId],
    );
  }

  // Expenses
  Future<List<Expense>> getExpenses({int? startTime, int? endTime}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? args;
    if (startTime != null && endTime != null) {
      where = 'created_at >= ? AND created_at <= ?';
      args = [startTime, endTime];
    }
    final res = await db.query('expenses', where: where, whereArgs: args, orderBy: 'created_at DESC');
    return res.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Repairs
  Future<List<RepairJob>> getRepairs() async {
    final db = await _dbHelper.database;
    final res = await db.query('repairs', orderBy: 'created_at DESC');
    return res.map((e) => RepairJob.fromMap(e)).toList();
  }

  Future<int> insertRepair(RepairJob job) async {
    final db = await _dbHelper.database;
    return await db.insert('repairs', job.toMap());
  }

  Future<int> updateRepair(RepairJob job) async {
    final db = await _dbHelper.database;
    return await db.update('repairs', job.toMap(), where: 'id = ?', whereArgs: [job.id]);
  }

  Future<int> deleteRepair(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('repairs', where: 'id = ?', whereArgs: [id]);
  }

  // Returns
  Future<List<ReturnBill>> getReturns() async {
    final db = await _dbHelper.database;
    final res = await db.query('returns', orderBy: 'created_at DESC');
    return res.map((e) => ReturnBill.fromMap(e)).toList();
  }

  Future<int> insertReturn(ReturnBill returnBill) async {
    final db = await _dbHelper.database;
    final id = await db.insert('returns', returnBill.toMap());

    // Replenish stock for returned items
    for (var item in returnBill.returnedItems) {
      await updateProductStock(item.productId, item.qty, batchId: item.batchId);
    }
    return id;
  }

  // Settings
  Future<StoreSettings> getSettings() async {
    final db = await _dbHelper.database;
    final res = await db.query('settings', limit: 1);
    if (res.isNotEmpty) {
      return StoreSettings.fromMap(res.first);
    }
    final defaultSettings = StoreSettings();
    await db.insert('settings', defaultSettings.toMap());
    return defaultSettings;
  }

  Future<int> updateSettings(StoreSettings settings) async {
    final db = await _dbHelper.database;
    return await db.update('settings', settings.toMap(), where: 'id = 1');
  }
}

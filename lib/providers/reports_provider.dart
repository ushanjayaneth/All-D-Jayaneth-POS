import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/day_end_summary.dart';
import '../data/pos_repository.dart';

class ReportsProvider extends ChangeNotifier {
  final PosRepository _repo = PosRepository();

  List<Sale> _sales = [];
  List<Expense> _expenses = [];
  String _timeFilter = 'today'; // 'today', 'this_week', 'this_month', 'all'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = false;

  List<Sale> get sales => _sales;
  List<Expense> get expenses => _expenses;
  String get timeFilter => _timeFilter;
  bool get isLoading => _isLoading;

  double get totalRevenue => _sales.fold(0.0, (sum, s) => sum + s.total);
  double get totalCost => _sales.fold(0.0, (sum, s) => sum + s.totalCost);
  double get grossProfit => totalRevenue - totalCost;
  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get netProfit => grossProfit - totalExpenses;

  // Breakdown by payment
  double get cashSales => _sales.where((s) => s.paymentMethod == 'cash').fold(0.0, (sum, s) => sum + s.total);
  double get cardSales => _sales.where((s) => s.paymentMethod == 'card').fold(0.0, (sum, s) => sum + s.total);
  double get creditSales => _sales.where((s) => s.paymentMethod == 'credit').fold(0.0, (sum, s) => sum + s.total);

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    int? startTime;
    int? endTime;
    final now = DateTime.now();

    if (_timeFilter == 'today') {
      startTime = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      endTime = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    } else if (_timeFilter == 'this_week') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      startTime = DateTime(monday.year, monday.month, monday.day).millisecondsSinceEpoch;
      endTime = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    } else if (_timeFilter == 'this_month') {
      startTime = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      endTime = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    }

    _sales = await _repo.getSales(startTime: startTime, endTime: endTime);
    _expenses = await _repo.getExpenses(startTime: startTime, endTime: endTime);
    _isLoading = false;
    notifyListeners();
  }

  void setTimeFilter(String filter) {
    _timeFilter = filter;
    loadReports();
  }

  Future<void> addExpense(Expense expense) async {
    await _repo.insertExpense(expense);
    await loadReports();
  }

  Future<void> deleteExpense(int id) async {
    await _repo.deleteExpense(id);
    await loadReports();
  }

  DayEndSummary generateDayEndSummary() {
    return DayEndSummary(
      date: DateTime.now(),
      totalBills: _sales.length,
      retailSales: _sales.where((s) => s.saleType == 'retail').fold(0.0, (sum, s) => sum + s.total),
      wholesaleSales: _sales.where((s) => s.saleType == 'wholesale').fold(0.0, (sum, s) => sum + s.total),
      totalSales: totalRevenue,
      cashSales: cashSales,
      cardSales: cardSales,
      creditSales: creditSales,
      totalCost: totalCost,
      grossProfit: grossProfit,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
  }
}

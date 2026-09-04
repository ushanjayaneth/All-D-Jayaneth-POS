import 'package:flutter/material.dart';
import '../models/repair_job.dart';
import '../models/return_bill.dart';
import '../data/pos_repository.dart';

class RepairsProvider extends ChangeNotifier {
  final PosRepository _repo = PosRepository();

  List<RepairJob> _repairs = [];
  List<ReturnBill> _returns = [];
  String _statusFilter = 'all';
  bool _isLoading = false;

  List<RepairJob> get repairs => _repairs;
  List<ReturnBill> get returns => _returns;
  String get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;

  List<RepairJob> get filteredRepairs {
    if (_statusFilter == 'all') return _repairs;
    return _repairs.where((r) => r.status == _statusFilter).toList();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    _repairs = await _repo.getRepairs();
    _returns = await _repo.getReturns();
    _isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<bool> saveRepair(RepairJob job) async {
    if (job.id > 0) {
      await _repo.updateRepair(job);
    } else {
      await _repo.insertRepair(job);
    }
    await loadAll();
    return true;
  }

  Future<bool> updateRepairStatus(int id, String newStatus) async {
    final job = _repairs.firstWhere((r) => r.id == id);
    final updated = job.copyWith(status: newStatus);
    await _repo.updateRepair(updated);
    await loadAll();
    return true;
  }

  Future<bool> deleteRepair(int id) async {
    await _repo.deleteRepair(id);
    await loadAll();
    return true;
  }

  Future<bool> processReturn(ReturnBill returnBill) async {
    await _repo.insertReturn(returnBill);
    await loadAll();
    return true;
  }
}

import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../data/pos_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final PosRepository _repo = PosRepository();

  List<Customer> _customers = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.phone != null && c.phone!.contains(_searchQuery));
    }).toList();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    _customers = await _repo.getCustomers();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> saveCustomer(Customer customer) async {
    if (customer.id != null && customer.id! > 0) {
      await _repo.updateCustomer(customer);
    } else {
      await _repo.insertCustomer(customer);
    }
    await loadCustomers();
    return true;
  }

  Future<bool> deleteCustomer(int id) async {
    await _repo.deleteCustomer(id);
    await loadCustomers();
    return true;
  }

  Future<bool> collectPayment(int customerId, double amount) async {
    await _repo.collectCustomerPayment(customerId, amount);
    await loadCustomers();
    return true;
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../models/held_bill.dart';
import '../models/customer.dart';
import '../data/pos_repository.dart';

class PosProvider extends ChangeNotifier {
  final PosRepository _repo = PosRepository();

  String _saleMode = 'retail'; // 'retail' or 'wholesale'
  List<CartItem> _cartItems = [];
  double _discount = 0.0;
  Customer? _selectedCustomer;
  List<HeldBill> _heldBills = [];
  bool _isLoading = false;

  String get saleMode => _saleMode;
  List<CartItem> get cartItems => _cartItems;
  double get discount => _discount;
  Customer? get selectedCustomer => _selectedCustomer;
  List<HeldBill> get heldBills => _heldBills;
  bool get isLoading => _isLoading;

  int get totalItemCount => _cartItems.fold(0, (sum, item) => sum + item.qty);
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get total => (subtotal - _discount).clamp(0.0, double.infinity);

  void setSaleMode(String mode) {
    if (_saleMode == mode) return;
    _saleMode = mode;
    // Recalculate cart item prices according to mode if possible
    notifyListeners();
  }

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setDiscount(double disc) {
    _discount = disc;
    notifyListeners();
  }

  void addToCart(Product product, {int qty = 1}) {
    final price = (_saleMode == 'wholesale' && product.wsalePrice != null)
        ? product.wsalePrice!
        : product.retailPrice;

    final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id && item.mode == _saleMode);

    if (existingIndex >= 0) {
      _cartItems[existingIndex].qty += qty;
      _cartItems[existingIndex].subtotal = _cartItems[existingIndex].qty * _cartItems[existingIndex].price;
    } else {
      _cartItems.add(CartItem(
        productId: product.id,
        name: product.name,
        price: price,
        costPrice: product.costPrice,
        qty: qty,
        subtotal: price * qty,
        mode: _saleMode,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(int index, int newQty) {
    if (index < 0 || index >= _cartItems.length) return;
    if (newQty <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index].qty = newQty;
      _cartItems[index].subtotal = _cartItems[index].qty * _cartItems[index].price;
    }
    notifyListeners();
  }

  void updateItemPrice(int index, double newPrice) {
    if (index < 0 || index >= _cartItems.length) return;
    _cartItems[index] = CartItem(
      productId: _cartItems[index].productId,
      name: _cartItems[index].name,
      price: newPrice,
      costPrice: _cartItems[index].costPrice,
      qty: _cartItems[index].qty,
      subtotal: newPrice * _cartItems[index].qty,
      mode: _cartItems[index].mode,
    );
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _discount = 0.0;
    _selectedCustomer = null;
    notifyListeners();
  }

  // Generate Unique Bill Number
  String generateBillNo() {
    final now = DateTime.now();
    final formatter = DateFormat('yyMMddHHmmss');
    return 'BILL-${formatter.format(now)}';
  }

  // Finalize Sale
  Future<Sale?> checkout({
    required String paymentMethod,
    double paidAmount = 0.0,
    double changeAmount = 0.0,
    String? cashierName,
  }) async {
    if (_cartItems.isEmpty) return null;

    final billNo = generateBillNo();
    final sale = Sale(
      billNo: billNo,
      saleType: _saleMode,
      subtotal: subtotal,
      discount: _discount,
      total: total,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      items: List.from(_cartItems),
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name,
      cashierName: cashierName ?? 'Cashier',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _repo.insertSale(sale);
    clearCart();
    return sale;
  }

  // Hold Bill
  Future<bool> holdCurrentBill() async {
    if (_cartItems.isEmpty) return false;
    final billNo = generateBillNo();
    final heldBill = HeldBill(
      billNo: billNo,
      saleType: _saleMode,
      subtotal: subtotal,
      discount: _discount,
      total: total,
      items: List.from(_cartItems),
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _repo.insertHeldBill(heldBill);
    clearCart();
    await loadHeldBills();
    return true;
  }

  Future<void> loadHeldBills() async {
    _heldBills = await _repo.getHeldBills();
    notifyListeners();
  }

  Future<void> restoreHeldBill(HeldBill bill) async {
    _cartItems = List.from(bill.items);
    _discount = bill.discount;
    _saleMode = bill.saleType;
    if (bill.customerId != null) {
      _selectedCustomer = Customer(
        id: bill.customerId!,
        name: bill.customerName ?? '',
      );
    }
    await _repo.deleteHeldBill(bill.id);
    await loadHeldBills();
    notifyListeners();
  }

  Future<void> deleteHeldBill(int id) async {
    await _repo.deleteHeldBill(id);
    await loadHeldBills();
  }
}

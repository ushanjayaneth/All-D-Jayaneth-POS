import 'package:flutter/material.dart';
import '../data/pos_repository.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../models/held_bill.dart';
import '../models/customer.dart';
import '../models/device_info.dart';
import '../services/firebase_sync_service.dart';

class PosProvider extends ChangeNotifier {
  final PosRepository _repository = PosRepository();

  String selectedSaleMode = 'retail'; // 'retail' or 'wholesale'
  int? selectedCategoryId;
  String searchQuery = '';

  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  double discountValue = 0.0;
  String discountType = 'a'; // 'a' = amount, 'p' = percentage

  Customer? selectedCustomer;
  DeviceInfo? currentDeviceInfo;

  List<HeldBill> heldBills = [];

  bool isLicenseBlocked = false;
  String lockReason = 'NONE'; // 'NONE', 'BLOCKED', 'OFFLINE_EXPIRED'

  PosProvider() {
    loadDeviceInfo();
    loadHeldBills();
  }

  Future<void> loadDeviceInfo() async {
    final settings = await _repository.getSettings();
    currentDeviceInfo = DeviceInfo(
      id: 'DEV_${(settings.storeName.hashCode.abs() % 10000).toString().padLeft(4, '0')}',
      cashier: 'Cashier 1',
      devName: 'Counter A',
      store: settings.storeName,
    );
    notifyListeners();
  }

  void updateDeviceInfo(DeviceInfo info) {
    currentDeviceInfo = info;
    notifyListeners();
  }

  void setSaleMode(String mode) {
    selectedSaleMode = mode;
    // Update existing items in cart to match mode price
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    selectedCustomer = customer;
    notifyListeners();
  }

  void setDiscount(double value, String type) {
    discountValue = value;
    discountType = type;
    notifyListeners();
  }

  // ===== CART ACTIONS =====
  void addToCart(
    Product product, {
    double? customPrice,
    String? batchId,
    String? batchLabel,
  }) {
    final price = customPrice ??
        (selectedSaleMode == 'wholesale'
            ? (product.wsalePrice ?? product.retailPrice)
            : product.retailPrice);

    final existingIndex = _cartItems.indexWhere(
      (c) => c.productId == product.id && c.mode == selectedSaleMode && c.batchId == batchId,
    );

    if (existingIndex != -1) {
      _cartItems[existingIndex].qty += 1;
      _cartItems[existingIndex].subtotal = _cartItems[existingIndex].qty * _cartItems[existingIndex].price;
    } else {
      _cartItems.add(
        CartItem(
          productId: product.id ?? 0,
          name: product.name,
          price: price,
          costPrice: product.costPrice,
          qty: 1,
          subtotal: price,
          mode: selectedSaleMode,
          batchId: batchId,
          batchLabel: batchLabel,
          imageBase64: product.imageBase64,
        ),
      );
    }
    notifyListeners();
  }

  void updateItemQty(int index, double delta) {
    if (index >= 0 && index < _cartItems.length) {
      final newQty = _cartItems[index].qty + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].qty = newQty;
        _cartItems[index].subtotal = newQty * _cartItems[index].price;
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    discountValue = 0.0;
    selectedCustomer = null;
    notifyListeners();
  }

  double get cartSubtotal {
    return _cartItems.fold<double>(0.0, (sum, item) => sum + item.subtotal);
  }

  double get cartDiscount {
    final sub = cartSubtotal;
    if (discountType == 'p') {
      return (sub * (discountValue / 100.0)).clamp(0.0, sub);
    }
    return discountValue.clamp(0.0, sub);
  }

  double get cartTotal {
    return (cartSubtotal - cartDiscount).clamp(0.0, 9999999.0);
  }

  int get cartItemCount {
    return _cartItems.fold<int>(0, (sum, i) => sum + i.qty.toInt());
  }

  // ===== SALE COMPLETE =====
  Future<Sale?> checkout({
    required String paymentMethod,
    required double paidAmount,
    double changeAmount = 0.0,
  }) async {
    return completeSale(paidAmount: paidAmount, paymentMethod: paymentMethod);
  }

  Future<Sale?> completeSale({
    required double paidAmount,
    required String paymentMethod,
  }) async {
    if (_cartItems.isEmpty) return null;

    final total = cartTotal;
    final change = paymentMethod == 'cash' ? (paidAmount - total).clamp(0.0, 9999999.0) : 0.0;
    final billNo = 'B${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final sale = Sale(
      billNo: billNo,
      saleType: selectedSaleMode,
      subtotal: cartSubtotal,
      discount: cartDiscount,
      total: total,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: change,
      items: List.from(_cartItems),
      customerId: selectedCustomer?.id,
      customerName: selectedCustomer?.name,
      cashierName: currentDeviceInfo?.cashier ?? 'Cashier 1',
      deviceId: currentDeviceInfo?.id,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final insertedId = await _repository.insertSale(sale);
    final completedSale = Sale.fromMap(sale.toMap()..['id'] = insertedId);

    clearCart();

    // Trigger cloud sync in background if configured
    final settings = await _repository.getSettings();
    if (settings.firebaseRtdbUrl != null && settings.firebaseRtdbUrl!.isNotEmpty) {
      FirebaseSyncService.instance.syncAll(settings.firebaseRtdbUrl!);
    }

    return completedSale;
  }

  // ===== HELD BILLS =====
  Future<void> loadHeldBills() async {
    heldBills = await _repository.getHeldBills();
    notifyListeners();
  }

  Future<void> holdCurrentBill() async {
    if (_cartItems.isEmpty) return;

    final billNo = 'H${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final heldBill = HeldBill(
      billNo: billNo,
      saleType: selectedSaleMode,
      subtotal: cartSubtotal,
      discount: cartDiscount,
      total: cartTotal,
      items: List.from(_cartItems),
      customerId: selectedCustomer?.id,
      customerName: selectedCustomer?.name,
      cashierName: currentDeviceInfo?.cashier,
      deviceId: currentDeviceInfo?.id,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _repository.insertHeldBill(heldBill);
    clearCart();
    await loadHeldBills();
  }

  Future<void> resumeHeldBill(HeldBill bill) async {
    clearCart();
    selectedSaleMode = bill.saleType;
    _cartItems.addAll(bill.items);
    discountValue = bill.discount;
    discountType = 'a';

    await _repository.deleteHeldBill(bill.id!);
    await loadHeldBills();
    notifyListeners();
  }

  Future<void> deleteHeldBill(int id) async {
    await _repository.deleteHeldBill(id);
    await loadHeldBills();
  }

  // ===== LICENSE / MASTER PIN =====
  void setLicenseBlocked(bool blocked, {String reason = 'BLOCKED'}) {
    isLicenseBlocked = blocked;
    lockReason = blocked ? reason : 'NONE';
    notifyListeners();
  }

  bool unlockWithPin(String pin) {
    if (pin == '9999') {
      isLicenseBlocked = false;
      lockReason = 'NONE';
      notifyListeners();
      return true;
    }
    return false;
  }
}

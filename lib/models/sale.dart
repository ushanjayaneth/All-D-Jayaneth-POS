import 'dart:convert';
import 'cart_item.dart';

class Sale {
  final int id;
  final String billNo;
  final String saleType; // 'retail' or 'wholesale'
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod; // 'cash', 'card', 'credit'
  final double paidAmount;
  final double changeAmount;
  final List<CartItem> items;
  final int? customerId;
  final String? customerName;
  final String? cashierName;
  final int createdAt;

  Sale({
    this.id = 0,
    required this.billNo,
    required this.saleType,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.paidAmount = 0.0,
    this.changeAmount = 0.0,
    required this.items,
    this.customerId,
    this.customerName,
    this.cashierName,
    required this.createdAt,
  });

  double get totalCost => items.fold(0.0, (sum, item) => sum + (item.costPrice * item.qty));
  double get profit => total - totalCost;

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'bill_no': billNo,
      'sale_type': saleType,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'items_json': jsonEncode(items.map((e) => e.toMap()).toList()),
      'customer_id': customerId,
      'customer_name': customerName,
      'cashier_name': cashierName,
      'created_at': createdAt,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    List<CartItem> parsedItems = [];
    if (map['items_json'] != null) {
      try {
        final List<dynamic> list = jsonDecode(map['items_json']);
        parsedItems = list.map((item) => CartItem.fromMap(item)).toList();
      } catch (_) {}
    }

    return Sale(
      id: map['id'] ?? 0,
      billNo: map['bill_no'] ?? '',
      saleType: map['sale_type'] ?? 'retail',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] ?? 'cash',
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      items: parsedItems,
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      cashierName: map['cashier_name'],
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

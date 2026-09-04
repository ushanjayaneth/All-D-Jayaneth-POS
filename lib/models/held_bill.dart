import 'dart:convert';
import 'cart_item.dart';

class HeldBill {
  final int id;
  final String billNo;
  final String saleType;
  final double subtotal;
  final double discount;
  final double total;
  final List<CartItem> items;
  final int? customerId;
  final String? customerName;
  final int createdAt;

  HeldBill({
    this.id = 0,
    required this.billNo,
    required this.saleType,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    required this.items,
    this.customerId,
    this.customerName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'bill_no': billNo,
      'sale_type': saleType,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'items_json': jsonEncode(items.map((e) => e.toMap()).toList()),
      'customer_id': customerId,
      'customer_name': customerName,
      'created_at': createdAt,
    };
  }

  factory HeldBill.fromMap(Map<String, dynamic> map) {
    List<CartItem> parsedItems = [];
    if (map['items_json'] != null) {
      try {
        final List<dynamic> list = jsonDecode(map['items_json']);
        parsedItems = list.map((item) => CartItem.fromMap(item)).toList();
      } catch (_) {}
    }
    return HeldBill(
      id: map['id'] ?? 0,
      billNo: map['bill_no'] ?? '',
      saleType: map['sale_type'] ?? 'retail',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      items: parsedItems,
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

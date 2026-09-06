import 'dart:convert';
import 'cart_item.dart';

class HeldBill {
  final int? id;
  final String billNo;
  final String saleType;
  final double subtotal;
  final double discount;
  final double total;
  final List<CartItem> items;
  final int? customerId;
  final String? customerName;
  final String? cashierName;
  final String? deviceId;
  final int createdAt;

  HeldBill({
    this.id,
    required this.billNo,
    required this.saleType,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    required this.items,
    this.customerId,
    this.customerName,
    this.cashierName,
    this.deviceId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_no': billNo,
      'sale_type': saleType,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
      'customer_id': customerId,
      'customer_name': customerName,
      'cashier_name': cashierName,
      'device_id': deviceId,
      'created_at': createdAt,
    };
  }

  factory HeldBill.fromMap(Map<String, dynamic> map) {
    List<CartItem> itemList = [];
    if (map['items_json'] != null) {
      try {
        final decoded = jsonDecode(map['items_json'].toString());
        if (decoded is List) {
          itemList = decoded.map((e) => CartItem.fromMap(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    } else if (map['items'] != null && map['items'] is List) {
      itemList = (map['items'] as List).map((e) => CartItem.fromMap(e as Map<String, dynamic>)).toList();
    }

    return HeldBill(
      id: map['id'] as int?,
      billNo: map['bill_no']?.toString() ?? map['billNo']?.toString() ?? '',
      saleType: map['sale_type']?.toString() ?? map['saleType']?.toString() ?? 'retail',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      items: itemList,
      customerId: map['customer_id'] as int? ?? map['customerId'] as int?,
      customerName: map['customer_name']?.toString() ?? map['customerName']?.toString(),
      cashierName: map['cashier_name']?.toString() ?? map['cashierName']?.toString(),
      deviceId: map['device_id']?.toString() ?? map['deviceId']?.toString(),
      createdAt: (map['created_at'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

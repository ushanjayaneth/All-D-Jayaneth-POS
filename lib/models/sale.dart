import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'cart_item.dart';

class Sale {
  final int? id;
  final String billNo;
  final String saleType; // 'retail', 'wholesale', 'loan'
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod; // 'cash', 'card', 'loan'
  final double? paidAmount;
  final double? changeAmount;
  final List<CartItem> items;
  final int? customerId;
  final String? customerName;
  final String? cashierName;
  final String? deviceId;
  final int createdAt;
  final String syncId;
  final int synced;

  Sale({
    this.id,
    required this.billNo,
    required this.saleType,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.paidAmount,
    this.changeAmount,
    required this.items,
    this.customerId,
    this.customerName,
    this.cashierName,
    this.deviceId,
    required this.createdAt,
    String? syncId,
    this.synced = 0,
  }) : syncId = syncId ?? const Uuid().v4();

  double get costTotal {
    return items.fold<double>(0.0, (sum, i) => sum + (i.costPrice * i.qty));
  }

  double get totalCost => costTotal;
  double get profit => total - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_no': billNo,
      'sale_type': saleType,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
      'customer_id': customerId,
      'customer_name': customerName,
      'cashier_name': cashierName,
      'device_id': deviceId,
      'created_at': createdAt,
      'sync_id': syncId,
      'synced': synced,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
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

    return Sale(
      id: map['id'] as int?,
      billNo: map['bill_no']?.toString() ?? map['billNo']?.toString() ?? '',
      saleType: map['sale_type']?.toString() ?? map['saleType']?.toString() ?? 'retail',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method']?.toString() ?? map['paymentMethod']?.toString() ?? 'cash',
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? (map['paidAmount'] as num?)?.toDouble(),
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? (map['changeAmount'] as num?)?.toDouble(),
      items: itemList,
      customerId: map['customer_id'] as int? ?? map['customerId'] as int?,
      customerName: map['customer_name']?.toString() ?? map['customerName']?.toString(),
      cashierName: map['cashier_name']?.toString() ?? map['cashierName']?.toString(),
      deviceId: map['device_id']?.toString() ?? map['deviceId']?.toString(),
      createdAt: (map['created_at'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      syncId: map['sync_id']?.toString() ?? map['syncId']?.toString() ?? const Uuid().v4(),
      synced: (map['synced'] as int?) ?? 0,
    );
  }
}

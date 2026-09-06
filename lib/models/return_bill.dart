import 'dart:convert';
import 'cart_item.dart';

class ReturnBill {
  final int? id;
  final String saleBillNo;
  final List<CartItem> returnedItems;
  final double refundAmount;
  final String? reason;
  final int createdAt;

  ReturnBill({
    this.id,
    required this.saleBillNo,
    required this.returnedItems,
    required this.refundAmount,
    this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_bill_no': saleBillNo,
      'returned_items_json': jsonEncode(returnedItems.map((i) => i.toMap()).toList()),
      'refund_amount': refundAmount,
      'reason': reason,
      'created_at': createdAt,
    };
  }

  factory ReturnBill.fromMap(Map<String, dynamic> map) {
    List<CartItem> items = [];
    if (map['returned_items_json'] != null) {
      try {
        final decoded = jsonDecode(map['returned_items_json'].toString());
        if (decoded is List) {
          items = decoded.map((e) => CartItem.fromMap(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    return ReturnBill(
      id: map['id'] as int?,
      saleBillNo: map['sale_bill_no']?.toString() ?? map['saleBillNo']?.toString() ?? '',
      returnedItems: items,
      refundAmount: (map['refund_amount'] as num?)?.toDouble() ?? (map['refundAmount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason']?.toString(),
      createdAt: (map['created_at'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

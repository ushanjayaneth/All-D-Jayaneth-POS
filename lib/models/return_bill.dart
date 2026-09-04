import 'dart:convert';
import 'cart_item.dart';

class ReturnBill {
  final int id;
  final String saleBillNo;
  final List<CartItem> returnedItems;
  final double refundAmount;
  final String? reason;
  final int createdAt;

  ReturnBill({
    this.id = 0,
    required this.saleBillNo,
    required this.returnedItems,
    required this.refundAmount,
    this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'sale_bill_no': saleBillNo,
      'returned_items_json': jsonEncode(returnedItems.map((e) => e.toMap()).toList()),
      'refund_amount': refundAmount,
      'reason': reason,
      'created_at': createdAt,
    };
  }

  factory ReturnBill.fromMap(Map<String, dynamic> map) {
    List<CartItem> parsedItems = [];
    if (map['returned_items_json'] != null) {
      try {
        final List<dynamic> list = jsonDecode(map['returned_items_json']);
        parsedItems = list.map((item) => CartItem.fromMap(item)).toList();
      } catch (_) {}
    }
    return ReturnBill(
      id: map['id'] ?? 0,
      saleBillNo: map['sale_bill_no'] ?? '',
      returnedItems: parsedItems,
      refundAmount: (map['refund_amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'],
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

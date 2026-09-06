import 'package:uuid/uuid.dart';

class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double totalDue;
  final String syncId;
  final int synced;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.totalDue = 0.0,
    String? syncId,
    this.synced = 0,
  }) : syncId = syncId ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'total_due': totalDue,
      'sync_id': syncId,
      'synced': synced,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      totalDue: (map['total_due'] as num?)?.toDouble() ?? (map['totalDue'] as num?)?.toDouble() ?? 0.0,
      syncId: map['sync_id']?.toString() ?? map['syncId']?.toString() ?? const Uuid().v4(),
      synced: (map['synced'] as int?) ?? 0,
    );
  }
}

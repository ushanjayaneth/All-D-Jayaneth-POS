class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final double totalDue;

  Customer({
    this.id = 0,
    required this.name,
    this.phone,
    this.address,
    this.totalDue = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'total_due': totalDue,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      phone: map['phone'],
      address: map['address'],
      totalDue: (map['total_due'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? totalDue,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalDue: totalDue ?? this.totalDue,
    );
  }
}

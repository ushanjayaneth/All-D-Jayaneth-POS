class DeviceInfo {
  final String id;
  final String cashier;
  final String devName;
  final String store;

  DeviceInfo({
    required this.id,
    required this.cashier,
    required this.devName,
    required this.store,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cashier': cashier,
      'devName': devName,
      'store': store,
    };
  }

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      id: map['id']?.toString() ?? 'dev_1',
      cashier: map['cashier']?.toString() ?? 'Cashier 1',
      devName: map['devName']?.toString() ?? map['dev_name']?.toString() ?? 'Counter A',
      store: map['store']?.toString() ?? map['store_name']?.toString() ?? 'Jayaneth Mobile',
    );
  }
}

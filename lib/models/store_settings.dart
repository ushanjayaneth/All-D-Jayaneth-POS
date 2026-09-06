class StoreSettings {
  final int? id;
  final String storeName;
  final String address;
  final String phone;
  final String currency;
  final String receiptHeader;
  final String receiptFooter;
  final String printerType; // 'system', 'bluetooth', 'usb', 'network'
  final String paperSize; // '58mm', '80mm'
  final bool isDarkMode;
  final String adminPin;
  final int lowStockAlert;
  final String? firebaseRtdbUrl;
  final bool autoPrint;

  StoreSettings({
    this.id,
    this.storeName = 'Jayaneth Mobile',
    this.address = 'No 12, Main Street, Colombo',
    this.phone = '077 123 4567',
    this.currency = 'Rs.',
    this.receiptHeader = 'WELCOME TO JAYANETH MOBILE',
    this.receiptFooter = 'Thank you for shopping with us! Come again!',
    this.printerType = 'system',
    this.paperSize = '80mm',
    this.isDarkMode = true,
    this.adminPin = '1234',
    this.lowStockAlert = 5,
    this.firebaseRtdbUrl,
    this.autoPrint = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_name': storeName,
      'address': address,
      'phone': phone,
      'currency': currency,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'printer_type': printerType,
      'paper_size': paperSize,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'admin_pin': adminPin,
      'low_stock_alert': lowStockAlert,
      'firebase_rtdb_url': firebaseRtdbUrl,
      'auto_print': autoPrint ? 1 : 0,
    };
  }

  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      id: map['id'] as int?,
      storeName: map['store_name']?.toString() ?? map['shopName']?.toString() ?? 'Jayaneth Mobile',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'Rs.',
      receiptHeader: map['receipt_header']?.toString() ?? 'WELCOME TO JAYANETH MOBILE',
      receiptFooter: map['receipt_footer']?.toString() ?? map['receiptNote']?.toString() ?? 'Thank you! Come again!',
      printerType: map['printer_type']?.toString() ?? 'system',
      paperSize: map['paper_size']?.toString() ?? '80mm',
      isDarkMode: (map['is_dark_mode'] as int?) != 0,
      adminPin: map['admin_pin']?.toString() ?? map['adminPin']?.toString() ?? '1234',
      lowStockAlert: (map['low_stock_alert'] as num?)?.toInt() ?? (map['lowStockAlert'] as num?)?.toInt() ?? 5,
      firebaseRtdbUrl: map['firebase_rtdb_url']?.toString() ?? map['firebaseUrl']?.toString(),
      autoPrint: (map['auto_print'] as int?) != 0,
    );
  }

  StoreSettings copyWith({
    int? id,
    String? storeName,
    String? address,
    String? phone,
    String? currency,
    String? receiptHeader,
    String? receiptFooter,
    String? printerType,
    String? paperSize,
    bool? isDarkMode,
    String? adminPin,
    int? lowStockAlert,
    String? firebaseRtdbUrl,
    bool? autoPrint,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      printerType: printerType ?? this.printerType,
      paperSize: paperSize ?? this.paperSize,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      adminPin: adminPin ?? this.adminPin,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      firebaseRtdbUrl: firebaseRtdbUrl ?? this.firebaseRtdbUrl,
      autoPrint: autoPrint ?? this.autoPrint,
    );
  }
}

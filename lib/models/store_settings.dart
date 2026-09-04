class StoreSettings {
  final String storeName;
  final String address;
  final String phone;
  final String currency;
  final String receiptHeader;
  final String receiptFooter;
  final String printerType; // 'bluetooth', 'usb', 'network', 'system'
  final String paperSize; // '58mm', '72mm', '80mm'
  final bool isDarkMode;

  StoreSettings({
    this.storeName = 'Jayaneth Demo POS',
    this.address = 'No. 123, Main Street, Colombo',
    this.phone = '0771234567',
    this.currency = 'Rs.',
    this.receiptHeader = 'Thank you for shopping with us!',
    this.receiptFooter = 'Goods once sold cannot be returned without receipt.',
    this.printerType = 'system',
    this.paperSize = '80mm',
    this.isDarkMode = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'store_name': storeName,
      'address': address,
      'phone': phone,
      'currency': currency,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'printer_type': printerType,
      'paper_size': paperSize,
      'is_dark_mode': isDarkMode ? 1 : 0,
    };
  }

  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      storeName: map['store_name'] ?? 'Jayaneth Demo POS',
      address: map['address'] ?? 'No. 123, Main Street, Colombo',
      phone: map['phone'] ?? '0771234567',
      currency: map['currency'] ?? 'Rs.',
      receiptHeader: map['receipt_header'] ?? 'Thank you for shopping with us!',
      receiptFooter: map['receipt_footer'] ?? 'Goods once sold cannot be returned without receipt.',
      printerType: map['printer_type'] ?? 'system',
      paperSize: map['paper_size'] ?? '80mm',
      isDarkMode: (map['is_dark_mode'] ?? 1) == 1,
    );
  }

  StoreSettings copyWith({
    String? storeName,
    String? address,
    String? phone,
    String? currency,
    String? receiptHeader,
    String? receiptFooter,
    String? printerType,
    String? paperSize,
    bool? isDarkMode,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      printerType: printerType ?? this.printerType,
      paperSize: paperSize ?? this.paperSize,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

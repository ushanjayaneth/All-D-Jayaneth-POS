class CartItem {
  final int productId;
  final String name;
  double price;
  final double costPrice;
  double qty;
  double subtotal;
  String mode; // 'retail', 'wholesale', 'loan'
  String? batchId;
  String? batchLabel; // e.g. 'Old Stock' or 'New Stock'
  String? imageBase64;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.costPrice = 0.0,
    double? qty,
    double? quantity,
    double? subtotal,
    this.mode = 'retail',
    this.batchId,
    this.batchLabel,
    this.imageBase64,
  })  : qty = qty ?? quantity ?? 1.0,
        subtotal = subtotal ?? (price * (qty ?? quantity ?? 1.0));

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'costPrice': costPrice,
      'qty': qty,
      'subtotal': subtotal,
      'mode': mode,
      'batchId': batchId,
      'batchLabel': batchLabel,
      'imageBase64': imageBase64,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: (map['productId'] as num?)?.toInt() ?? (map['itemId'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      qty: (map['qty'] as num?)?.toDouble() ?? 1.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      mode: map['mode']?.toString() ?? map['saleMode']?.toString() ?? 'retail',
      batchId: map['batchId']?.toString(),
      batchLabel: map['batchLabel']?.toString(),
      imageBase64: map['imageBase64']?.toString(),
    );
  }
}

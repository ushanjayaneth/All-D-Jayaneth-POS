class CartItem {
  final int productId;
  final String name;
  final double price;
  final double costPrice;
  int qty;
  double subtotal;
  final String mode; // 'retail' or 'wholesale'

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.costPrice = 0.0,
    this.qty = 1,
    required this.subtotal,
    this.mode = 'retail',
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'qty': qty,
      'subtotal': subtotal,
      'mode': mode,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['product_id'] ?? 0,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      qty: map['qty'] ?? 1,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      mode: map['mode'] ?? 'retail',
    );
  }
}

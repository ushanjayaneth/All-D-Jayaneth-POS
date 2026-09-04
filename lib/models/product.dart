class Product {
  final int id;
  final String? barcode;
  final String name;
  final int? categoryId;
  final double retailPrice;
  final double? wsalePrice;
  final double costPrice;
  final int stock;
  final String? description;

  Product({
    this.id = 0,
    this.barcode,
    required this.name,
    this.categoryId,
    required this.retailPrice,
    this.wsalePrice,
    this.costPrice = 0.0,
    this.stock = 0,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'barcode': barcode,
      'name': name,
      'category_id': categoryId,
      'retail_price': retailPrice,
      'wsale_price': wsalePrice,
      'cost_price': costPrice,
      'stock': stock,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? 0,
      barcode: map['barcode'],
      name: map['name'] ?? '',
      categoryId: map['category_id'],
      retailPrice: (map['retail_price'] as num?)?.toDouble() ?? 0.0,
      wsalePrice: (map['wsale_price'] as num?)?.toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] ?? 0,
      description: map['description'],
    );
  }

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    int? categoryId,
    double? retailPrice,
    double? wsalePrice,
    double? costPrice,
    int? stock,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      retailPrice: retailPrice ?? this.retailPrice,
      wsalePrice: wsalePrice ?? this.wsalePrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      description: description ?? this.description,
    );
  }
}

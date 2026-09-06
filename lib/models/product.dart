import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'stock_batch.dart';

class Product {
  final int? id;
  final String? barcode;
  final String name;
  final int? categoryId;
  final double retailPrice;
  final double? wsalePrice;
  final double costPrice;
  final double? oldStockPrice;
  final double? newStockPrice;
  final int stock;
  final String? description;
  final String? imageBase64;
  final String unit;
  final List<StockBatch> stockBatches;
  final String syncId;
  final int synced;

  Product({
    this.id,
    this.barcode,
    required this.name,
    this.categoryId,
    required this.retailPrice,
    this.wsalePrice,
    this.costPrice = 0.0,
    this.oldStockPrice,
    this.newStockPrice,
    this.stock = 0,
    this.description,
    this.imageBase64,
    this.unit = 'pcs',
    List<StockBatch>? stockBatches,
    String? syncId,
    this.synced = 0,
  })  : stockBatches = stockBatches ?? [],
        syncId = syncId ?? const Uuid().v4();

  // Computes total stock from batches if batches exist, otherwise returns stock
  double get totalStock {
    if (stockBatches.isNotEmpty) {
      return stockBatches.fold<double>(0.0, (sum, b) => sum + b.quantity);
    }
    return stock.toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'category_id': categoryId,
      'retail_price': retailPrice,
      'wsale_price': wsalePrice,
      'cost_price': costPrice,
      'old_stock_price': oldStockPrice,
      'new_stock_price': newStockPrice,
      'stock': stock,
      'description': description,
      'image_base64': imageBase64,
      'unit': unit,
      'stock_batches_json': jsonEncode(stockBatches.map((b) => b.toMap()).toList()),
      'sync_id': syncId,
      'synced': synced,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    List<StockBatch> batches = [];
    if (map['stock_batches_json'] != null && map['stock_batches_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['stock_batches_json'].toString());
        if (decoded is List) {
          batches = decoded.map((e) => StockBatch.fromMap(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    } else if (map['stockBatches'] != null) {
      try {
        final bList = map['stockBatches'];
        if (bList is List) {
          batches = bList.map((e) => StockBatch.fromMap(e as Map<String, dynamic>)).toList();
        } else if (bList is Map) {
          batches = bList.values.map((e) => StockBatch.fromMap(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    return Product(
      id: map['id'] as int?,
      barcode: map['barcode']?.toString(),
      name: map['name']?.toString() ?? '',
      categoryId: map['category_id'] as int? ?? map['categoryId'] as int?,
      retailPrice: (map['retail_price'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? (map['retailPrice'] as num?)?.toDouble() ?? 0.0,
      wsalePrice: (map['wsale_price'] as num?)?.toDouble() ?? (map['wholesalePrice'] as num?)?.toDouble() ?? (map['wsalePrice'] as num?)?.toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      oldStockPrice: (map['old_stock_price'] as num?)?.toDouble() ?? (map['oldPrice'] as num?)?.toDouble(),
      newStockPrice: (map['new_stock_price'] as num?)?.toDouble() ?? (map['newPrice'] as num?)?.toDouble(),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      description: map['description']?.toString(),
      imageBase64: map['image_base64']?.toString() ?? map['image']?.toString(),
      unit: map['unit']?.toString() ?? 'pcs',
      stockBatches: batches,
      syncId: map['sync_id']?.toString() ?? map['syncId']?.toString() ?? const Uuid().v4(),
      synced: (map['synced'] as int?) ?? 0,
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
    double? oldStockPrice,
    double? newStockPrice,
    int? stock,
    String? description,
    String? imageBase64,
    String? unit,
    List<StockBatch>? stockBatches,
    String? syncId,
    int? synced,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      retailPrice: retailPrice ?? this.retailPrice,
      wsalePrice: wsalePrice ?? this.wsalePrice,
      costPrice: costPrice ?? this.costPrice,
      oldStockPrice: oldStockPrice ?? this.oldStockPrice,
      newStockPrice: newStockPrice ?? this.newStockPrice,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      imageBase64: imageBase64 ?? this.imageBase64,
      unit: unit ?? this.unit,
      stockBatches: stockBatches ?? this.stockBatches,
      syncId: syncId ?? this.syncId,
      synced: synced ?? this.synced,
    );
  }
}

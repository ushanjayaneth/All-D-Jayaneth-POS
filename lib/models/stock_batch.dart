class StockBatch {
  final String batchId;
  double quantity;
  final double costPrice;
  final double? sellingPrice;
  final String dateAdded;
  final List<String> barcodes;

  StockBatch({
    required this.batchId,
    required this.quantity,
    required this.costPrice,
    this.sellingPrice,
    required this.dateAdded,
    this.barcodes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'dateAdded': dateAdded,
      'barcodes': barcodes,
    };
  }

  factory StockBatch.fromMap(Map<String, dynamic> map) {
    List<String> bcs = [];
    if (map['barcodes'] != null) {
      if (map['barcodes'] is List) {
        bcs = List<String>.from(map['barcodes']);
      }
    }
    return StockBatch(
      batchId: map['batchId']?.toString() ?? 'b_${DateTime.now().millisecondsSinceEpoch}',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble(),
      dateAdded: map['dateAdded']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      barcodes: bcs,
    );
  }
}

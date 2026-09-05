import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sale.dart';
import '../models/product.dart';

class CsvExportService {
  static Future<String> exportSalesToCsv(List<Sale> sales) async {
    List<List<dynamic>> rows = [];
    rows.add([
      'Bill No',
      'Date & Time',
      'Type',
      'Subtotal',
      'Discount',
      'Total',
      'Total Cost',
      'Profit',
      'Payment Method',
      'Customer',
      'Items Count'
    ]);

    for (var sale in sales) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(sale.createdAt),
      );
      rows.add([
        sale.billNo,
        dateStr,
        sale.saleType,
        sale.subtotal,
        sale.discount,
        sale.total,
        sale.totalCost,
        sale.profit,
        sale.paymentMethod,
        sale.customerName ?? 'Walk-in',
        sale.items.length
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return await _saveFile('Sales_Report_${DateTime.now().millisecondsSinceEpoch}.csv', csvData);
  }

  static Future<String> exportProductsToCsv(List<Product> products) async {
    List<List<dynamic>> rows = [];
    rows.add([
      'ID',
      'Barcode',
      'Name',
      'Retail Price',
      'Wholesale Price',
      'Cost Price',
      'Stock',
      'Description'
    ]);

    for (var p in products) {
      rows.add([
        p.id,
        p.barcode ?? '',
        p.name,
        p.retailPrice,
        p.wsalePrice ?? '',
        p.costPrice,
        p.stock,
        p.description ?? ''
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return await _saveFile('Products_Stock_${DateTime.now().millisecondsSinceEpoch}.csv', csvData);
  }

  /// Cross-platform file save: uses FilePicker on all platforms
  static Future<String> _saveFile(String fileName, String content) async {
    try {
      final bytes = Uint8List.fromList(content.codeUnits);

      if (kIsWeb) {
        // On Web, use FilePicker saveFile which triggers browser download
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV File',
          fileName: fileName,
          bytes: bytes,
        );
        return result ?? 'Download triggered';
      } else {
        // On Desktop/Mobile, show save dialog
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV File',
          fileName: fileName,
          bytes: bytes,
        );
        return result ?? 'File saved';
      }
    } catch (e) {
      debugPrint('CSV Export error: $e');
      return 'Export failed: $e';
    }
  }
}

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
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
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Sales_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);
    await OpenFile.open(file.path);
    return file.path;
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
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Products_Stock_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);
    await OpenFile.open(file.path);
    return file.path;
  }
}

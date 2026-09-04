import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';
import '../models/day_end_summary.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._init();
  PrinterService._init();

  // Print Receipt on Thermal Printer (58mm, 72mm, 80mm) or Standard Printer
  Future<bool> printReceipt({
    required Sale sale,
    required StoreSettings settings,
  }) async {
    try {
      final doc = pw.Document();
      final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
        DateTime.fromMillisecondsSinceEpoch(sale.createdAt),
      );

      // Define page format based on paper size
      PdfPageFormat pageFormat;
      if (settings.paperSize == '58mm') {
        pageFormat = const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm);
      } else if (settings.paperSize == '72mm') {
        pageFormat = const PdfPageFormat(72 * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm);
      } else {
        pageFormat = const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);
      }

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Store Header
                pw.Text(
                  settings.storeName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                if (settings.address.isNotEmpty)
                  pw.Text(
                    settings.address,
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                if (settings.phone.isNotEmpty)
                  pw.Text(
                    'Tel: ${settings.phone}',
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                pw.Divider(thickness: 0.8),

                // Bill Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bill No: ${sale.billNo}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Type: ${sale.saleType.toUpperCase()}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 7)),
                    if (sale.cashierName != null)
                      pw.Text('Cashier: ${sale.cashierName}', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
                if (sale.customerName != null)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Customer: ${sale.customerName}', style: const pw.TextStyle(fontSize: 8)),
                  ),
                pw.Divider(thickness: 0.8),

                // Item Table Header
                pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 3, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                pw.Divider(thickness: 0.5),

                // Item List
                ...sale.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 5, child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Expanded(flex: 2, child: pw.Text('${item.qty}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Expanded(flex: 3, child: pw.Text(item.price.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Expanded(flex: 3, child: pw.Text(item.subtotal.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5))),
                      ],
                    ),
                  );
                }),
                pw.Divider(thickness: 0.8),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('${settings.currency} ${sale.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (sale.discount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('- ${settings.currency} ${sale.discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET TOTAL:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${settings.currency} ${sale.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Divider(thickness: 0.5),

                // Payment Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Mode:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(sale.paymentMethod.toUpperCase(), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (sale.paymentMethod == 'cash') ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Cash Paid:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('${settings.currency} ${sale.paidAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Change Due:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('${settings.currency} ${sale.changeAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
                pw.SizedBox(height: 6),

                // Footer Notes
                if (settings.receiptHeader.isNotEmpty)
                  pw.Text(
                    settings.receiptHeader,
                    style: const pw.TextStyle(fontSize: 7.5),
                    textAlign: pw.TextAlign.center,
                  ),
                if (settings.receiptFooter.isNotEmpty)
                  pw.Text(
                    settings.receiptFooter,
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                pw.SizedBox(height: 4),
                pw.Text('*** THANK YOU ***', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Bill_${sale.billNo}',
      );
      return true;
    } catch (e) {
      debugPrint('Printing error: $e');
      return false;
    }
  }

  // Print Day End Report
  Future<bool> printDayEndReport({
    required DayEndSummary summary,
    required StoreSettings settings,
  }) async {
    try {
      final doc = pw.Document();
      final dateStr = DateFormat('yyyy-MM-dd').format(summary.date);

      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(settings.storeName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('DAY END SUMMARY REPORT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8)),
                pw.Divider(thickness: 0.8),

                _reportRow('Total Bills:', '${summary.totalBills}'),
                _reportRow('Retail Sales:', '${settings.currency} ${summary.retailSales.toStringAsFixed(2)}'),
                _reportRow('Wholesale Sales:', '${settings.currency} ${summary.wholesaleSales.toStringAsFixed(2)}'),
                pw.Divider(thickness: 0.5),
                _reportRow('TOTAL REVENUE:', '${settings.currency} ${summary.totalSales.toStringAsFixed(2)}', bold: true),
                pw.Divider(thickness: 0.5),
                _reportRow('Cash Collections:', '${settings.currency} ${summary.cashSales.toStringAsFixed(2)}'),
                _reportRow('Card Payments:', '${settings.currency} ${summary.cardSales.toStringAsFixed(2)}'),
                _reportRow('Credit (Loans):', '${settings.currency} ${summary.creditSales.toStringAsFixed(2)}'),
                pw.Divider(thickness: 0.5),
                _reportRow('Total Cost (COGS):', '${settings.currency} ${summary.totalCost.toStringAsFixed(2)}'),
                _reportRow('Gross Profit:', '${settings.currency} ${summary.grossProfit.toStringAsFixed(2)}'),
                _reportRow('Total Expenses:', '- ${settings.currency} ${summary.totalExpenses.toStringAsFixed(2)}'),
                pw.Divider(thickness: 1),
                _reportRow('NET PROFIT:', '${settings.currency} ${summary.netProfit.toStringAsFixed(2)}', bold: true),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 6),
                pw.Text('Generated by ${settings.storeName} POS', style: const pw.TextStyle(fontSize: 7)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'DayEnd_$dateStr',
      );
      return true;
    } catch (e) {
      debugPrint('Day End Print error: $e');
      return false;
    }
  }

  pw.Widget _reportRow(String title, String val, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(val, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class BarcodesScreen extends StatefulWidget {
  const BarcodesScreen({Key? key}) : super(key: key);

  @override
  State<BarcodesScreen> createState() => _BarcodesScreenState();
}

class _BarcodesScreenState extends State<BarcodesScreen> {
  Product? _selectedProduct;
  int _copies = 1;

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'Barcode Labels & Printing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cyberBgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    dropdownColor: AppTheme.cyberBgSecondary,
                    style: const TextStyle(color: AppTheme.lightText),
                    decoration: const InputDecoration(
                      labelText: 'Select Product for Barcode Label',
                    ),
                    items: productProv.products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.name} (#${p.barcode ?? 'Auto'})', style: const TextStyle(color: AppTheme.lightText)),
                      );
                    }).toList(),
                    onChanged: (p) => setState(() => _selectedProduct = p),
                  ),
                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Label Copies to Print: ', style: TextStyle(color: AppTheme.slateText, fontSize: 13)),
                        const SizedBox(width: 10),
                        DropdownButton<int>(
                          value: _copies,
                          dropdownColor: AppTheme.cyberBgSecondary,
                          style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                          items: [1, 2, 5, 10, 20, 50].map((n) => DropdownMenuItem(value: n, child: Text('$n copies'))).toList(),
                          onChanged: (v) => setState(() => _copies = v ?? 1),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text('Print Sticker Labels'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                          onPressed: () => _printBarcodeLabels(context, _selectedProduct!, settings, _copies),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedProduct != null) ...[
              Center(
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.neonCyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        settings.storeName.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedProduct!.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: _selectedProduct!.barcode ?? _selectedProduct!.id.toString().padLeft(8, '0'),
                        width: 220,
                        height: 70,
                        drawText: true,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: ${settings.currency} ${_selectedProduct!.retailPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'Select a product above to generate and preview barcode sticker label.',
                        style: TextStyle(color: AppTheme.slateText, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _printBarcodeLabels(BuildContext context, Product product, dynamic settings, int count) async {
    final doc = pw.Document();
    final barcodeData = product.barcode ?? product.id.toString().padLeft(8, '0');

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm),
        build: (pw.Context ctx) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(settings.storeName, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.Text(product.name, style: const pw.TextStyle(fontSize: 7), maxLines: 1),
                pw.SizedBox(height: 2),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: barcodeData,
                  width: 120,
                  height: 35,
                  drawText: true,
                ),
                pw.SizedBox(height: 2),
                pw.Text('${settings.currency} ${product.retailPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Barcode_${product.name}',
    );
  }
}

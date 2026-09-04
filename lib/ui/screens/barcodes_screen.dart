import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';

class BarcodesScreen extends StatefulWidget {
  const BarcodesScreen({Key? key}) : super(key: key);

  @override
  State<BarcodesScreen> createState() => _BarcodesScreenState();
}

class _BarcodesScreenState extends State<BarcodesScreen> {
  Product? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Labels & Printing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Select Product for Barcode Label',
                border: OutlineInputBorder(),
              ),
              items: productProv.products.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.name} (${p.barcode ?? 'No Barcode'})'),
                );
              }).toList(),
              onChanged: (p) => setState(() => _selectedProduct = p),
            ),
            const SizedBox(height: 24),

            if (_selectedProduct != null) ...[
              Center(
                child: Card(
                  elevation: 4,
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(settings.storeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_selectedProduct!.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: _selectedProduct!.barcode ?? _selectedProduct!.id.toString().padLeft(8, '0'),
                          width: 200,
                          height: 70,
                          drawText: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Price: ${settings.currency} ${_selectedProduct!.retailPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text('Select a product above to generate and preview barcode label.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

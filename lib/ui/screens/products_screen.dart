import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/csv_export_service.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Inventory'),
        actions: [
          IconButton(
            tooltip: 'Export to Excel (CSV)',
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              await CsvExportService.exportProductsToCsv(productProv.products);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Products exported to CSV.')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              onPressed: () => _showProductDialog(context, null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (val) => productProv.setSearchQuery(val),
            ),
          ),
          Expanded(
            child: productProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProv.filteredProducts.isEmpty
                    ? const Center(child: Text('No products added yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: productProv.filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final p = productProv.filteredProducts[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                child: Icon(Icons.inventory_2, color: Theme.of(context).primaryColor),
                              ),
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Barcode: ${p.barcode ?? 'N/A'} | Cost: ${settings.currency}${p.costPrice.toStringAsFixed(2)} | Stock: ${p.stock}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Retail: ${settings.currency} ${p.retailPrice.toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                      ),
                                      if (p.wsalePrice != null)
                                        Text(
                                          'Wholesale: ${settings.currency} ${p.wsalePrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showProductDialog(context, p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, p),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final retailCtrl = TextEditingController(text: product != null ? product.retailPrice.toString() : '');
    final wsaleCtrl = TextEditingController(text: product?.wsalePrice?.toString() ?? '');
    final costCtrl = TextEditingController(text: product != null ? product.costPrice.toString() : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '0');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    int? selectedCategory = product?.categoryId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
                const SizedBox(height: 8),
                TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price (ගන්නා මිල)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: retailCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retail Price *'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: wsaleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wholesale Price'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || retailCtrl.text.trim().isEmpty) return;
              final p = Product(
                id: product?.id ?? 0,
                name: nameCtrl.text.trim(),
                barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                categoryId: selectedCategory,
                retailPrice: double.tryParse(retailCtrl.text) ?? 0.0,
                wsalePrice: double.tryParse(wsaleCtrl.text),
                costPrice: double.tryParse(costCtrl.text) ?? 0.0,
                stock: int.tryParse(stockCtrl.text) ?? 0,
                description: descCtrl.text.trim(),
              );

              final prov = Provider.of<ProductProvider>(context, listen: false);
              await prov.saveProduct(p);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prov = Provider.of<ProductProvider>(context, listen: false);
              await prov.deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

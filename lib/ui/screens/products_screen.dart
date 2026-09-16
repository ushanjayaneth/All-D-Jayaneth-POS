import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/stock_batch.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/csv_export_service.dart';
import '../../services/image_compression_service.dart';
import '../../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2, color: AppTheme.neonCyan, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isMobile ? 'Products' : 'Products & Inventory',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 17 : 18,
                  color: AppTheme.lightText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export to CSV',
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.slateText, size: 22),
            onPressed: () async {
              await CsvExportService.exportProductsToCsv(productProv.products);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Products exported to CSV successfully!'),
                    backgroundColor: AppTheme.greenSuccess,
                  ),
                );
              }
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 10.0 : 14.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(isMobile ? 'Add' : 'Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showProductDialog(context, null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar + Items Count Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppTheme.lightText),
                    decoration: InputDecoration(
                      hintText: 'Search products by name, barcode...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.neonCyan),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.slateText),
                              onPressed: () {
                                _searchCtrl.clear();
                                productProv.setSearchQuery('');
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                    onChanged: (val) => productProv.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${productProv.products.length} Items',
                    style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Categories Filter Chips
          if (productProv.categories.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('All Items'),
                      selected: productProv.selectedCategoryId == null,
                      selectedColor: AppTheme.neonCyan,
                      backgroundColor: AppTheme.cyberBgTertiary,
                      labelStyle: TextStyle(
                        color: productProv.selectedCategoryId == null ? Colors.black : AppTheme.slateText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => productProv.setSelectedCategory(null),
                    ),
                  ),
                  ...productProv.categories.map((cat) {
                    final isSel = productProv.selectedCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('${cat.icon ?? '📦'} ${cat.name}'),
                        selected: isSel,
                        selectedColor: AppTheme.neonCyan,
                        backgroundColor: AppTheme.cyberBgTertiary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : AppTheme.slateText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => productProv.setSelectedCategory(isSel ? null : cat.id),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Products List
          Expanded(
            child: productProv.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
                : productProv.filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'No products found.',
                              style: TextStyle(color: AppTheme.slateText, fontSize: 16),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Product'),
                              onPressed: () => _showProductDialog(context, null),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                        itemCount: productProv.filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final p = productProv.filteredProducts[i];
                          return _buildProductCard(context, p, settings.currency, settings.lowStockAlert);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product p, String currency, int lowStockLimit) {
    final hasBatches = p.stockBatches.isNotEmpty;
    final isLowStock = p.stock > 0 && p.stock <= lowStockLimit;
    final isOutOfStock = p.stock <= 0;

    Uint8List? imageBytes;
    if (p.imageBase64 != null && p.imageBase64!.isNotEmpty) {
      imageBytes = ImageCompressionService.decodeBase64(p.imageBase64);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cyberBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: AppTheme.cyberBgTertiary,
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: AppTheme.neonCyan, size: 28),
                    )
                  : const Icon(Icons.inventory_2, color: AppTheme.neonCyan, size: 28),
            ),
          ),
          const SizedBox(width: 12),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name + Badges
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Stock Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? AppTheme.redDanger.withOpacity(0.18)
                            : isLowStock
                                ? AppTheme.orangeWarning.withOpacity(0.18)
                                : AppTheme.greenSuccess.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOutOfStock
                              ? AppTheme.redDanger
                              : isLowStock
                                  ? AppTheme.orangeWarning
                                  : AppTheme.greenSuccess,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'OUT OF STOCK'
                            : isLowStock
                                ? 'LOW: ${p.stock} ${p.unit}'
                                : 'STOCK: ${p.stock} ${p.unit}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock
                              ? AppTheme.redDanger
                              : isLowStock
                                  ? AppTheme.orangeWarning
                                  : AppTheme.greenSuccess,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Barcode + Unit + Batches tag
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (p.barcode != null && p.barcode!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.cyberBgTertiary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          '# ${p.barcode}',
                          style: const TextStyle(color: AppTheme.slateText, fontSize: 11),
                        ),
                      ),
                    if (hasBatches)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.neonPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.neonPurple.withOpacity(0.4)),
                        ),
                        child: Text(
                          '📦 ${p.stockBatches.length} Batches',
                          style: const TextStyle(color: AppTheme.neonPurple, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Prices Grid / Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Retail: $currency ${p.retailPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (p.wsalePrice != null && p.wsalePrice! > 0)
                      Text(
                        'Wholesale: $currency ${p.wsalePrice!.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                      ),
                    Text(
                      'Cost: $currency ${p.costPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.dimText, fontSize: 12),
                    ),
                  ],
                ),

                // Old Stock vs New Stock Price Badges
                if ((p.oldStockPrice != null && p.oldStockPrice! > 0) || (p.newStockPrice != null && p.newStockPrice! > 0)) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (p.oldStockPrice != null && p.oldStockPrice! > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.orangeWarning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.orangeWarning.withOpacity(0.4)),
                          ),
                          child: Text(
                            'Old Stock: $currency ${p.oldStockPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppTheme.orangeWarning, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (p.newStockPrice != null && p.newStockPrice! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.greenSuccess.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.greenSuccess.withOpacity(0.4)),
                          ),
                          child: Text(
                            'New Stock: $currency ${p.newStockPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppTheme.greenSuccess, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),
                // Retail & Wholesale Profits
                Row(
                  children: [
                    Text(
                      'Retail Profit: $currency ${(p.retailPrice - p.costPrice).clamp(0.0, double.infinity).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.greenSuccess, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'WS Profit: $currency ${((p.wsalePrice ?? p.retailPrice) - p.costPrice).clamp(0.0, double.infinity).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons & Green + New Stock Button
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Dual Price Badge
              if (p.hasDualPricing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '🟡 Dual Price',
                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Green [+ New Stock] Button
              ElevatedButton.icon(
                icon: const Icon(Icons.add_box, size: 14),
                label: const Text('+ New Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenSuccess,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showRestockModal(context, p),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit Product',
                    icon: const Icon(Icons.edit, color: AppTheme.slateText, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showProductDialog(context, p),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Delete Product',
                    icon: const Icon(Icons.delete_outline, color: AppTheme.redDanger, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context, p),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickCategoryDialog(BuildContext context, Function(int?) onCreated) {
    final nameCtrl = TextEditingController();
    final productProv = Provider.of<ProductProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.cardBorder)),
        title: const Row(
          children: [
            Icon(Icons.category, color: AppTheme.neonCyan, size: 20),
            SizedBox(width: 8),
            Text('Add Category', style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.lightText),
          decoration: const InputDecoration(labelText: 'Category Name *', hintText: 'e.g. Fresh Chicken'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final cat = Category(name: name, icon: '📦');
              await productProv.saveCategory(cat);
              final newlyCreated = productProv.categories.where((c) => c.name == name).firstOrNull;
              onCreated(newlyCreated?.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Add / Edit Product Dialog with Image Upload (<100KB Auto Compression)
  void _showProductDialog(BuildContext context, Product? product) {
    final productProv = Provider.of<ProductProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final unitCtrl = TextEditingController(text: product?.unit ?? 'pcs');
    final retailCtrl = TextEditingController(text: product != null ? product.retailPrice.toStringAsFixed(2) : '');
    final wsaleCtrl = TextEditingController(text: product?.wsalePrice != null ? product!.wsalePrice!.toStringAsFixed(2) : '');
    final costCtrl = TextEditingController(text: product != null ? product.costPrice.toStringAsFixed(2) : '');
    final oldPriceCtrl = TextEditingController(text: product?.oldStockPrice != null ? product!.oldStockPrice!.toStringAsFixed(2) : '');
    final newPriceCtrl = TextEditingController(text: product?.newStockPrice != null ? product!.newStockPrice!.toStringAsFixed(2) : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '0');
    final lowStockCtrl = TextEditingController(text: product?.lowStockLimit != null ? product!.lowStockLimit.toString() : '');
    final descCtrl = TextEditingController(text: product?.description ?? '');

    int? selectedCat = product?.categoryId;
    String? currentImageBase64 = product?.imageBase64;
    bool isCompressingImage = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Uint8List? imgBytes;
          if (currentImageBase64 != null && currentImageBase64!.isNotEmpty) {
            imgBytes = ImageCompressionService.decodeBase64(currentImageBase64);
          }

          return AlertDialog(
            backgroundColor: AppTheme.cyberBgSecondary,
            title: Row(
              children: [
                Icon(
                  product == null ? Icons.add_circle : Icons.edit,
                  color: AppTheme.neonCyan,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  product == null ? 'Add New Product' : 'Edit Product',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.lightText),
                ),
              ],
            ),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker Section
                    const Text(
                      'Product Photo (Auto-compressed < 100KB)',
                      style: TextStyle(color: AppTheme.slateText, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cyberBgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 64,
                              height: 64,
                              color: AppTheme.cyberBg,
                              child: isCompressingImage
                                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonCyan))
                                  : imgBytes != null
                                      ? Image.memory(imgBytes, width: 64, height: 64, fit: BoxFit.cover)
                                      : const Icon(Icons.add_a_photo, color: AppTheme.dimText, size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: Text(imgBytes == null ? 'Select Image' : 'Change Image'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  onPressed: () async {
                                    setDialogState(() => isCompressingImage = true);
                                    try {
                                      final result = await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                        allowMultiple: false,
                                        withData: true,
                                      );
                                      if (result != null && result.files.isNotEmpty) {
                                        final raw = result.files.first.bytes;
                                        if (raw != null) {
                                          final compressed = await ImageCompressionService.compressAndConvertToBase64(
                                            raw,
                                            maxSize: 800,
                                            targetBytes: 100 * 1024,
                                          );
                                          setDialogState(() {
                                            currentImageBase64 = compressed;
                                            isCompressingImage = false;
                                          });
                                          return;
                                        }
                                      }
                                    } catch (_) {}
                                    setDialogState(() => isCompressingImage = false);
                                  },
                                ),
                                if (imgBytes != null) ...[
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setDialogState(() => currentImageBase64 = null);
                                    },
                                    child: const Text(
                                      'Remove Image',
                                      style: TextStyle(color: AppTheme.redDanger, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Name Field
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: AppTheme.lightText),
                      decoration: const InputDecoration(labelText: 'Product Name *'),
                    ),
                    const SizedBox(height: 10),

                    // Category Dropdown with Quick Add (+) Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: selectedCat,
                            dropdownColor: AppTheme.cyberBgSecondary,
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No Category (General)', style: TextStyle(color: AppTheme.slateText)),
                              ),
                              ...productProv.categories.map((c) => DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text('${c.icon ?? '📦'} ${c.name}', style: const TextStyle(color: AppTheme.lightText)),
                                  )),
                            ],
                            onChanged: (v) => setDialogState(() => selectedCat = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Create New Category',
                          child: InkWell(
                            onTap: () {
                              _showQuickCategoryDialog(context, (newCatId) {
                                setDialogState(() => selectedCat = newCatId);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.cyberBgTertiary,
                                border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, color: AppTheme.neonCyan, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Barcode & Unit
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: barcodeCtrl,
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: InputDecoration(
                              labelText: 'Barcode / SKU',
                              suffixIcon: IconButton(
                                tooltip: 'Auto Generate Barcode',
                                icon: const Icon(Icons.qr_code, color: AppTheme.neonCyan, size: 20),
                                onPressed: () {
                                  final gen = DateTime.now().millisecondsSinceEpoch.toString().substring(3);
                                  barcodeCtrl.text = gen;
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(labelText: 'Unit (pcs, kg...)'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Pricing Section Header
                    const Text(
                      'Pricing & Cost',
                      style: TextStyle(color: AppTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Cost Price & Retail Price
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(labelText: 'Cost Price'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: retailCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(labelText: 'Retail Price *'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Wholesale Price & Initial Stock
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: wsaleCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(labelText: 'Wholesale Price'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(labelText: 'Stock Quantity'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Individual Low Stock Limit Field
                    TextField(
                      controller: lowStockCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.orangeWarning),
                      decoration: const InputDecoration(
                        labelText: 'Individual Low Stock Alert Limit',
                        hintText: 'Leave blank to use global settings limit',
                        prefixIcon: Icon(Icons.warning_amber_rounded, color: AppTheme.orangeWarning, size: 18),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Dual Pricing (Old Stock vs New Stock) - Only for existing products with active dual pricing
                    if (product != null && product.hasDualPricing) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.cyberBgTertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.history_toggle_off, color: AppTheme.orangeWarning, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Batch Pricing (Old & New Stock Prices)',
                                  style: TextStyle(color: AppTheme.orangeWarning, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: oldPriceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: AppTheme.orangeWarning),
                                    decoration: const InputDecoration(
                                      labelText: 'Old Stock Price',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: newPriceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: AppTheme.greenSuccess),
                                    decoration: const InputDecoration(
                                      labelText: 'New Stock Price',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    TextField(
                      controller: descCtrl,
                      style: const TextStyle(color: AppTheme.lightText),
                      decoration: const InputDecoration(labelText: 'Description / Notes'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || retailCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter product name and retail price.')),
                    );
                    return;
                  }

                  final retail = double.tryParse(retailCtrl.text) ?? 0.0;
                  final wsale = double.tryParse(wsaleCtrl.text);
                  final cost = double.tryParse(costCtrl.text) ?? 0.0;
                  final oldPrice = (product != null && product.hasDualPricing) ? double.tryParse(oldPriceCtrl.text) : null;
                  final newPrice = (product != null && product.hasDualPricing) ? double.tryParse(newPriceCtrl.text) : null;
                  final stock = int.tryParse(stockCtrl.text) ?? 0;
                  final lowLimit = int.tryParse(lowStockCtrl.text);

                  final p = Product(
                    id: product?.id,
                    name: nameCtrl.text.trim(),
                    barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                    categoryId: selectedCat,
                    retailPrice: retail,
                    wsalePrice: wsale,
                    costPrice: cost,
                    oldStockPrice: oldPrice,
                    newStockPrice: newPrice,
                    stock: stock,
                    lowStockLimit: lowLimit,
                    unit: unitCtrl.text.trim().isEmpty ? 'pcs' : unitCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    imageBase64: currentImageBase64,
                    stockBatches: product?.stockBatches ?? [],
                    syncId: product?.syncId ?? const Uuid().v4(),
                    synced: 0,
                  );

                  await productProv.saveProduct(p);
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dedicated "+ Restock Product" Modal matching Screenshot 5.16.13 PM
  void _showRestockModal(BuildContext context, Product product) {
    final productProv = Provider.of<ProductProvider>(context, listen: false);
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController(text: product.costPrice.toStringAsFixed(2));
    final retailCtrl = TextEditingController(text: product.retailPrice.toStringAsFixed(2));
    final wsaleCtrl = TextEditingController(text: (product.wsalePrice ?? product.retailPrice).toStringAsFixed(2));
    final barcodeInputCtrl = TextEditingController();
    final List<String> scannedBarcodes = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final addedQty = double.tryParse(qtyCtrl.text) ?? 0.0;
          final newCost = double.tryParse(costCtrl.text) ?? product.costPrice;
          final newRetail = double.tryParse(retailCtrl.text) ?? product.retailPrice;
          final newWsale = double.tryParse(wsaleCtrl.text) ?? (product.wsalePrice ?? product.retailPrice);
          final isPriceChanged = (newRetail != product.retailPrice);
          final projectedStock = product.stock + addedQty.toInt();

          return AlertDialog(
            backgroundColor: AppTheme.cyberBgSecondary,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSuccess.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_box, color: AppTheme.greenSuccess, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '+ Restock Product',
                        style: TextStyle(color: AppTheme.lightText, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        product.name,
                        style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto Stock Preview Banner
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cyberBgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Current Stock', style: TextStyle(color: AppTheme.slateText, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text('${product.stock} ${product.unit}', style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const Icon(Icons.add, color: AppTheme.greenSuccess, size: 18),
                          Column(
                            children: [
                              const Text('Adding Qty', style: TextStyle(color: AppTheme.slateText, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text('${addedQty.toInt()} ${product.unit}', style: const TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: AppTheme.neonCyan, size: 18),
                          Column(
                            children: [
                              const Text('New Stock', style: TextStyle(color: AppTheme.slateText, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text('$projectedStock ${product.unit}', style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quantity & Purchase Price
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Add Quantity (${product.unit}) *',
                              prefixIcon: const Icon(Icons.inventory, color: AppTheme.greenSuccess, size: 18),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(
                              labelText: 'Purchase Price (Cost) *',
                              prefixIcon: Icon(Icons.attach_money, color: AppTheme.slateText, size: 18),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Selling Prices (Retail & Wholesale)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: retailCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              labelText: 'Selling Retail Price *',
                              prefixIcon: Icon(Icons.sell, color: AppTheme.neonCyan, size: 18),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: wsaleCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(
                              labelText: 'Selling WS Price',
                              prefixIcon: Icon(Icons.store, color: AppTheme.slateText, size: 18),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),

                    // Dual Pricing Alert Banner if price changed
                    if (isPriceChanged) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dual Pricing Activated!',
                                    style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Old Price: ${product.retailPrice.toStringAsFixed(2)}  ➔  New Price: ${newRetail.toStringAsFixed(2)}\nBoth prices will be selectable at POS checkout.',
                                    style: const TextStyle(color: AppTheme.lightText, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Scan Many Barcodes Section
                    const Text('Scan Many Barcodes:', style: TextStyle(color: AppTheme.slateText, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: barcodeInputCtrl,
                            style: const TextStyle(color: AppTheme.lightText),
                            decoration: const InputDecoration(
                              hintText: 'Enter / Scan Barcode...',
                              prefixIcon: Icon(Icons.qr_code_scanner, color: AppTheme.neonCyan, size: 18),
                              isDense: true,
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty && !scannedBarcodes.contains(val.trim())) {
                                setModalState(() {
                                  scannedBarcodes.add(val.trim());
                                  barcodeInputCtrl.clear();
                                  qtyCtrl.text = scannedBarcodes.length.toString();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                          onPressed: () {
                            final val = barcodeInputCtrl.text.trim();
                            if (val.isNotEmpty && !scannedBarcodes.contains(val)) {
                              setModalState(() {
                                scannedBarcodes.add(val);
                                barcodeInputCtrl.clear();
                                qtyCtrl.text = scannedBarcodes.length.toString();
                              });
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (scannedBarcodes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 80),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.cyberBgTertiary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: scannedBarcodes.length,
                          itemBuilder: (c, idx) => Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.greenSuccess, size: 14),
                              const SizedBox(width: 6),
                              Text(scannedBarcodes[idx], style: const TextStyle(color: AppTheme.lightText, fontSize: 12)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setModalState(() {
                                  scannedBarcodes.removeAt(idx);
                                  qtyCtrl.text = scannedBarcodes.isNotEmpty ? scannedBarcodes.length.toString() : qtyCtrl.text;
                                }),
                                child: const Icon(Icons.close, color: AppTheme.redDanger, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('+ Confirm Restock'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenSuccess, foregroundColor: Colors.black),
                onPressed: () async {
                  if (addedQty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid restock quantity.')),
                    );
                    return;
                  }

                  double? oldPrice = product.oldStockPrice;
                  double? newPrice = product.newStockPrice;
                  if (isPriceChanged) {
                    oldPrice = product.retailPrice;
                    newPrice = newRetail;
                  }

                  final newBatch = StockBatch(
                    batchId: const Uuid().v4(),
                    quantity: addedQty,
                    costPrice: newCost,
                    sellingPrice: newRetail,
                    barcodes: scannedBarcodes,
                    dateAdded: DateTime.now().toIso8601String(),
                  );

                  final updatedBatches = List<StockBatch>.from(product.stockBatches)..add(newBatch);
                  final updatedProduct = product.copyWith(
                    stock: product.stock + addedQty.toInt(),
                    costPrice: newCost,
                    retailPrice: newRetail,
                    wsalePrice: newWsale,
                    oldStockPrice: oldPrice,
                    newStockPrice: newPrice,
                    stockBatches: updatedBatches,
                  );

                  await productProv.saveProduct(updatedProduct);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Restocked "${product.name}": +${addedQty.toInt()} ${product.unit} (New Stock: ${updatedProduct.stock})'),
                        backgroundColor: AppTheme.greenSuccess,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Quick "Add Stock Batch" Modal
  void _showAddBatchDialog(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController(text: product.costPrice.toStringAsFixed(2));
    final sellCtrl = TextEditingController(text: product.retailPrice.toStringAsFixed(2));
    bool updateNewStockPrice = true;
    bool updateOldStockPrice = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setBatchState) => AlertDialog(
          backgroundColor: AppTheme.cyberBgSecondary,
          title: Row(
            children: [
              const Icon(Icons.add_business, color: AppTheme.neonCyan, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add Stock Batch - ${product.name}',
                  style: const TextStyle(color: AppTheme.lightText, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter incoming batch details to update stock levels and track batch pricing:',
                  style: TextStyle(color: AppTheme.slateText, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.lightText),
                        decoration: const InputDecoration(labelText: 'Quantity to Add *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppTheme.lightText),
                        decoration: const InputDecoration(labelText: 'Batch Cost Price'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sellCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(labelText: 'Batch Selling Price *'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as New Stock Price', style: TextStyle(color: AppTheme.lightText, fontSize: 12)),
                  value: updateNewStockPrice,
                  activeColor: AppTheme.neonCyan,
                  onChanged: (v) {
                    setBatchState(() {
                      updateNewStockPrice = v ?? true;
                      if (updateNewStockPrice) updateOldStockPrice = false;
                    });
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as Old Stock Price', style: TextStyle(color: AppTheme.lightText, fontSize: 12)),
                  value: updateOldStockPrice,
                  activeColor: AppTheme.orangeWarning,
                  onChanged: (v) {
                    setBatchState(() {
                      updateOldStockPrice = v ?? false;
                      if (updateOldStockPrice) updateNewStockPrice = false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                final cost = double.tryParse(costCtrl.text) ?? 0.0;
                final sell = double.tryParse(sellCtrl.text) ?? 0.0;

                if (qty <= 0) return;

                final newBatch = StockBatch(
                  batchId: const Uuid().v4(),
                  quantity: qty,
                  costPrice: cost,
                  sellingPrice: sell,
                  dateAdded: DateTime.now().toIso8601String(),
                );

                final prov = Provider.of<ProductProvider>(context, listen: false);
                await prov.addStockBatch(product.id!, newBatch);

                // Update product price if requested
                if (updateNewStockPrice || updateOldStockPrice) {
                  final currentP = prov.products.firstWhere((p) => p.id == product.id, orElse: () => product);
                  final updatedP = currentP.copyWith(
                    newStockPrice: updateNewStockPrice ? sell : currentP.newStockPrice,
                    oldStockPrice: updateOldStockPrice ? sell : currentP.oldStockPrice,
                  );
                  await prov.saveProduct(updatedP);
                }

                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Batch to Stock'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Text('Delete Product', style: TextStyle(color: AppTheme.redDanger, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete "${product.name}"?',
          style: const TextStyle(color: AppTheme.lightText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redDanger, foregroundColor: Colors.white),
            onPressed: () async {
              if (product.id != null) {
                final prov = Provider.of<ProductProvider>(context, listen: false);
                await prov.deleteProduct(product.id!);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

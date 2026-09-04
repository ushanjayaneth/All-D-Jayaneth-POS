import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../widgets/payment_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  void _onBarcodeSubmitted(String barcode) {
    if (barcode.trim().isEmpty) return;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final posProvider = Provider.of<PosProvider>(context, listen: false);

    final product = productProvider.findByBarcode(barcode.trim());
    if (product != null) {
      posProvider.addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to cart'),
          duration: const Duration(milliseconds: 700),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found for barcode: $barcode'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _barcodeCtrl.clear();
    _barcodeFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final pos = Provider.of<PosProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                // Products Catalog Panel (Left/Center)
                Expanded(
                  flex: 6,
                  child: _buildProductsCatalog(context, pos, productProv, settings),
                ),
                const VerticalDivider(width: 1),
                // Billing Cart Panel (Right)
                Expanded(
                  flex: 4,
                  child: _buildCartPanel(context, pos, settings),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(child: _buildProductsCatalog(context, pos, productProv, settings)),
                _buildMobileCartSummary(context, pos, settings),
              ],
            ),
    );
  }

  Widget _buildProductsCatalog(BuildContext context, PosProvider pos, ProductProvider productProv, dynamic settings) {
    return Column(
      children: [
        // Mode Selector Bar (Retail vs Wholesale) & Fast Barcode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).cardTheme.color,
          child: Row(
            children: [
              // Retail/Wholesale Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _modeButton(context, '🏪 Retail', 'retail', pos.saleMode == 'retail', () => pos.setSaleMode('retail')),
                    _modeButton(context, '📦 Wholesale', 'wholesale', pos.saleMode == 'wholesale', () => pos.setSaleMode('wholesale')),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Barcode Input
              Expanded(
                child: TextField(
                  controller: _barcodeCtrl,
                  focusNode: _barcodeFocus,
                  decoration: InputDecoration(
                    hintText: 'Scan Barcode or Type & Enter...',
                    prefixIcon: const Icon(Icons.qr_code_scanner, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: _onBarcodeSubmitted,
                ),
              ),
              const SizedBox(width: 12),

              // Search Input
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search product...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => productProv.setSearchQuery(val),
                ),
              ),
            ],
          ),
        ),

        // Category Filter Chips
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: const Text('All Categories'),
                  selected: productProv.selectedCategoryId == null,
                  onSelected: (selected) => productProv.setSelectedCategory(null),
                ),
              ),
              ...productProv.categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(cat.name),
                    selected: productProv.selectedCategoryId == cat.id,
                    onSelected: (selected) {
                      productProv.setSelectedCategory(selected ? cat.id : null);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: productProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productProv.filteredProducts.isEmpty
                  ? const Center(child: Text('No products found.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 0.88,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: productProv.filteredProducts.length,
                      itemBuilder: (ctx, i) {
                        final p = productProv.filteredProducts[i];
                        final displayPrice = (pos.saleMode == 'wholesale' && p.wsalePrice != null)
                            ? p.wsalePrice!
                            : p.retailPrice;

                        return InkWell(
                          onTap: () => pos.addToCart(p),
                          borderRadius: BorderRadius.circular(12),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.stock > 5 ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Stock: ${p.stock}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: p.stock > 5 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${settings.currency} ${displayPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _modeButton(BuildContext context, String label, String mode, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(BuildContext context, PosProvider pos, dynamic settings) {
    final customerProv = Provider.of<CustomerProvider>(context);

    return Container(
      color: Theme.of(context).cardTheme.color,
      child: Column(
        children: [
          // Cart Header & Customer Selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Customer>(
                    value: pos.selectedCustomer,
                    decoration: InputDecoration(
                      labelText: 'Select Customer (Optional)',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.person, size: 18),
                    ),
                    items: [
                      const DropdownMenuItem<Customer>(
                        value: null,
                        child: Text('Walk-in Customer'),
                      ),
                      ...customerProv.customers.map((c) {
                        return DropdownMenuItem<Customer>(
                          value: c,
                          child: Text('${c.name} ${c.phone != null ? '(${c.phone})' : ''}'),
                        );
                      }).toList(),
                    ],
                    onChanged: (c) => pos.setSelectedCustomer(c),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Hold Bill',
                  icon: const Icon(Icons.pause_circle_outline, color: Colors.orange),
                  onPressed: pos.cartItems.isEmpty ? null : () async {
                    final ok = await pos.holdCurrentBill();
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bill saved to Held Bills.')),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Clear Cart',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: pos.cartItems.isEmpty ? null : () => pos.clearCart(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cart Items List
          Expanded(
            child: pos.cartItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Cart is empty', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: pos.cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = pos.cartItems[i];
                      return ListTile(
                        dense: true,
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${settings.currency} ${item.price.toStringAsFixed(2)} each'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => pos.updateQuantity(i, item.qty - 1),
                            ),
                            Text('${item.qty}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => pos.updateQuantity(i, item.qty + 1),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                '${settings.currency} ${item.subtotal.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                              onPressed: () => pos.removeFromCart(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),

          // Pricing & Checkout Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items: ${pos.totalItemCount}', style: const TextStyle(color: Colors.grey)),
                    Text('Subtotal: ${settings.currency} ${pos.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NET TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '${settings.currency} ${pos.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_bag_checkout),
                    label: const Text('PAY / CHECKOUT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: pos.cartItems.isEmpty
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (ctx) => PaymentDialog(totalAmount: pos.total),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartSummary(BuildContext context, PosProvider pos, dynamic settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${pos.totalItemCount} Items in Cart', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                '${settings.currency} ${pos.total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('View Cart & Pay'),
            onPressed: pos.cartItems.isEmpty
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => Container(
                        height: MediaQuery.of(context).size.height * 0.85,
                        child: _buildCartPanel(context, pos, settings),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../providers/pos_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/image_compression_service.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_layout.dart';
import '../widgets/batch_price_selector_dialog.dart';
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

  int _lockTapCount = 0;
  DateTime _lastLockTap = DateTime.now();

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
      _handleProductTap(product, posProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Barcode not found: $barcode'),
          backgroundColor: AppTheme.redDanger,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _barcodeCtrl.clear();
    _barcodeFocus.requestFocus();
  }

  Future<void> _handleProductTap(Product product, PosProvider pos) async {
    final hasMultiplePrices = (product.oldStockPrice != null && product.oldStockPrice! > 0) ||
        (product.newStockPrice != null && product.newStockPrice! > 0) ||
        product.stockBatches.length > 1;

    if (hasMultiplePrices) {
      final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
      final selection = await showDialog<BatchPriceSelection>(
        context: context,
        builder: (ctx) => BatchPriceSelectorDialog(
          product: product,
          currency: settings.currency,
          saleMode: pos.selectedSaleMode,
        ),
      );

      if (selection != null) {
        pos.addToCart(
          product,
          customPrice: selection.price,
          batchId: selection.batchId,
          batchLabel: selection.label,
        );
      }
    } else {
      pos.addToCart(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = Provider.of<PosProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;
    final sync = Provider.of<SyncProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.cyberBg,
          appBar: _buildTopAppBar(context, pos, settings, sync),
          body: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildProductCatalog(context, pos, productProv, settings),
                    ),
                    const VerticalDivider(width: 1, color: AppTheme.cardBorder),
                    Expanded(
                      flex: 4,
                      child: _buildCartPanel(context, pos, settings),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildProductCatalog(context, pos, productProv, settings)),
                    if (pos.cartItems.isNotEmpty) _buildMobileCartBar(context, pos, settings),
                  ],
                ),
        ),

        // App Lock Overlay
        if (pos.isLicenseBlocked) _buildLockOverlay(context, pos),
      ],
    );
  }

  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    PosProvider pos,
    dynamic settings,
    SyncProvider sync,
  ) {
    final storeName = settings.storeName.isNotEmpty ? settings.storeName : 'Jayaneth Demo';
    final cashier = pos.currentDeviceInfo?.cashier ?? "Cashier 1";
    final counter = pos.currentDeviceInfo?.devName ?? "Counter A";

    return AppBar(
      backgroundColor: AppTheme.cyberBg,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppTheme.lightText),
        onPressed: () {
          MainNavigationLayout.of(context)?.openDrawer();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storeName,
            style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
            '$cashier · $counter',
            style: const TextStyle(color: AppTheme.dimText, fontSize: 11.5),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sync.isOnline ? AppTheme.greenSuccess : AppTheme.redDanger,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                sync.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: sync.isOnline ? AppTheme.greenSuccess : AppTheme.redDanger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaleModePill(String label, String mode, PosProvider pos, Color activeColor) {
    final isSelected = pos.selectedSaleMode == mode;
    return InkWell(
      onTap: () => pos.setSaleMode(mode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : AppTheme.cyberBgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppTheme.slateText,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCatalog(
    BuildContext context,
    PosProvider pos,
    ProductProvider productProv,
    dynamic settings,
  ) {
    final products = productProv.filteredProducts;

    return Column(
      children: [
        // 1. Sale Mode Selection Row (4 Pills in a Row)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _buildSaleModePill('🏪 Retail', 'retail', pos, AppTheme.neonCyan),
              const SizedBox(width: 8),
              _buildSaleModePill('📦 W.Sale', 'wholesale', pos, const Color(0xFFA855F7)),
              const SizedBox(width: 8),
              _buildSaleModePill('💳 R.Loan', 'r_loan', pos, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildSaleModePill('💳 W.Loan', 'w_loan', pos, const Color(0xFFF59E0B)),
            ],
          ),
        ),

        // 2. Search Bar + QR Scan + Cart Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.cyberBgTertiary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppTheme.lightText, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(color: AppTheme.dimText, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.slateText, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.dimText, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                productProv.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => productProv.setSearchQuery(val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showManualBarcodeDialog(context),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cyberBgTertiary,
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppTheme.neonCyan, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openMobileCartSheet(context, pos, settings),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cyberBgTertiary,
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, color: AppTheme.neonCyan, size: 22),
                      if (pos.cartItemCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.redDanger,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            alignment: Alignment.center,
                            child: Text(
                              '${pos.cartItemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Category Filter Chips + "+ add New"
        _buildCategoryChips(context, productProv),

        // 4. Products Grid
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.inventory_2_outlined, color: AppTheme.dimText, size: 52),
                      SizedBox(height: 12),
                      Text('No products found', style: TextStyle(color: AppTheme.slateText, fontSize: 14)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, idx) {
                    final p = products[idx];
                    return _buildProductCard(context, p, pos, settings);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(BuildContext context, ProductProvider productProv) {
    final categories = productProv.categories;
    final selectedId = productProv.selectedCategoryId;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        children: [
          _categoryChip(
            label: 'All',
            isSelected: selectedId == null,
            onTap: () => productProv.setSelectedCategory(null),
          ),
          ...categories.map((c) {
            return _categoryChip(
              label: '${c.icon ?? "📦"} ${c.name}',
              isSelected: selectedId == c.id,
              onTap: () => productProv.setSelectedCategory(c.id),
            );
          }),
          _addCategoryChip(context),
        ],
      ),
    );
  }

  Widget _categoryChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonCyan.withOpacity(0.12) : AppTheme.cyberBgTertiary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppTheme.neonCyan : AppTheme.cardBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.neonCyan : AppTheme.slateText,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _addCategoryChip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _showQuickAddCategoryDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cyberBgTertiary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppTheme.slateText, size: 14),
              SizedBox(width: 4),
              Text(
                'add New',
                style: TextStyle(color: AppTheme.slateText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product p,
    PosProvider pos,
    dynamic settings,
  ) {
    final mode = pos.selectedSaleMode;
    final isWholesale = mode == 'wholesale' || mode == 'w_loan';
    final isLoan = mode == 'r_loan' || mode == 'w_loan';
    final price = isWholesale ? (p.wsalePrice ?? p.retailPrice) : p.retailPrice;
    final profit = (price - p.costPrice).clamp(0.0, double.infinity);
    final currency = settings.currency ?? 'Rs';

    Color priceColor = AppTheme.neonCyan;
    if (isLoan) {
      priceColor = const Color(0xFFF59E0B);
    } else if (isWholesale) {
      priceColor = const Color(0xFFA855F7);
    }

    final imageBytes = ImageCompressionService.decodeBase64(p.imageBase64);
    final effectiveLimit = p.getEffectiveLowStockLimit(settings.lowStockAlert);
    final isLowStock = p.stock <= effectiveLimit;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cyberBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowStock ? AppTheme.redDanger.withOpacity(0.6) : AppTheme.cardBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleProductTap(p, pos),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberBgTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.devices, color: AppTheme.slateText, size: 32),
                          ),
                  ),
                ),

                // Product Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Category indicator
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.neonCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              p.categoryName ?? 'General',
                              style: const TextStyle(color: AppTheme.slateText, fontSize: 10.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Price
                      Text(
                        '$currency ${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: priceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),

                      // Profit
                      Text(
                        'Profit: $currency ${profit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.greenSuccess,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Stock box with low stock alert
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLowStock ? AppTheme.redDanger.withOpacity(0.15) : AppTheme.cyberBgTertiary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLowStock ? AppTheme.redDanger : AppTheme.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLowStock) ...[
                              const Icon(Icons.warning_amber_rounded, color: AppTheme.redDanger, size: 11),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              'Stock: ${p.stock}',
                              style: TextStyle(
                                color: isLowStock ? AppTheme.redDanger : AppTheme.slateText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Dual Price Badge
            if (p.hasDualPricing)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Dual Price',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== CART PANEL (DESKTOP) & BOTTOM SHEET (MOBILE) =====
  Widget _buildCartPanel(BuildContext context, PosProvider pos, dynamic settings) {
    return Container(
      color: AppTheme.cyberBgSecondary,
      child: Column(
        children: [
          // Cart Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: AppTheme.neonCyan, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Cart Items (${pos.cartItemCount})',
                      style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                if (pos.cartItems.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, color: AppTheme.redDanger, size: 16),
                    label: const Text('Clear', style: TextStyle(color: AppTheme.redDanger, fontSize: 12)),
                    onPressed: () => pos.clearCart(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),

          // Cart Item List
          Expanded(
            child: pos.cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.remove_shopping_cart_outlined, color: AppTheme.dimText, size: 40),
                        SizedBox(height: 8),
                        Text('Cart is empty', style: TextStyle(color: AppTheme.slateText)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: pos.cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = pos.cartItems[idx];
                      return _buildCartItemTile(context, item, idx, pos, settings);
                    },
                  ),
          ),

          // Customer Selector & Discount & Summary
          _buildCartFooter(context, pos, settings),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(
    BuildContext context,
    dynamic item,
    int index,
    PosProvider pos,
    dynamic settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cyberBgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${settings.currency} ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12),
                    ),
                    if (item.batchLabel != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.orangeWarning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.batchLabel!,
                          style: const TextStyle(color: AppTheme.orangeWarning, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Qty Control
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16, color: AppTheme.slateText),
                onPressed: () => pos.updateItemQty(index, -1),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cyberBgSecondary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  '${item.qty.toInt()}',
                  style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16, color: AppTheme.neonCyan),
                onPressed: () => pos.updateItemQty(index, 1),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),

          // Subtotal
          const SizedBox(width: 8),
          Text(
            '${settings.currency} ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter(BuildContext context, PosProvider pos, dynamic settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cyberBgSecondary,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Customer Picker
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: AppTheme.slateText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pos.selectedCustomer?.name ?? 'Walk-in Customer',
                  style: TextStyle(
                    color: pos.selectedCustomer != null ? AppTheme.neonCyan : AppTheme.slateText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showCustomerPickerDialog(context, pos),
                child: Text(
                  pos.selectedCustomer != null ? 'Change' : 'Select Customer',
                  style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Calculations: Subtotal, Discount, Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(color: AppTheme.slateText, fontSize: 13)),
              Text('${settings.currency} ${pos.cartSubtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.lightText)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _showDiscountDialog(context, pos),
                child: Row(
                  children: [
                    const Text('Discount:', style: TextStyle(color: AppTheme.slateText, fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      pos.discountType == 'p' ? '(${pos.discountValue}%)' : '(${settings.currency}${pos.discountValue})',
                      style: const TextStyle(color: AppTheme.orangeWarning, fontSize: 11),
                    ),
                    const Icon(Icons.edit, size: 12, color: AppTheme.orangeWarning),
                  ],
                ),
              ),
              Text('- ${settings.currency} ${pos.cartDiscount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.orangeWarning)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PAYABLE:', style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '${settings.currency} ${pos.cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Hold Bill & Checkout
          Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.pause, size: 16, color: AppTheme.orangeWarning),
                  label: const Text('Hold Bill', style: TextStyle(color: AppTheme.orangeWarning, fontSize: 12)),
                  onPressed: pos.cartItems.isEmpty ? null : () => pos.holdCurrentBill(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('PAY / CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: pos.cartItems.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => PaymentDialog(totalAmount: pos.cartTotal),
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mobile Bottom Floating Cart Summary
  Widget _buildMobileCartBar(BuildContext context, PosProvider pos, dynamic settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.cyberBgSecondary,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${pos.cartItemCount} Items',
                  style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                ),
                Text(
                  '${settings.currency} ${pos.cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('View Cart / Pay'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.cyberBgSecondary,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                  builder: (ctx) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: _buildCartPanel(context, pos, settings),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManualBarcodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Text('Scan / Enter Barcode', style: TextStyle(color: AppTheme.lightText)),
        content: TextField(
          controller: _barcodeCtrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.lightText),
          decoration: const InputDecoration(hintText: 'Barcode number...'),
          onSubmitted: (val) {
            Navigator.pop(ctx);
            _onBarcodeSubmitted(val);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onBarcodeSubmitted(_barcodeCtrl.text);
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _showCustomerPickerDialog(BuildContext context, PosProvider pos) {
    final customerProv = Provider.of<CustomerProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Text('Select Customer', style: TextStyle(color: AppTheme.lightText)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Walk-in Customer (No Account)', style: TextStyle(color: AppTheme.lightText)),
                onTap: () {
                  pos.setCustomer(null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(color: AppTheme.cardBorder),
              ...customerProv.customers.map((c) {
                return ListTile(
                  title: Text(c.name, style: const TextStyle(color: AppTheme.lightText)),
                  subtitle: Text(c.phone ?? '', style: const TextStyle(color: AppTheme.slateText)),
                  trailing: c.totalDue > 0
                      ? Text('Due: ${c.totalDue}', style: const TextStyle(color: AppTheme.orangeWarning))
                      : null,
                  onTap: () {
                    pos.setCustomer(c);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, PosProvider pos) {
    final ctrl = TextEditingController(text: pos.discountValue > 0 ? pos.discountValue.toString() : '');
    String currentType = pos.discountType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          backgroundColor: AppTheme.cyberBgSecondary,
          title: const Text('Apply Discount', style: TextStyle(color: AppTheme.lightText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Fixed Amount (Rs)'),
                      selected: currentType == 'a',
                      onSelected: (s) => setSt(() => currentType = 'a'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Percentage (%)'),
                      selected: currentType == 'p',
                      onSelected: (s) => setSt(() => currentType = 'p'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: InputDecoration(
                  labelText: currentType == 'a' ? 'Discount Amount' : 'Discount %',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                pos.setDiscount(0.0, 'a');
                Navigator.pop(ctx);
              },
              child: const Text('Clear', style: TextStyle(color: AppTheme.redDanger)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(ctrl.text) ?? 0.0;
                pos.setDiscount(val, currentType);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // Master Lock Overlay
  Widget _buildLockOverlay(BuildContext context, PosProvider pos) {
    final isOfflineExpired = pos.lockReason == 'OFFLINE_EXPIRED';

    return Container(
      color: AppTheme.cyberBg.withOpacity(0.96),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Card(
        color: AppTheme.cyberBgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isOfflineExpired ? AppTheme.orangeWarning : AppTheme.redDanger, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  if (now.difference(_lastLockTap).inMilliseconds < 800) {
                    _lockTapCount++;
                  } else {
                    _lockTapCount = 1;
                  }
                  _lastLockTap = now;
                  if (_lockTapCount >= 5) {
                    _lockTapCount = 0;
                    _showMasterUnlockDialog(context, pos);
                  }
                },
                child: Icon(
                  isOfflineExpired ? Icons.wifi_off : Icons.lock,
                  color: isOfflineExpired ? AppTheme.orangeWarning : AppTheme.redDanger,
                  size: 56,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isOfflineExpired ? '🌐 INTERNET REQUIRED' : '🚨 APP LICENSE BLOCKED',
                style: TextStyle(
                  color: isOfflineExpired ? AppTheme.orangeWarning : AppTheme.redDanger,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOfflineExpired
                    ? 'Please connect device to Internet to verify license.'
                    : 'This POS application has been locked. Please contact Admin.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'Store: ${pos.currentDeviceInfo?.store ?? "Jayaneth Mobile"}\nDevice ID: ${pos.currentDeviceInfo?.id ?? "DEV_1"}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.dimText, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMasterUnlockDialog(BuildContext context, PosProvider pos) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Text('Master Admin Unlock', style: TextStyle(color: AppTheme.lightText)),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: AppTheme.lightText),
          decoration: const InputDecoration(labelText: 'Enter Master PIN (9999)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (pos.unlockWithPin(pinCtrl.text)) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ App Unlocked Successfully!'), backgroundColor: AppTheme.greenSuccess),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Invalid PIN'), backgroundColor: AppTheme.redDanger),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

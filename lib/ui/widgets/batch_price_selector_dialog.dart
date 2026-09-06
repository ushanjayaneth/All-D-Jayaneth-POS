import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';

class BatchPriceSelection {
  final double price;
  final String label;
  final String? batchId;
  final double costPrice;

  BatchPriceSelection({
    required this.price,
    required this.label,
    this.batchId,
    required this.costPrice,
  });
}

class BatchPriceSelectorDialog extends StatelessWidget {
  final Product product;
  final String currency;
  final String saleMode; // 'retail' or 'wholesale'

  const BatchPriceSelectorDialog({
    Key? key,
    required this.product,
    this.currency = 'Rs.',
    this.saleMode = 'retail',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double defaultPrice = saleMode == 'wholesale'
        ? (product.wsalePrice ?? product.retailPrice)
        : product.retailPrice;

    return AlertDialog(
      backgroundColor: AppTheme.cyberBgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.cardBorder, width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.price_change_outlined, color: AppTheme.neonCyan, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(color: AppTheme.lightText, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'මෙම භාණ්ඩය සඳහා මිල තෝරන්න (Select Price Batch):',
            style: TextStyle(color: AppTheme.slateText, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Option 1: Old Stock Price (if defined)
          if (product.oldStockPrice != null && product.oldStockPrice! > 0) ...[
            _buildOptionCard(
              context: context,
              icon: Icons.history,
              badgeColor: AppTheme.orangeWarning,
              badgeText: '🟡 පරණ ස්ටොක් (Old Stock)',
              priceText: '$currency ${product.oldStockPrice!.toStringAsFixed(2)}',
              onTap: () {
                Navigator.pop(
                  context,
                  BatchPriceSelection(
                    price: product.oldStockPrice!,
                    label: 'Old Stock',
                    batchId: 'old_batch',
                    costPrice: product.costPrice,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],

          // Option 2: New Stock Price (if defined)
          if (product.newStockPrice != null && product.newStockPrice! > 0) ...[
            _buildOptionCard(
              context: context,
              icon: Icons.new_releases_outlined,
              badgeColor: AppTheme.greenSuccess,
              badgeText: '🟢 අලුත් ස්ටොක් (New Stock)',
              priceText: '$currency ${product.newStockPrice!.toStringAsFixed(2)}',
              onTap: () {
                Navigator.pop(
                  context,
                  BatchPriceSelection(
                    price: product.newStockPrice!,
                    label: 'New Stock',
                    batchId: 'new_batch',
                    costPrice: product.costPrice,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],

          // Option 3: Standard Default Price
          _buildOptionCard(
            context: context,
            icon: Icons.sell_outlined,
            badgeColor: AppTheme.neonCyan,
            badgeText: saleMode == 'wholesale' ? '📦 තොග මිල (Wholesale)' : '🏪 සාමාන්‍ය මිල (Standard)',
            priceText: '$currency ${defaultPrice.toStringAsFixed(2)}',
            onTap: () {
              Navigator.pop(
                context,
                BatchPriceSelection(
                  price: defaultPrice,
                  label: 'Standard',
                  costPrice: product.costPrice,
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.dimText)),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color badgeColor,
    required String badgeText,
    required String priceText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cyberBgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: badgeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceText,
                    style: const TextStyle(color: AppTheme.lightText, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.slateText, size: 14),
          ],
        ),
      ),
    );
  }
}

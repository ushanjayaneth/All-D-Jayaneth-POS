import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/sale.dart';
import '../../models/return_bill.dart';
import '../../models/cart_item.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/product_provider.dart';
import '../../data/pos_repository.dart';
import '../../services/printer_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/receipt_preview_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsProvider>(context, listen: false).loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    final filteredSales = reportProv.sales.where((s) {
      final billMatches = s.billNo.toLowerCase().contains(_search.toLowerCase());
      final customerMatches = s.customerName != null && s.customerName!.toLowerCase().contains(_search.toLowerCase());
      return billMatches || customerMatches;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.history, color: AppTheme.neonCyan, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Sales Transaction History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
              ),
              child: Text(
                '${filteredSales.length} Invoices',
                style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              style: const TextStyle(color: AppTheme.lightText),
              decoration: InputDecoration(
                hintText: 'Search by bill number or customer name...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.neonCyan),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'No sales transactions found.',
                          style: TextStyle(color: AppTheme.slateText, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filteredSales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final sale = filteredSales[i];
                      final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(sale.createdAt),
                      );

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cyberBgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.neonCyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.receipt, color: AppTheme.neonCyan, size: 22),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sale.billNo,
                                  style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '${settings.currency} ${sale.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan, fontSize: 15),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '$dateStr • ${sale.paymentMethod.toUpperCase()} • ${sale.customerName ?? 'Walk-in'}',
                              style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                            ),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14.0),
                                decoration: const BoxDecoration(
                                  color: AppTheme.cyberBgTertiary,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Items Sold:', style: TextStyle(color: AppTheme.slateText, fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    ...sale.items.map((it) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '• ${it.name} x ${it.qty}',
                                                style: const TextStyle(color: AppTheme.lightText, fontSize: 13),
                                              ),
                                              Text(
                                                '${settings.currency} ${it.subtotal.toStringAsFixed(2)}',
                                                style: const TextStyle(color: AppTheme.slateText, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        )),
                                    const Divider(color: AppTheme.cardBorder, height: 18),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.assignment_return, size: 16, color: AppTheme.orangeWarning),
                                          label: const Text('Return Items', style: TextStyle(color: AppTheme.orangeWarning)),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.orangeWarning)),
                                          onPressed: () => _showReturnDialog(context, sale),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.share, size: 16, color: AppTheme.greenSuccess),
                                          label: const Text('WhatsApp Bill', style: TextStyle(color: AppTheme.greenSuccess)),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.greenSuccess)),
                                          onPressed: () => _showWhatsAppDialog(context, sale),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.remove_red_eye, size: 16, color: AppTheme.neonCyan),
                                          label: const Text('View Slip', style: TextStyle(color: AppTheme.lightText)),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => ReceiptPreviewDialog(sale: sale),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.print, size: 16),
                                          label: const Text('Reprint'),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                                          onPressed: () => PrinterService.instance.printReceipt(
                                            sale: sale,
                                            settings: settings,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  void _showWhatsAppDialog(BuildContext context, Sale sale) {
    final phoneCtrl = TextEditingController();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Row(
          children: [
            Icon(Icons.share, color: AppTheme.greenSuccess, size: 20),
            SizedBox(width: 8),
            Text('Share Bill on WhatsApp', style: TextStyle(color: AppTheme.lightText, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter customer WhatsApp mobile number (e.g. 0771234567):',
              style: TextStyle(color: AppTheme.slateText, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.lightText),
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone, color: AppTheme.greenSuccess),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenSuccess, foregroundColor: Colors.black),
            onPressed: () async {
              final phone = phoneCtrl.text.trim();
              if (phone.isNotEmpty) {
                await WhatsAppService.sendReceipt(
                  sale: sale,
                  settings: settings,
                  phoneNumber: phone,
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Send Receipt'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context, Sale sale) {
    final reasonCtrl = TextEditingController();
    final Map<int, bool> selectedItems = {
      for (int i = 0; i < sale.items.length; i++) i: true,
    };
    final Map<int, int> returnQuantities = {
      for (int i = 0; i < sale.items.length; i++) i: sale.items[i].qty.toInt(),
    };
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          double totalRefund = 0.0;
          double totalCostDeduction = 0.0;
          int totalItemsToReturn = 0;

          for (int i = 0; i < sale.items.length; i++) {
            if (selectedItems[i] == true) {
              final it = sale.items[i];
              final q = returnQuantities[i] ?? 1;
              totalRefund += it.price * q;
              totalCostDeduction += it.costPrice * q;
              totalItemsToReturn += q;
            }
          }

          final profitDeduction = (totalRefund - totalCostDeduction).clamp(0.0, double.infinity);

          return AlertDialog(
            backgroundColor: AppTheme.cyberBgSecondary,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeWarning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_return, color: AppTheme.orangeWarning, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '↩ Return Items / Full Bill',
                        style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Bill: ${sale.billNo} • Customer: ${sale.customerName ?? 'Walk-in'}',
                        style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select items to return & refund:',
                          style: TextStyle(color: AppTheme.lightText, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            final allSelected = selectedItems.values.every((v) => v);
                            setModalState(() {
                              for (int i = 0; i < sale.items.length; i++) {
                                selectedItems[i] = !allSelected;
                              }
                            });
                          },
                          child: Text(
                            selectedItems.values.every((v) => v) ? 'Deselect All' : 'Select All',
                            style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Items Checklist
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cyberBgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sale.items.length,
                        separatorBuilder: (_, __) => const Divider(color: AppTheme.cardBorder, height: 1),
                        itemBuilder: (c, idx) {
                          final it = sale.items[idx];
                          final isSelected = selectedItems[idx] ?? false;
                          final currQty = returnQuantities[idx] ?? 1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppTheme.orangeWarning,
                                  onChanged: (v) {
                                    setModalState(() {
                                      selectedItems[idx] = v ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.name,
                                        style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Text(
                                        'Unit: ${settings.currency} ${it.price.toStringAsFixed(2)} | Bought: ${it.qty}',
                                        style: const TextStyle(color: AppTheme.slateText, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity selector
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.slateText),
                                      onPressed: (isSelected && currQty > 1)
                                          ? () => setModalState(() => returnQuantities[idx] = currQty - 1)
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '$currQty',
                                        style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.slateText),
                                      onPressed: (isSelected && currQty < it.qty)
                                          ? () => setModalState(() => returnQuantities[idx] = currQty + 1)
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${settings.currency} ${(it.price * currQty).toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12.5),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: reasonCtrl,
                      style: const TextStyle(color: AppTheme.lightText),
                      decoration: const InputDecoration(
                        labelText: 'Reason for Return (Optional)',
                        hintText: 'e.g. Defective, Wrong Size, Customer Refund',
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Refund Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.redDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.redDanger.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Refund Amount:', style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                '${settings.currency} ${totalRefund.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppTheme.redDanger, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Profit Deduction:', style: TextStyle(color: AppTheme.slateText, fontSize: 12)),
                              Text(
                                '- ${settings.currency} ${profitDeduction.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppTheme.orangeWarning, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.inventory, color: AppTheme.greenSuccess, size: 14),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Inventory: Returned items will automatically be restocked into inventory.',
                                  style: TextStyle(color: AppTheme.greenSuccess, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.assignment_return, size: 16),
                label: Text(totalItemsToReturn == sale.items.fold(0, (s, i) => s + i.qty.toInt()) ? 'Return Entire Bill' : 'Confirm Return ($totalItemsToReturn Items)'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orangeWarning, foregroundColor: Colors.black),
                onPressed: totalRefund <= 0
                    ? null
                    : () async {
                        final repo = PosRepository();
                        final returnedCartItems = <CartItem>[];

                        for (int i = 0; i < sale.items.length; i++) {
                          if (selectedItems[i] == true) {
                            final it = sale.items[i];
                            final q = returnQuantities[i] ?? 1;
                            returnedCartItems.add(
                              CartItem(
                                productId: it.productId,
                                name: it.name,
                                price: it.price,
                                costPrice: it.costPrice,
                                quantity: q,
                                batchId: it.batchId,
                              ),
                            );
                          }
                        }

                        // 1. Record ReturnBill (which also automatically replenishes stock in DB)
                        final returnRecord = ReturnBill(
                          saleBillNo: sale.billNo,
                          returnedItems: returnedCartItems,
                          refundAmount: totalRefund,
                          reason: reasonCtrl.text.trim().isEmpty ? 'Sales Return' : reasonCtrl.text.trim(),
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        await repo.insertReturn(returnRecord);

                        // 2. Record negative refund sale to deduct revenue and profit
                        final refundSale = Sale(
                          billNo: 'RET-${sale.billNo}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                          saleType: 'return',
                          subtotal: -totalRefund,
                          discount: 0,
                          total: -totalRefund,
                          totalCost: -totalCostDeduction,
                          paymentMethod: sale.paymentMethod,
                          paidAmount: -totalRefund,
                          changeAmount: 0,
                          items: returnedCartItems.map((c) => c.copyWith(price: -c.price, costPrice: -c.costPrice)).toList(),
                          customerName: sale.customerName,
                          customerId: sale.customerId,
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        await repo.insertSale(refundSale);

                        // 3. Refresh Providers
                        if (mounted) {
                          await Provider.of<ReportsProvider>(context, listen: false).loadReports();
                          await Provider.of<ProductProvider>(context, listen: false).loadAll();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Return processed for Bill ${sale.billNo}. Stock restocked & profits updated!'),
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
}

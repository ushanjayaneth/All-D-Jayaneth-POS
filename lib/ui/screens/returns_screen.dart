import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/return_bill.dart';
import '../../models/cart_item.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<RepairsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.assignment_return, color: AppTheme.neonCyan, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Sales Returns & Refunds',
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
                '${prov.returns.length} Records',
                style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Record Return'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orangeWarning, foregroundColor: Colors.black),
              onPressed: () => _showAddReturnDialog(context),
            ),
          ),
        ],
      ),
      body: prov.returns.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_return_outlined, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No return bills recorded.', style: TextStyle(color: AppTheme.slateText, fontSize: 16)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Record Return / Refund'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orangeWarning, foregroundColor: Colors.black),
                    onPressed: () => _showAddReturnDialog(context),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: prov.returns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final ret = prov.returns[i];
                final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(ret.createdAt),
                );

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cyberBgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.redDanger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.redDanger.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.assignment_return, color: AppTheme.redDanger, size: 24),
                    ),
                    title: Text(
                      'Bill No: ${ret.saleBillNo}',
                      style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Date: $dateStr • Reason: ${ret.reason ?? 'General Return'}',
                      style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Refund Amount:', style: TextStyle(color: AppTheme.slateText, fontSize: 11)),
                        Text(
                          '${settings.currency} ${ret.refundAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.redDanger, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddReturnDialog(BuildContext context) {
    final billCtrl = TextEditingController();
    final itemCtrl = TextEditingController();
    final refundCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Row(
          children: [
            Icon(Icons.assignment_return, color: AppTheme.orangeWarning, size: 20),
            SizedBox(width: 8),
            Text('Record Return / Refund', style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: billCtrl,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Original Sale Bill No *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: itemCtrl,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Item Returned (Name / SKU) *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: refundCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.redDanger, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Refund Amount Paid *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Reason for Return'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orangeWarning, foregroundColor: Colors.black),
            onPressed: () async {
              if (billCtrl.text.trim().isEmpty || refundCtrl.text.trim().isEmpty) return;
              final refund = double.tryParse(refundCtrl.text) ?? 0.0;

              final ret = ReturnBill(
                saleBillNo: billCtrl.text.trim(),
                returnedItems: [
                  CartItem(
                    productId: 0,
                    name: itemCtrl.text.trim().isEmpty ? 'Returned Item' : itemCtrl.text.trim(),
                    price: refund,
                    costPrice: 0.0,
                    quantity: 1,
                  ),
                ],
                refundAmount: refund,
                reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              );

              final prov = Provider.of<RepairsProvider>(context, listen: false);
              await prov.processReturn(ret);
              Navigator.pop(ctx);
            },
            child: const Text('Save Return'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/pos_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class HeldBillsScreen extends StatefulWidget {
  const HeldBillsScreen({Key? key}) : super(key: key);

  @override
  State<HeldBillsScreen> createState() => _HeldBillsScreenState();
}

class _HeldBillsScreenState extends State<HeldBillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PosProvider>(context, listen: false).loadHeldBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pos = Provider.of<PosProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.pause_circle_filled, color: AppTheme.orangeWarning, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Held Orders & Cart Queue',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.orangeWarning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.orangeWarning.withOpacity(0.3)),
              ),
              child: Text(
                '${pos.heldBills.length} Held',
                style: const TextStyle(color: AppTheme.orangeWarning, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: pos.heldBills.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pause_circle_outline, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No held orders in queue.', style: TextStyle(color: AppTheme.slateText, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: pos.heldBills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final bill = pos.heldBills[i];
                final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(bill.createdAt),
                );

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cyberBgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.billNo,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.lightText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: $dateStr • Type: ${bill.saleType.toUpperCase()} • ${bill.items.length} items',
                              style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                            ),
                            if (bill.customerName != null) ...[
                              const SizedBox(height: 2),
                              Text('Customer: ${bill.customerName}', style: const TextStyle(fontSize: 12, color: AppTheme.neonCyan)),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '${settings.currency} ${bill.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.neonCyan),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Recall to Cart'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                        onPressed: () async {
                          await pos.restoreHeldBill(bill);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Order ${bill.billNo} restored to cart.'),
                                backgroundColor: AppTheme.greenSuccess,
                              ),
                            );
                            Navigator.pop(context); // Return to POS
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.redDanger, size: 20),
                        onPressed: () {
                          if (bill.id != null) {
                            pos.deleteHeldBill(bill.id!);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

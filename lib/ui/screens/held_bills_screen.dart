import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/settings_provider.dart';

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
      appBar: AppBar(
        title: const Text('Held Bills'),
      ),
      body: pos.heldBills.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pause_circle_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No held bills found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pos.heldBills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final bill = pos.heldBills[i];
                final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(bill.createdAt),
                );

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bill.billNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Date: $dateStr | Type: ${bill.saleType.toUpperCase()} | ${bill.items.length} items', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              if (bill.customerName != null)
                                Text('Customer: ${bill.customerName}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '${settings.currency} ${bill.total.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Recall to Cart'),
                          onPressed: () async {
                            await pos.restoreHeldBill(bill);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bill ${bill.billNo} restored to cart.')),
                            );
                            Navigator.pop(context); // Go to POS
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => pos.deleteHeldBill(bill.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

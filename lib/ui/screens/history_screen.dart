import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/printer_service.dart';
import '../../services/pdf_invoice_service.dart';
import '../../services/whatsapp_service.dart';
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
      return s.billNo.toLowerCase().contains(_search.toLowerCase()) ||
          (s.customerName != null && s.customerName!.toLowerCase().contains(_search.toLowerCase()));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Transaction History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by bill number or customer name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: filteredSales.isEmpty
                ? const Center(child: Text('No sales records found.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredSales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final sale = filteredSales[i];
                      final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(sale.createdAt),
                      );

                      return Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                            child: Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(sale.billNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${settings.currency} ${sale.total.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                          subtitle: Text('Date: $dateStr | ${sale.paymentMethod.toUpperCase()} | ${sale.customerName ?? 'Walk-in'}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Items Sold:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  ...sale.items.map((it) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('• ${it.name} x ${it.qty}'),
                                            Text('${settings.currency} ${it.subtotal.toStringAsFixed(2)}'),
                                          ],
                                        ),
                                      )),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.remove_red_eye, size: 16),
                                        label: const Text('View Slip'),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

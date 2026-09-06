import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/sale.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
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
}

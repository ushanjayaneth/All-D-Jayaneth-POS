import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../providers/settings_provider.dart';
import '../../services/printer_service.dart';
import '../../services/pdf_invoice_service.dart';
import '../../services/whatsapp_service.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final Sale sale;

  const ReceiptPreviewDialog({Key? key, required this.sale}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(sale.createdAt),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Receipt Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),

            // Visual Receipt Paper Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(settings.storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (settings.address.isNotEmpty)
                    Text(settings.address, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (settings.phone.isNotEmpty)
                    Text('Tel: ${settings.phone}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bill No: ${sale.billNo}', style: const TextStyle(fontSize: 11)),
                      Text('Type: ${sale.saleType.toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Date: $dateStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      if (sale.customerName != null)
                        Text('Customer: ${sale.customerName}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                  const Divider(),

                  // Item list
                  ...sale.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: Text(item.name, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text('${item.qty}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${settings.currency} ${item.subtotal.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NET TOTAL:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        '${settings.currency} ${sale.total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Mode:', style: TextStyle(fontSize: 11)),
                      Text(sale.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    onPressed: () => PrinterService.instance.printReceipt(
                      sale: sale,
                      settings: settings,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                    onPressed: () => PdfInvoiceService.generateAndSaveInvoice(
                      sale: sale,
                      settings: settings,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('WhatsApp'),
                    onPressed: () {
                      _showWhatsAppInputDialog(context, sale, settings);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWhatsAppInputDialog(BuildContext context, Sale sale, dynamic settings) {
    final phoneCtrl = TextEditingController(text: sale.customerName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send WhatsApp Bill'),
        content: TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Customer Phone (e.g. 0771234567)',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              WhatsAppService.sendReceipt(
                sale: sale,
                settings: settings,
                phoneNumber: phoneCtrl.text,
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

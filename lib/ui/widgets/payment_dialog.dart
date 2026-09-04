import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../providers/pos_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/printer_service.dart';
import '../../services/whatsapp_service.dart';
import 'receipt_preview_dialog.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentDialog({Key? key, required this.totalAmount}) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMethod = 'cash'; // 'cash', 'card', 'credit'
  final TextEditingController _paidAmountCtrl = TextEditingController();
  final TextEditingController _whatsappPhoneCtrl = TextEditingController();
  double _paidAmount = 0.0;
  bool _sendWhatsApp = false;
  bool _directPrint = true;

  @override
  void initState() {
    super.initState();
    _paidAmount = widget.totalAmount;
    _paidAmountCtrl.text = widget.totalAmount.toStringAsFixed(0);

    final pos = Provider.of<PosProvider>(context, listen: false);
    if (pos.selectedCustomer?.phone != null) {
      _whatsappPhoneCtrl.text = pos.selectedCustomer!.phone!;
      _sendWhatsApp = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final pos = Provider.of<PosProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final changeAmount = (_paidAmount - widget.totalAmount).clamp(0.0, double.infinity);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Finalize Payment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Total Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Payable:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    '${settings.currency} ${widget.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Mode Selector
            Row(
              children: [
                _paymentModeChip('Cash', 'cash', Icons.payments),
                const SizedBox(width: 8),
                _paymentModeChip('Card', 'card', Icons.credit_card),
                const SizedBox(width: 8),
                _paymentModeChip('Credit (Loan)', 'credit', Icons.account_balance_wallet),
              ],
            ),
            const SizedBox(height: 16),

            // Cash Mode Inputs
            if (_paymentMethod == 'cash') ...[
              TextField(
                controller: _paidAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Paid Amount (${settings.currency})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                onChanged: (val) {
                  setState(() {
                    _paidAmount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Quick Cash Suggestion Chips
              Wrap(
                spacing: 8,
                children: [500, 1000, 2000, 5000].map((note) {
                  return ActionChip(
                    label: Text('+$note'),
                    onPressed: () {
                      setState(() {
                        _paidAmount += note;
                        _paidAmountCtrl.text = _paidAmount.toStringAsFixed(0);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Change Due Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change Due:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    '${settings.currency} ${changeAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: changeAmount > 0 ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Credit Mode Customer requirement alert
            if (_paymentMethod == 'credit' && pos.selectedCustomer == null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '⚠️ Please select a customer first to issue a credit/loan bill.',
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),

            // WhatsApp Toggle
            Row(
              children: [
                Checkbox(
                  value: _sendWhatsApp,
                  onChanged: (v) => setState(() => _sendWhatsApp = v ?? false),
                ),
                const Text('Send WhatsApp Bill', style: TextStyle(fontSize: 13)),
              ],
            ),
            if (_sendWhatsApp) ...[
              TextField(
                controller: _whatsappPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Customer WhatsApp Phone (e.g. 0771234567)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.phone),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Direct Print Toggle
            Row(
              children: [
                Checkbox(
                  value: _directPrint,
                  onChanged: (v) => setState(() => _directPrint = v ?? true),
                ),
                const Text('Print Thermal Receipt', style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('COMPLETE TRANSACTION', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: (_paymentMethod == 'credit' && pos.selectedCustomer == null)
                    ? null
                    : () async {
                        final sale = await pos.checkout(
                          paymentMethod: _paymentMethod,
                          paidAmount: _paidAmount,
                          changeAmount: changeAmount,
                        );

                        if (sale != null && mounted) {
                          Navigator.pop(context);

                          if (_directPrint) {
                            await PrinterService.instance.printReceipt(
                              sale: sale,
                              settings: settings,
                            );
                          }

                          if (_sendWhatsApp && _whatsappPhoneCtrl.text.isNotEmpty) {
                            await WhatsAppService.sendReceipt(
                              sale: sale,
                              settings: settings,
                              phoneNumber: _whatsappPhoneCtrl.text,
                            );
                          }

                          showDialog(
                            context: context,
                            builder: (ctx) => ReceiptPreviewDialog(sale: sale),
                          );
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentModeChip(String label, String value, IconData icon) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).primaryColor : Colors.transparent,
            border: Border.all(
              color: selected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/printer_service.dart';
import '../../theme/app_theme.dart';

class DayEndScreen extends StatelessWidget {
  const DayEndScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;
    final summary = reportProv.generateDayEndSummary();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.point_of_sale, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'Day End Settlement & Cash Drawer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print Day End Slip'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () async {
                await PrinterService.instance.printDayEndReport(
                  summary: summary,
                  settings: settings,
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settlement Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cyberBgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Today: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.lightText)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${summary.totalBills} Bills Issued',
                          style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 20),
                  _summaryRow('Retail Revenue:', '${settings.currency} ${summary.retailSales.toStringAsFixed(2)}'),
                  _summaryRow('Wholesale Revenue:', '${settings.currency} ${summary.wholesaleSales.toStringAsFixed(2)}'),
                  const Divider(color: AppTheme.cardBorder, height: 16),
                  _summaryRow('TOTAL REVENUE:', '${settings.currency} ${summary.totalSales.toStringAsFixed(2)}', isBold: true, color: AppTheme.neonCyan),
                  const Divider(color: AppTheme.cardBorder, height: 16),
                  _summaryRow('Cash in Drawer (මුදල්):', '${settings.currency} ${summary.cashSales.toStringAsFixed(2)}', color: AppTheme.greenSuccess),
                  _summaryRow('Card Payments (කාඩ්පත්):', '${settings.currency} ${summary.cardSales.toStringAsFixed(2)}', color: AppTheme.neonCyan),
                  _summaryRow('Credit / Loans (ණය):', '${settings.currency} ${summary.creditSales.toStringAsFixed(2)}', color: AppTheme.orangeWarning),
                  const Divider(color: AppTheme.cardBorder, height: 16),
                  _summaryRow('Cost of Goods Sold (COGS):', '${settings.currency} ${summary.totalCost.toStringAsFixed(2)}'),
                  _summaryRow('Gross Profit:', '${settings.currency} ${summary.grossProfit.toStringAsFixed(2)}'),
                  _summaryRow('Daily Business Expenses:', '- ${settings.currency} ${summary.totalExpenses.toStringAsFixed(2)}', color: AppTheme.redDanger),
                  const Divider(color: AppTheme.cardBorder, height: 20, thickness: 1.5),
                  _summaryRow(
                    'NET PROFIT (සැබෑ ශුද්ධ ලාභය):',
                    '${settings.currency} ${summary.netProfit.toStringAsFixed(2)}',
                    isBold: true,
                    color: summary.netProfit >= 0 ? AppTheme.greenSuccess : AppTheme.redDanger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Expenses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Business Expenses (එදිනෙදා වියදම්)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                  onPressed: () => _showAddExpenseDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            reportProv.expenses.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cyberBgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: const Center(child: Text('No expenses recorded today.', style: TextStyle(color: AppTheme.slateText))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reportProv.expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final exp = reportProv.expenses[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cyberBgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.redDanger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.redDanger.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.receipt_long, color: AppTheme.redDanger, size: 20),
                          ),
                          title: Text(
                            exp.description ?? 'Expense',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.lightText),
                          ),
                          subtitle: Text('Type: ${exp.type.toUpperCase()}', style: const TextStyle(color: AppTheme.slateText, fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '- ${settings.currency} ${exp.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.redDanger, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.redDanger, size: 18),
                                onPressed: () {
                                  if (exp.id != null) {
                                    reportProv.deleteExpense(exp.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 13,
              color: isBold ? AppTheme.lightText : AppTheme.slateText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
              color: color ?? AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'Utilities';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.cyberBgSecondary,
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppTheme.neonCyan, size: 20),
              SizedBox(width: 8),
              Text('Add Business Expense', style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Expense Description *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Amount (මුදල) *'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: AppTheme.cyberBgSecondary,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Expense Type'),
                items: const [
                  DropdownMenuItem(value: 'Utilities', child: Text('Utilities (Electricity / Water / Tel)')),
                  DropdownMenuItem(value: 'Salary', child: Text('Staff Salary / Wages')),
                  DropdownMenuItem(value: 'Rent', child: Text('Shop Rent')),
                  DropdownMenuItem(value: 'Tea & Refreshments', child: Text('Tea / Food / Refreshments')),
                  DropdownMenuItem(value: 'Transport', child: Text('Transport / Delivery')),
                  DropdownMenuItem(value: 'Other', child: Text('Other Miscellaneous')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'Other'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (descCtrl.text.trim().isEmpty || amt <= 0) return;

                final exp = Expense(
                  amount: amt,
                  description: descCtrl.text.trim(),
                  type: type,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                );

                final prov = Provider.of<ReportsProvider>(context, listen: false);
                await prov.addExpense(exp);
                Navigator.pop(ctx);
              },
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}

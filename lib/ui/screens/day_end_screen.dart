import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/printer_service.dart';

class DayEndScreen extends StatelessWidget {
  const DayEndScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;
    final summary = reportProv.generateDayEndSummary();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day End Settlement & Expenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Print Day End Slip'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${summary.totalBills} Bills Issued', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    _summaryRow('Retail Revenue:', '${settings.currency} ${summary.retailSales.toStringAsFixed(2)}'),
                    _summaryRow('Wholesale Revenue:', '${settings.currency} ${summary.wholesaleSales.toStringAsFixed(2)}'),
                    const Divider(),
                    _summaryRow('TOTAL REVENUE:', '${settings.currency} ${summary.totalSales.toStringAsFixed(2)}', isBold: true),
                    const Divider(),
                    _summaryRow('Cash in Drawer:', '${settings.currency} ${summary.cashSales.toStringAsFixed(2)}'),
                    _summaryRow('Card Payments:', '${settings.currency} ${summary.cardSales.toStringAsFixed(2)}'),
                    _summaryRow('Credit (Loan) Bills:', '${settings.currency} ${summary.creditSales.toStringAsFixed(2)}'),
                    const Divider(),
                    _summaryRow('Cost of Goods (COGS):', '${settings.currency} ${summary.totalCost.toStringAsFixed(2)}'),
                    _summaryRow('Gross Profit:', '${settings.currency} ${summary.grossProfit.toStringAsFixed(2)}'),
                    _summaryRow('Total Expenses:', '- ${settings.currency} ${summary.totalExpenses.toStringAsFixed(2)}'),
                    const Divider(thickness: 1.5),
                    _summaryRow(
                      'NET PROFIT (ශුද්ධ ලාභය):',
                      '${settings.currency} ${summary.netProfit.toStringAsFixed(2)}',
                      isBold: true,
                      color: summary.netProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Expenses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Business Expenses (එදිනෙදා වියදම්)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Expense'),
                  onPressed: () => _showAddExpenseDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            reportProv.expenses.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No expenses recorded today.')),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reportProv.expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final exp = reportProv.expenses[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x22EF4444),
                            child: Icon(Icons.receipt_long, color: Colors.red),
                          ),
                          title: Text(exp.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Category: ${exp.category.toUpperCase()}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '- ${settings.currency} ${exp.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey, size: 18),
                                onPressed: () => reportProv.deleteExpense(exp.id),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 14 : 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 15 : 13, color: color)),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'utilities';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Business Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Expense Description *')),
              const SizedBox(height: 8),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount *')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'utilities', child: Text('Utilities (Electricity / Water / Tel)')),
                  DropdownMenuItem(value: 'salary', child: Text('Staff Salary / Wages')),
                  DropdownMenuItem(value: 'rent', child: Text('Shop Rent')),
                  DropdownMenuItem(value: 'tea_food', child: Text('Tea / Food / Refreshments')),
                  DropdownMenuItem(value: 'other', child: Text('Other Miscellaneous')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'other'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (descCtrl.text.trim().isEmpty || amt <= 0) return;

                final exp = Expense(
                  amount: amt,
                  description: descCtrl.text.trim(),
                  category: category,
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

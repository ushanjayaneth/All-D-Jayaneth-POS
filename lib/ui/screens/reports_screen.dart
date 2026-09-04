import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/csv_export_service.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports & Net Profit'),
        actions: [
          IconButton(
            tooltip: 'Export Sales to CSV (Excel)',
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              await CsvExportService.exportSalesToCsv(reportProv.sales);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sales report exported to CSV.')),
              );
            },
          ),
        ],
      ),
      body: reportProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips (Today / This Week / This Month / All)
                  Row(
                    children: [
                      _timeFilterChip('Today', 'today', reportProv),
                      const SizedBox(width: 8),
                      _timeFilterChip('This Week', 'this_week', reportProv),
                      const SizedBox(width: 8),
                      _timeFilterChip('This Month', 'this_month', reportProv),
                      const SizedBox(width: 8),
                      _timeFilterChip('All Time', 'all', reportProv),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Big Net Profit Highlight Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: reportProv.netProfit >= 0
                            ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                            : [const Color(0xFF450A0A), const Color(0xFF7F1D1D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: reportProv.netProfit >= 0 ? const Color(0xFF00D4FF) : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '💰 NET PROFIT ANALYSIS (සැබෑ ශුද්ධ ලාභය)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF)),
                            ),
                            Text(
                              '${reportProv.sales.length} Bills Processed',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${settings.currency} ${reportProv.netProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: reportProv.netProfit >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Formula: Total Sales - Cost of Goods Sold (COGS) - Business Expenses',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stat Cards Grid
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            title: 'Total Revenue (ආදායම)',
                            value: '${settings.currency} ${reportProv.totalRevenue.toStringAsFixed(2)}',
                            icon: Icons.payments,
                            color: const Color(0xFF00D4FF),
                          ),
                          StatCard(
                            title: 'Total Cost (ගන්නා මිල)',
                            value: '${settings.currency} ${reportProv.totalCost.toStringAsFixed(2)}',
                            icon: Icons.shopping_basket,
                            color: const Color(0xFFF59E0B),
                          ),
                          StatCard(
                            title: 'Gross Profit (දළ ලාභය)',
                            value: '${settings.currency} ${reportProv.grossProfit.toStringAsFixed(2)}',
                            icon: Icons.trending_up,
                            color: const Color(0xFF10B981),
                          ),
                          StatCard(
                            title: 'Total Expenses (වියදම්)',
                            value: '${settings.currency} ${reportProv.totalExpenses.toStringAsFixed(2)}',
                            icon: Icons.receipt_long,
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Payment Breakdown
                  const Text('Payment Collection Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _breakdownRow(context, '💵 Cash Collection', reportProv.cashSales, reportProv.totalRevenue, settings.currency, Colors.green),
                          const Divider(),
                          _breakdownRow(context, '💳 Card Payments', reportProv.cardSales, reportProv.totalRevenue, settings.currency, Colors.blue),
                          const Divider(),
                          _breakdownRow(context, '📑 Customer Credit (Loan)', reportProv.creditSales, reportProv.totalRevenue, settings.currency, Colors.orange),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _timeFilterChip(String label, String value, ReportsProvider prov) {
    final selected = prov.timeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (s) {
        if (s) prov.setTimeFilter(value);
      },
    );
  }

  Widget _breakdownRow(BuildContext context, String title, double amount, double total, String currency, Color color) {
    final percentage = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text('$currency ${amount.toStringAsFixed(2)} ($percentage%)', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

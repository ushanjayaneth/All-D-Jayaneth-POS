import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/csv_export_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isUnlocked = false;
  final TextEditingController _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsProvider>(context, listen: false).loadReports();
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'Financial Analytics & Net Profit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_isUnlocked) ...[
            IconButton(
              tooltip: 'Lock Reports',
              icon: const Icon(Icons.lock, color: AppTheme.orangeWarning),
              onPressed: () => setState(() {
                _isUnlocked = false;
                _pinCtrl.clear();
              }),
            ),
            IconButton(
              tooltip: 'Export Sales to CSV (Excel)',
              icon: const Icon(Icons.file_download, color: AppTheme.slateText),
              onPressed: () async {
                await CsvExportService.exportSalesToCsv(reportProv.sales);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sales report exported to CSV.'),
                      backgroundColor: AppTheme.greenSuccess,
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body: !_isUnlocked
          ? Center(
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cyberBgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.orangeWarning.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.orangeWarning),
                      ),
                      child: const Icon(Icons.lock, color: AppTheme.orangeWarning, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin PIN Required',
                      style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter Master Admin PIN to view sensitive revenues and profit analytics:',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.slateText, fontSize: 12.5),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _pinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: const TextStyle(color: AppTheme.neonCyan, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '••••',
                        counterText: '',
                        prefixIcon: Icon(Icons.password, color: AppTheme.neonCyan),
                      ),
                      onSubmitted: (_) => _verifyAdminPin(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text('Unlock Reports', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                        onPressed: _verifyAdminPin,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : reportProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips (Today / This Week / This Month / All)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
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
                  ),
                  const SizedBox(height: 16),

                  // Big Net Profit Highlight Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: reportProv.netProfit >= 0
                            ? [const Color(0xFF0F172A), const Color(0xFF0A2540)]
                            : [const Color(0xFF3B0D0C), const Color(0xFF1F0808)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: reportProv.netProfit >= 0 ? AppTheme.neonCyan : AppTheme.redDanger,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.monetization_on, color: AppTheme.neonCyan, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'NET PROFIT ANALYSIS',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.cyberBgTertiary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Text(
                                '${reportProv.sales.length} Bills Processed',
                                style: const TextStyle(fontSize: 11, color: AppTheme.slateText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${settings.currency} ${reportProv.netProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: reportProv.netProfit >= 0 ? AppTheme.greenSuccess : AppTheme.redDanger,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Formula: Total Sales - Cost of Goods Sold (COGS) - Business Expenses',
                          style: TextStyle(fontSize: 11, color: AppTheme.slateText),
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
                        childAspectRatio: 1.4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            title: 'Total Revenue',
                            value: '${settings.currency} ${reportProv.totalRevenue.toStringAsFixed(2)}',
                            icon: Icons.payments,
                            color: AppTheme.neonCyan,
                          ),
                          StatCard(
                            title: 'Total Cost',
                            value: '${settings.currency} ${reportProv.totalCost.toStringAsFixed(2)}',
                            icon: Icons.shopping_basket,
                            color: AppTheme.orangeWarning,
                          ),
                          StatCard(
                            title: 'Gross Profit',
                            value: '${settings.currency} ${reportProv.grossProfit.toStringAsFixed(2)}',
                            icon: Icons.trending_up,
                            color: AppTheme.greenSuccess,
                          ),
                          StatCard(
                            title: 'Total Expenses',
                            value: '${settings.currency} ${reportProv.totalExpenses.toStringAsFixed(2)}',
                            icon: Icons.receipt_long,
                            color: AppTheme.redDanger,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Payment Breakdown
                  const Text(
                    'Payment Collection Breakdown',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cyberBgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _breakdownRow(context, '💵 Cash Collection', reportProv.cashSales, reportProv.totalRevenue, settings.currency, AppTheme.greenSuccess),
                        const Divider(color: AppTheme.cardBorder, height: 16),
                        _breakdownRow(context, '💳 Card Payments', reportProv.cardSales, reportProv.totalRevenue, settings.currency, AppTheme.neonCyan),
                        const Divider(color: AppTheme.cardBorder, height: 16),
                        _breakdownRow(context, '📑 Customer Credit (Loan)', reportProv.creditSales, reportProv.totalRevenue, settings.currency, AppTheme.orangeWarning),
                      ],
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
      selectedColor: AppTheme.neonCyan,
      backgroundColor: AppTheme.cyberBgSecondary,
      labelStyle: TextStyle(
        color: selected ? Colors.black : AppTheme.slateText,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (s) {
        if (s) prov.setTimeFilter(value);
      },
    );
  }

  Widget _breakdownRow(BuildContext context, String title, double amount, double total, String currency, Color color) {
    final percentage = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        Text(
          '$currency ${amount.toStringAsFixed(2)} ($percentage%)',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
        ),
      ],
    );
  }

  void _verifyAdminPin() {
    final entered = _pinCtrl.text.trim();
    if (entered == '8514') {
      setState(() {
        _isUnlocked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin Access Granted ✅'),
          backgroundColor: AppTheme.greenSuccess,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _pinCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid Admin PIN. Access Denied.'),
          backgroundColor: AppTheme.redDanger,
        ),
      );
    }
  }
}

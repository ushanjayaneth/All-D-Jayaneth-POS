import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/repair_job.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class RepairsScreen extends StatefulWidget {
  const RepairsScreen({Key? key}) : super(key: key);

  @override
  State<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends State<RepairsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RepairsProvider>(context, listen: false).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repairProv = Provider.of<RepairsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.build_circle, color: AppTheme.neonCyan, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Device Repairs & Job Tickets',
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
                '${repairProv.repairs.length} Jobs',
                style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Repair Job'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () => _showRepairDialog(context, null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Tabs
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All Jobs', 'all', repairProv),
                _filterChip('Received (භාරගත්)', 'received', repairProv),
                _filterChip('In Progress (හදන ගමන්)', 'in_progress', repairProv),
                _filterChip('Ready (සාදා නිමකල)', 'ready', repairProv),
                _filterChip('Delivered (භාරදුන්)', 'delivered', repairProv),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: repairProv.filteredRepairs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_outlined, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('No repair jobs in this status.', style: TextStyle(color: AppTheme.slateText, fontSize: 16)),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Repair Ticket'),
                          onPressed: () => _showRepairDialog(context, null),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: repairProv.filteredRepairs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final job = repairProv.filteredRepairs[i];
                      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(job.createdAt));

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cyberBgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cyberBgTertiary,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.cardBorder),
                                      ),
                                      child: Text(
                                        'Job #: ${job.jobNo ?? 'REP'}',
                                        style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('($dateStr)', style: const TextStyle(color: AppTheme.dimText, fontSize: 11)),
                                  ],
                                ),
                                _statusBadge(job.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '📱 ${job.deviceModel}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                            ),
                            const SizedBox(height: 2),
                            Text('Issue: ${job.issueDescription}', style: const TextStyle(color: AppTheme.slateText, fontSize: 13)),
                            const Divider(color: AppTheme.cardBorder, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '👤 ${job.customerName} (${job.customerPhone ?? 'No Phone'})',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.slateText),
                                ),
                                Text(
                                  'Est: ${settings.currency} ${job.estimatedCost.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cyberBgTertiary,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: DropdownButton<String>(
                                    value: job.status.toLowerCase(),
                                    underline: const SizedBox(),
                                    dropdownColor: AppTheme.cyberBgSecondary,
                                    style: const TextStyle(color: AppTheme.lightText, fontSize: 12),
                                    items: const [
                                      DropdownMenuItem(value: 'received', child: Text('Status: Received')),
                                      DropdownMenuItem(value: 'in_progress', child: Text('Status: In Progress')),
                                      DropdownMenuItem(value: 'ready', child: Text('Status: Ready')),
                                      DropdownMenuItem(value: 'delivered', child: Text('Status: Delivered')),
                                    ],
                                    onChanged: (newStatus) {
                                      if (newStatus != null && job.id != null) {
                                        repairProv.updateRepairStatus(job.id!, newStatus);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.redDanger, size: 19),
                                  onPressed: () {
                                    if (job.id != null) {
                                      repairProv.deleteRepair(job.id!);
                                    }
                                  },
                                ),
                              ],
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

  Widget _filterChip(String label, String value, RepairsProvider prov) {
    final isSel = prov.statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        selectedColor: AppTheme.neonCyan,
        backgroundColor: AppTheme.cyberBgSecondary,
        labelStyle: TextStyle(
          color: isSel ? Colors.black : AppTheme.slateText,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (s) {
          if (s) prov.setStatusFilter(value);
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'received':
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue;
        label = 'Received';
        break;
      case 'in_progress':
        bg = AppTheme.orangeWarning.withOpacity(0.15);
        fg = AppTheme.orangeWarning;
        label = 'In Progress';
        break;
      case 'ready':
        bg = AppTheme.greenSuccess.withOpacity(0.15);
        fg = AppTheme.greenSuccess;
        label = 'Ready';
        break;
      case 'delivered':
        bg = AppTheme.neonPurple.withOpacity(0.15);
        fg = AppTheme.neonPurple;
        label = 'Delivered';
        break;
      default:
        bg = AppTheme.slateText.withOpacity(0.15);
        fg = AppTheme.slateText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  void _showRepairDialog(BuildContext context, RepairJob? job) {
    final custNameCtrl = TextEditingController(text: job?.customerName ?? '');
    final phoneCtrl = TextEditingController(text: job?.customerPhone ?? '');
    final modelCtrl = TextEditingController(text: job?.deviceModel ?? '');
    final issueCtrl = TextEditingController(text: job?.issueDescription ?? '');
    final costCtrl = TextEditingController(text: job?.estimatedCost != null ? job!.estimatedCost.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Row(
          children: [
            Icon(Icons.build, color: AppTheme.neonCyan, size: 20),
            SizedBox(width: 8),
            Text('Add Repair Job Ticket', style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: custNameCtrl, style: const TextStyle(color: AppTheme.lightText), decoration: const InputDecoration(labelText: 'Customer Name *')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.lightText), decoration: const InputDecoration(labelText: 'Customer Phone (දුරකථන අංකය)')),
                const SizedBox(height: 10),
                TextField(controller: modelCtrl, style: const TextStyle(color: AppTheme.lightText), decoration: const InputDecoration(labelText: 'Device Model (e.g. Samsung A12) *')),
                const SizedBox(height: 10),
                TextField(controller: issueCtrl, style: const TextStyle(color: AppTheme.lightText), decoration: const InputDecoration(labelText: 'Fault / Issue Description (දෝෂය) *')),
                const SizedBox(height: 10),
                TextField(controller: costCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.lightText), decoration: const InputDecoration(labelText: 'Estimated Repair Cost (ඇස්තමේන්තු මුදල)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
            onPressed: () async {
              if (custNameCtrl.text.trim().isEmpty || modelCtrl.text.trim().isEmpty) return;
              final jobNo = 'REP-${DateFormat('yyMMddHHmm').format(DateTime.now())}';
              final newJob = RepairJob(
                jobNo: jobNo,
                customerName: custNameCtrl.text.trim(),
                customerPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                deviceModel: modelCtrl.text.trim(),
                issueDescription: issueCtrl.text.trim(),
                estimatedCost: double.tryParse(costCtrl.text) ?? 0.0,
                status: 'received',
                createdAt: DateTime.now().millisecondsSinceEpoch,
              );

              final prov = Provider.of<RepairsProvider>(context, listen: false);
              await prov.saveRepair(newJob);
              Navigator.pop(ctx);
            },
            child: const Text('Create Ticket'),
          ),
        ],
      ),
    );
  }
}

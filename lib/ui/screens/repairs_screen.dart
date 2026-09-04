import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/repair_job.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/settings_provider.dart';

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
      appBar: AppBar(
        title: const Text('Device Repairs & Job Tickets'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New Repair Job'),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
          Expanded(
            child: repairProv.filteredRepairs.isEmpty
                ? const Center(child: Text('No repair jobs in this status.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: repairProv.filteredRepairs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final job = repairProv.filteredRepairs[i];
                      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(job.createdAt));

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Job #: ${job.jobNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  _statusBadge(job.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('📱 ${job.deviceModel}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('Issue: ${job.issueDescription}', style: const TextStyle(color: Colors.grey)),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('👤 ${job.customerName} (${job.customerPhone ?? 'No Phone'})', style: const TextStyle(fontSize: 12)),
                                  Text(
                                    'Est: ${settings.currency} ${job.estimatedCost.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  DropdownButton<String>(
                                    value: job.status,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'received', child: Text('Status: Received')),
                                      DropdownMenuItem(value: 'in_progress', child: Text('Status: In Progress')),
                                      DropdownMenuItem(value: 'ready', child: Text('Status: Ready')),
                                      DropdownMenuItem(value: 'delivered', child: Text('Status: Delivered')),
                                    ],
                                    onChanged: (newStatus) {
                                      if (newStatus != null) {
                                        repairProv.updateRepairStatus(job.id, newStatus);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => repairProv.deleteRepair(job.id),
                                  ),
                                ],
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

  Widget _filterChip(String label, String value, RepairsProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: prov.statusFilter == value,
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

    switch (status) {
      case 'received':
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue;
        label = 'Received';
        break;
      case 'in_progress':
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange;
        label = 'In Progress';
        break;
      case 'ready':
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green;
        label = 'Ready';
        break;
      case 'delivered':
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple;
        label = 'Delivered';
        break;
      default:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  void _showRepairDialog(BuildContext context, RepairJob? job) {
    final custNameCtrl = TextEditingController(text: job?.customerName ?? '');
    final phoneCtrl = TextEditingController(text: job?.customerPhone ?? '');
    final modelCtrl = TextEditingController(text: job?.deviceModel ?? '');
    final issueCtrl = TextEditingController(text: job?.issueDescription ?? '');
    final costCtrl = TextEditingController(text: job?.estimatedCost.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Repair Job Ticket'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: custNameCtrl, decoration: const InputDecoration(labelText: 'Customer Name *')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Customer Phone')),
                const SizedBox(height: 8),
                TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Device Model (e.g. Samsung A12) *')),
                const SizedBox(height: 8),
                TextField(controller: issueCtrl, decoration: const InputDecoration(labelText: 'Fault / Issue Description *')),
                const SizedBox(height: 8),
                TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimated Cost')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
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

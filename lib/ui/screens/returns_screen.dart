import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/settings_provider.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<RepairsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Returns & Refunds'),
      ),
      body: prov.returns.isEmpty
          ? const Center(child: Text('No return bills recorded.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: prov.returns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final ret = prov.returns[i];
                final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(ret.createdAt));

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x22EF4444),
                      child: Icon(Icons.assignment_return, color: Colors.red),
                    ),
                    title: Text('Sale Bill: ${ret.saleBillNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Date: $dateStr | Reason: ${ret.reason ?? 'N/A'}'),
                    trailing: Text(
                      'Refund: ${settings.currency} ${ret.refundAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

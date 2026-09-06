import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final customerProv = Provider.of<CustomerProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.people_alt, color: AppTheme.neonCyan, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Customers & Credit Ledger',
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
                '${customerProv.customers.length} Accounts',
                style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Customer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () => _showCustomerDialog(context, null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              style: const TextStyle(color: AppTheme.lightText),
              decoration: InputDecoration(
                hintText: 'Search customers by name or phone...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.neonCyan),
                isDense: true,
              ),
              onChanged: (val) => customerProv.setSearchQuery(val),
            ),
          ),
          Expanded(
            child: customerProv.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
                : customerProv.filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text('No customers found.', style: TextStyle(color: AppTheme.slateText, fontSize: 16)),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add First Customer'),
                              onPressed: () => _showCustomerDialog(context, null),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: customerProv.filteredCustomers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = customerProv.filteredCustomers[i];
                          final hasDue = c.totalDue > 0;

                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cyberBgSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: hasDue ? AppTheme.redDanger.withOpacity(0.12) : AppTheme.greenSuccess.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: hasDue ? AppTheme.redDanger.withOpacity(0.4) : AppTheme.greenSuccess.withOpacity(0.4)),
                                ),
                                child: Icon(Icons.person, color: hasDue ? AppTheme.redDanger : AppTheme.greenSuccess, size: 24),
                              ),
                              title: Text(
                                c.name,
                                style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                'Tel: ${c.phone ?? 'No Phone'} • ${c.address ?? 'No Address'}',
                                style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        hasDue ? 'Credit Due:' : 'Status: Clear',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: hasDue ? AppTheme.redDanger : AppTheme.greenSuccess,
                                        ),
                                      ),
                                      Text(
                                        '${settings.currency} ${c.totalDue.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: hasDue ? AppTheme.redDanger : AppTheme.greenSuccess,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  if (hasDue)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.greenSuccess,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () => _showPaymentCollectionDialog(context, c, settings),
                                      child: const Text('Pay Due', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 19, color: AppTheme.slateText),
                                    onPressed: () => _showCustomerDialog(context, c),
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

  void _showCustomerDialog(BuildContext context, Customer? customer) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: Row(
          children: [
            Icon(customer == null ? Icons.person_add : Icons.edit, color: AppTheme.neonCyan, size: 20),
            const SizedBox(width: 8),
            Text(
              customer == null ? 'Add Customer' : 'Edit Customer',
              style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Customer Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Phone Number (දුරකථන අංකය)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Address (ලිපිනය)'),
              ),
            ],
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
              if (nameCtrl.text.trim().isEmpty) return;
              final c = Customer(
                id: customer?.id,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                totalDue: customer?.totalDue ?? 0.0,
                syncId: customer?.syncId ?? const Uuid().v4(),
                synced: 0,
              );
              final prov = Provider.of<CustomerProvider>(context, listen: false);
              await prov.saveCustomer(c);
              Navigator.pop(ctx);
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  void _showPaymentCollectionDialog(BuildContext context, Customer customer, dynamic settings) {
    final amountCtrl = TextEditingController(text: customer.totalDue.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: Row(
          children: [
            const Icon(Icons.payments, color: AppTheme.greenSuccess, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Collect Payment - ${customer.name}',
                style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.redDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.redDanger.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding Balance:', style: TextStyle(color: AppTheme.slateText, fontSize: 12)),
                  Text(
                    '${settings.currency} ${customer.totalDue.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.redDanger, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'Amount Paid (ගෙවූ මුදල) *'),
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
              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amt <= 0 || customer.id == null) return;
              final prov = Provider.of<CustomerProvider>(context, listen: false);
              await prov.collectPayment(customer.id!, amt);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }
}

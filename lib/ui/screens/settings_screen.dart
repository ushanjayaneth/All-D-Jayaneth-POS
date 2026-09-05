import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _currencyCtrl = TextEditingController();
  final TextEditingController _headerCtrl = TextEditingController();
  final TextEditingController _footerCtrl = TextEditingController();
  String _paperSize = '80mm';

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    _storeNameCtrl.text = settings.storeName;
    _addressCtrl.text = settings.address;
    _phoneCtrl.text = settings.phone;
    _currencyCtrl.text = settings.currency;
    _headerCtrl.text = settings.receiptHeader;
    _footerCtrl.text = settings.receiptFooter;
    _paperSize = settings.paperSize;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);
    final settings = settingsProv.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings & Configuration'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              onPressed: () async {
                final updated = settings.copyWith(
                  storeName: _storeNameCtrl.text.trim(),
                  address: _addressCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                  currency: _currencyCtrl.text.trim(),
                  receiptHeader: _headerCtrl.text.trim(),
                  receiptFooter: _footerCtrl.text.trim(),
                  paperSize: _paperSize,
                );
                await settingsProv.updateSettings(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings updated successfully.')),
                );
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Toggle
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode (අඳුරු තේමාව)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Toggle between sleek dark & light theme'),
              value: settings.isDarkMode,
              onChanged: (v) => settingsProv.toggleTheme(),
            ),
          ),
          const SizedBox(height: 16),

          // Store Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Store & Business Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(controller: _storeNameCtrl, decoration: const InputDecoration(labelText: 'Store / Business Name *', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Store Address', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _currencyCtrl, decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. Rs. or \$)', border: OutlineInputBorder()))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Printer Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Receipt & Thermal Printer Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paperSize,
                    decoration: const InputDecoration(labelText: 'Thermal Paper Width', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '58mm', child: Text('58mm (Small Thermal Printer)')),
                      DropdownMenuItem(value: '72mm', child: Text('72mm (Medium Thermal Printer)')),
                      DropdownMenuItem(value: '80mm', child: Text('80mm (Standard POS Thermal Printer)')),
                    ],
                    onChanged: (v) => setState(() => _paperSize = v ?? '80mm'),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _headerCtrl, decoration: const InputDecoration(labelText: 'Receipt Header Note', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _footerCtrl, decoration: const InputDecoration(labelText: 'Receipt Footer Note / Policy', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/backup_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/pdf_invoice_service.dart';
import '../../theme/app_theme.dart';
import '../../models/sale.dart';
import '../../models/cart_item.dart';

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
  final TextEditingController _lowStockCtrl = TextEditingController();
  final TextEditingController _headerCtrl = TextEditingController();
  final TextEditingController _footerCtrl = TextEditingController();
  final TextEditingController _firebaseUrlCtrl = TextEditingController();

  String _paperSize = '80mm';
  String _printerType = 'system';
  bool _autoPrint = true;
  bool _isSaving = false;
  bool _isSyncingCloud = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    _storeNameCtrl.text = settings.storeName;
    _addressCtrl.text = settings.address;
    _phoneCtrl.text = settings.phone;
    _currencyCtrl.text = settings.currency;
    _lowStockCtrl.text = settings.lowStockAlert.toString();
    _headerCtrl.text = settings.receiptHeader;
    _footerCtrl.text = settings.receiptFooter;
    _firebaseUrlCtrl.text = settings.firebaseRtdbUrl ?? '';
    _paperSize = settings.paperSize;
    _printerType = settings.printerType;
    _autoPrint = settings.autoPrint;
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _currencyCtrl.dispose();
    _lowStockCtrl.dispose();
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    _firebaseUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);
    final syncProv = Provider.of<SyncProvider>(context);
    final settings = settingsProv.settings;

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'System Settings & Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.save, size: 18),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: _isSaving ? null : () => _saveSettings(context),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. Business & Store Profile
          _buildSectionHeader(Icons.storefront, 'Store & Business Profile (ව්‍යාපාරික විස්තර)'),
          _buildCard([
            TextField(
              controller: _storeNameCtrl,
              style: const TextStyle(color: AppTheme.lightText),
              decoration: const InputDecoration(labelText: 'Store / Business Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              style: const TextStyle(color: AppTheme.lightText),
              decoration: const InputDecoration(labelText: 'Store Address (ලිපිනය)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    style: const TextStyle(color: AppTheme.lightText),
                    decoration: const InputDecoration(labelText: 'Contact Phone Number (දුරකථන අංකය)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _currencyCtrl,
                    style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. Rs. or \$)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lowStockCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.orangeWarning),
                    decoration: const InputDecoration(labelText: 'Low Stock Alert Limit (අවම තොග සීමාව)'),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 20),

          // 2. Firebase Cloud Auto-Sync
          _buildSectionHeader(Icons.cloud_sync, 'Firebase Cloud Realtime Sync (ඔන්ලයින් ඩේටා සම්බන්දතාවය)'),
          _buildCard([
            Row(
              children: [
                // Live Sync Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: syncProv.status == SyncStatus.ok
                        ? AppTheme.greenSuccess.withOpacity(0.15)
                        : syncProv.status == SyncStatus.syncing
                            ? AppTheme.orangeWarning.withOpacity(0.15)
                            : AppTheme.redDanger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: syncProv.status == SyncStatus.ok
                          ? AppTheme.greenSuccess
                          : syncProv.status == SyncStatus.syncing
                              ? AppTheme.orangeWarning
                              : AppTheme.redDanger,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: syncProv.status == SyncStatus.ok
                            ? AppTheme.greenSuccess
                            : syncProv.status == SyncStatus.syncing
                                ? AppTheme.orangeWarning
                                : AppTheme.redDanger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        syncProv.status == SyncStatus.ok
                            ? 'Cloud Synced (ඔන්ලයින්)'
                            : syncProv.status == SyncStatus.syncing
                                ? 'Syncing... (සම්බන්ද වෙමින්)'
                                : 'Offline / Not Connected (ඕෆ්ලයින්)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: syncProv.status == SyncStatus.ok
                              ? AppTheme.greenSuccess
                              : syncProv.status == SyncStatus.syncing
                                  ? AppTheme.orangeWarning
                                  : AppTheme.redDanger,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  syncProv.statusMessage,
                  style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firebaseUrlCtrl,
              style: const TextStyle(color: AppTheme.neonCyan),
              decoration: InputDecoration(
                labelText: 'Firebase Database URL (e.g. https://your-pos-rtdb.firebaseio.com)',
                hintText: 'https://project-id-default-rtdb.firebaseio.com',
                prefixIcon: const Icon(Icons.link, color: AppTheme.neonCyan),
                suffixIcon: IconButton(
                  tooltip: 'Paste URL',
                  icon: const Icon(Icons.paste, color: AppTheme.slateText),
                  onPressed: () async {
                    // Paste trigger handled via standard OS clipboard
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: _isSyncingCloud
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.cloud_download, size: 16),
                  label: const Text('Connect & Pull Cloud Data (ඩේටා ලබාගන්න)'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                  onPressed: _isSyncingCloud ? null : () => _connectAndPullCloudData(context),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync, size: 16, color: AppTheme.neonCyan),
                  label: const Text('Sync Now (Push & Pull)', style: TextStyle(color: AppTheme.lightText)),
                  onPressed: () async {
                    await syncProv.triggerSyncNow();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sync triggered.'), backgroundColor: AppTheme.greenSuccess),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 Note: Once configured, offline changes are automatically saved locally and uploaded to Firebase as soon as an internet connection is available.',
              style: TextStyle(color: AppTheme.dimText, fontSize: 12),
            ),
          ]),

          const SizedBox(height: 20),

          // 3. Security & Admin PIN
          _buildSectionHeader(Icons.security, 'Security & Admin PIN Protection (ආරක්ෂක කේතය)'),
          _buildCard([
            Row(
              children: [
                const Icon(Icons.lock, color: AppTheme.orangeWarning, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin PIN Protection',
                        style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Current PIN: •••• (Default: 1234, Master Reset: 9999)',
                        style: const TextStyle(color: AppTheme.slateText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pin, size: 16),
                  label: const Text('Change Admin PIN'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orangeWarning, foregroundColor: Colors.black),
                  onPressed: () => _showChangePinDialog(context),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 20),

          // 4. Receipt & Thermal Printer Setup
          _buildSectionHeader(Icons.print, 'Receipt & Thermal Printer Setup (ප්‍රින්ටර් සැකසුම්)'),
          _buildCard([
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _printerType,
                    dropdownColor: AppTheme.cyberBgSecondary,
                    style: const TextStyle(color: AppTheme.lightText),
                    decoration: const InputDecoration(labelText: 'Printer Connection Mode'),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System Default / USB Printer')),
                      DropdownMenuItem(value: 'bluetooth', child: Text('Bluetooth Thermal Printer')),
                      DropdownMenuItem(value: 'network', child: Text('Network / LAN POS Printer')),
                    ],
                    onChanged: (v) => setState(() => _printerType = v ?? 'system'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paperSize,
                    dropdownColor: AppTheme.cyberBgSecondary,
                    style: const TextStyle(color: AppTheme.lightText),
                    decoration: const InputDecoration(labelText: 'Thermal Paper Width'),
                    items: const [
                      DropdownMenuItem(value: '58mm', child: Text('58mm (Small Thermal Printer)')),
                      DropdownMenuItem(value: '80mm', child: Text('80mm (Standard POS Printer)')),
                    ],
                    onChanged: (v) => setState(() => _paperSize = v ?? '80mm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-Print Receipt after Checkout', style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Automatically open printer dialog when a sale is completed', style: TextStyle(color: AppTheme.slateText, fontSize: 12)),
              value: _autoPrint,
              activeColor: AppTheme.neonCyan,
              onChanged: (v) => setState(() => _autoPrint = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _headerCtrl,
              style: const TextStyle(color: AppTheme.lightText),
              decoration: const InputDecoration(labelText: 'Receipt Header Message'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _footerCtrl,
              style: const TextStyle(color: AppTheme.lightText),
              decoration: const InputDecoration(labelText: 'Receipt Footer / Policy Note'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long, size: 16, color: AppTheme.neonCyan),
              label: const Text('Print Test Receipt (ප්‍රින්ටර් එක ටෙස්ට් කරන්න)', style: TextStyle(color: AppTheme.lightText)),
              onPressed: () => _printTestReceipt(context),
            ),
          ]),

          const SizedBox(height: 20),

          // 5. Data Management (JSON Backup, Restore, Factory Reset)
          _buildSectionHeader(Icons.storage, 'Data Management & Backup (දත්ත සුරැකීම සහ ප්‍රතිස්ථාපනය)'),
          _buildCard([
            const Text(
              'Safely backup your local database to a standalone JSON file, or restore existing data.',
              style: TextStyle(color: AppTheme.slateText, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download / Export JSON Backup'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                  onPressed: () => _exportJsonBackup(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload, size: 16, color: AppTheme.neonCyan),
                  label: const Text('Restore from JSON Backup', style: TextStyle(color: AppTheme.lightText)),
                  onPressed: () => _restoreJsonBackup(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, size: 16, color: AppTheme.redDanger),
                  label: const Text('System Factory Reset (සියලු දත්ත මකන්න)', style: TextStyle(color: AppTheme.redDanger)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.redDanger)),
                  onPressed: () => _showFactoryResetDialog(context),
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cyberBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<void> _saveSettings(BuildContext context) async {
    setState(() => _isSaving = true);
    final prov = Provider.of<SettingsProvider>(context, listen: false);
    final current = prov.settings;

    final updated = current.copyWith(
      storeName: _storeNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      currency: _currencyCtrl.text.trim().isEmpty ? 'Rs.' : _currencyCtrl.text.trim(),
      lowStockAlert: int.tryParse(_lowStockCtrl.text) ?? 5,
      receiptHeader: _headerCtrl.text.trim(),
      receiptFooter: _footerCtrl.text.trim(),
      firebaseRtdbUrl: _firebaseUrlCtrl.text.trim().isEmpty ? null : _firebaseUrlCtrl.text.trim(),
      paperSize: _paperSize,
      printerType: _printerType,
      autoPrint: _autoPrint,
    );

    await prov.updateSettings(updated);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppTheme.greenSuccess,
        ),
      );
    }
  }

  Future<void> _connectAndPullCloudData(BuildContext context) async {
    final url = _firebaseUrlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Firebase Database URL.')),
      );
      return;
    }

    setState(() => _isSyncingCloud = true);

    // Save URL first
    final prov = Provider.of<SettingsProvider>(context, listen: false);
    await prov.updateSettings(prov.settings.copyWith(firebaseRtdbUrl: url));

    // Pull cloud data
    await FirebaseSyncService.instance.syncAll(url);

    // Reload products and customers to reflect in local UI
    if (mounted) {
      await Provider.of<ProductProvider>(context, listen: false).loadAll();
      await Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    }

    setState(() => _isSyncingCloud = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud sync completed! Local items and records updated.'),
          backgroundColor: AppTheme.greenSuccess,
        ),
      );
    }
  }

  void _showChangePinDialog(BuildContext context) {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Row(
          children: [
            Icon(Icons.pin, color: AppTheme.orangeWarning, size: 20),
            SizedBox(width: 8),
            Text('Change Admin PIN', style: TextStyle(color: AppTheme.lightText, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Current PIN (Default: 1234)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'New PIN (4 Digits)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.lightText),
                decoration: const InputDecoration(labelText: 'Confirm New PIN'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orangeWarning, foregroundColor: Colors.black),
            onPressed: () async {
              if (newPinCtrl.text.trim().length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be at least 4 digits.')),
                );
                return;
              }
              if (newPinCtrl.text.trim() != confirmPinCtrl.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New PIN and Confirm PIN do not match.')),
                );
                return;
              }

              final prov = Provider.of<SettingsProvider>(context, listen: false);
              final success = await prov.changeAdminPin(currentPinCtrl.text.trim(), newPinCtrl.text.trim());
              if (success) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin PIN changed successfully!'), backgroundColor: AppTheme.greenSuccess),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect current PIN.'), backgroundColor: AppTheme.redDanger),
                  );
                }
              }
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _printTestReceipt(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    final testSale = Sale(
      billNo: 'TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      saleType: 'retail',
      subtotal: 1500.0,
      discount: 0.0,
      total: 1500.0,
      paymentMethod: 'Cash',
      paidAmount: 2000.0,
      changeAmount: 500.0,
      items: [
        CartItem(
          productId: 1,
          name: 'Demo Test Product',
          price: 1500.0,
          costPrice: 1200.0,
          quantity: 1,
        ),
      ],
      cashierName: 'Admin',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await PdfInvoiceService.printReceipt(testSale, settings);
  }

  Future<void> _exportJsonBackup(BuildContext context) async {
    try {
      final jsonStr = await BackupService.generateBackupJson();
      final bytes = utf8.encode(jsonStr);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final filename = 'MY_POS_Backup_$timestamp.json';

      // Use FilePicker or standard share/save
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save POS Backup JSON',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? 'Backup saved to $path' : 'Backup generated successfully.'),
            backgroundColor: AppTheme.greenSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.redDanger),
        );
      }
    }
  }

  Future<void> _restoreJsonBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final jsonStr = utf8.decode(bytes);
          final success = await BackupService.restoreFromBackupJson(jsonStr);
          if (success) {
            if (mounted) {
              await Provider.of<ProductProvider>(context, listen: false).loadAll();
              await Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
              await Provider.of<SettingsProvider>(context, listen: false).loadSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database restored successfully!'), backgroundColor: AppTheme.greenSuccess),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid backup file format.'), backgroundColor: AppTheme.redDanger),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: AppTheme.redDanger),
        );
      }
    }
  }

  void _showFactoryResetDialog(BuildContext context) {
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.redDanger, size: 22),
            SizedBox(width: 8),
            Text('Factory Reset System', style: TextStyle(color: AppTheme.redDanger, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ WARNING: This will permanently erase all local products, categories, sales, held bills, customers, expenses, and repair records!\n\nEnter Admin PIN to confirm:',
              style: TextStyle(color: AppTheme.lightText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.lightText),
              decoration: const InputDecoration(labelText: 'Admin PIN (Default: 1234)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redDanger, foregroundColor: Colors.white),
            onPressed: () async {
              final prov = Provider.of<SettingsProvider>(context, listen: false);
              if (!prov.verifyPin(pinCtrl.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect Admin PIN.'), backgroundColor: AppTheme.redDanger),
                );
                return;
              }

              await BackupService.factoryReset();
              if (mounted) {
                await Provider.of<ProductProvider>(context, listen: false).loadAll();
                await Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('System factory reset completed. Database cleared.'), backgroundColor: AppTheme.greenSuccess),
                );
              }
            },
            child: const Text('Confirm Factory Reset'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../providers/settings_provider.dart';
import 'screens/pos_screen.dart';
import 'screens/products_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/held_bills_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/day_end_screen.dart';
import 'screens/repairs_screen.dart';
import 'screens/returns_screen.dart';
import 'screens/barcodes_screen.dart';
import 'screens/settings_screen.dart';

class MainNavigationLayout extends StatefulWidget {
  const MainNavigationLayout({Key? key}) : super(key: key);

  @override
  State<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends State<MainNavigationLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PosScreen(),
    ProductsScreen(),
    CategoriesScreen(),
    CustomersScreen(),
    HeldBillsScreen(),
    HistoryScreen(),
    ReportsScreen(),
    DayEndScreen(),
    RepairsScreen(),
    ReturnsScreen(),
    BarcodesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final pos = Provider.of<PosProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1200,
              minExtendedWidth: 200,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.point_of_sale, size: 28, color: Theme.of(context).primaryColor),
                    ),
                    if (MediaQuery.of(context).size.width > 1200) ...[
                      const SizedBox(height: 8),
                      Text(
                        settings.storeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('POS Billing')),
                const NavigationRailDestination(icon: Icon(Icons.inventory_2), label: Text('Products')),
                const NavigationRailDestination(icon: Icon(Icons.category), label: Text('Categories')),
                const NavigationRailDestination(icon: Icon(Icons.people), label: Text('Customers')),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text('${pos.heldBills.length}'),
                    isLabelVisible: pos.heldBills.isNotEmpty,
                    child: const Icon(Icons.pause_circle_outline),
                  ),
                  label: const Text('Held Bills'),
                ),
                const NavigationRailDestination(icon: Icon(Icons.history), label: Text('Sales History')),
                const NavigationRailDestination(icon: Icon(Icons.insights), label: Text('Reports & Profit')),
                const NavigationRailDestination(icon: Icon(Icons.wb_twilight), label: Text('Day End')),
                const NavigationRailDestination(icon: Icon(Icons.build), label: Text('Repairs')),
                const NavigationRailDestination(icon: Icon(Icons.assignment_return), label: Text('Returns')),
                const NavigationRailDestination(icon: Icon(Icons.qr_code_2), label: Text('Barcodes')),
                const NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }

    // Mobile Bottom Navigation
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
        onDestinationSelected: (idx) {
          if (idx == 4) {
            _showMoreBottomSheet(context);
          } else {
            setState(() => _selectedIndex = idx);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }

  void _showMoreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: const Text('Held Bills'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Sales History'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 5);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_twilight),
              title: const Text('Day End Settlement'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 7);
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Repairs Management'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 8);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Returns & Refunds'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 9);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Barcode Labels'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 10);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = 11);
              },
            ),
          ],
        ),
      ),
    );
  }
}

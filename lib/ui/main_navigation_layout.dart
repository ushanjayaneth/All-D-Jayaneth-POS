import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../theme/app_theme.dart';
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
  State<MainNavigationLayout> createState() => MainNavigationLayoutState();

  static MainNavigationLayoutState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationLayoutState>();
  }
}

class MainNavigationLayoutState extends State<MainNavigationLayout> {
  int selectedIndex = 0;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void navigateTo(int index) {
    setState(() => selectedIndex = index);
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

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
    final sync = Provider.of<SyncProvider>(context);

    return Scaffold(
      key: scaffoldKey,
      drawer: _buildDrawer(context, settings.storeName, sync.isOnline, pos.heldBills.length),
      body: Row(
        children: [
          if (isDesktop) ...[
            _buildDesktopRail(context, settings.storeName, sync.isOnline, pos.heldBills.length),
            const VerticalDivider(width: 1, color: AppTheme.cardBorder),
          ],
          Expanded(child: _screens[selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String storeName, bool isOnline, int heldBillsCount) {
    final drawerItems = [
      _DrawerEntry(0, '🏪 POS (Sales)', Icons.point_of_sale),
      _DrawerEntry(1, '📦 Products (Inventory)', Icons.inventory_2),
      _DrawerEntry(2, '🏷️ Categories', Icons.category),
      _DrawerEntry(3, '👥 Customers & Loans', Icons.people),
      _DrawerEntry(4, '⏸ Held Bills', Icons.pause_circle_outline, badge: heldBillsCount > 0 ? '$heldBillsCount' : null),
      _DrawerEntry(5, '📜 Sales History', Icons.history),
      _DrawerEntry(6, '📊 Reports & Stats', Icons.insights),
      _DrawerEntry(7, '💰 Day End & Expenses', Icons.wb_twilight),
      _DrawerEntry(8, '🔧 Repairs', Icons.build),
      _DrawerEntry(9, '🔄 Returns', Icons.assignment_return),
      _DrawerEntry(10, '🏷️ Barcodes', Icons.qr_code_2),
      _DrawerEntry(11, '⚙️ Settings', Icons.settings),
    ];

    return Drawer(
      backgroundColor: AppTheme.cyberBgSecondary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.point_of_sale, color: AppTheme.neonCyan, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline ? AppTheme.greenSuccess : AppTheme.redDanger,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline ? 'Online Sync' : 'Offline Mode',
                                  style: const TextStyle(color: AppTheme.slateText, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.cardBorder, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: drawerItems.map((item) {
                  final isSelected = selectedIndex == item.index;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.neonCyan.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.neonCyan.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(item.icon, color: isSelected ? AppTheme.neonCyan : AppTheme.slateText, size: 20),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected ? AppTheme.neonCyan : AppTheme.lightText,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      trailing: item.badge != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.orangeWarning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.badge!,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        navigateTo(item.index);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppTheme.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'MY POS • v1.0.0',
                style: TextStyle(color: AppTheme.dimText.withOpacity(0.7), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRail(BuildContext context, String storeName, bool isOnline, int heldBillsCount) {
    return NavigationRail(
      backgroundColor: AppTheme.cyberBgSecondary,
      selectedIndex: selectedIndex,
      onDestinationSelected: (idx) => navigateTo(idx),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.neonCyan.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.point_of_sale, color: AppTheme.neonCyan, size: 24),
        ),
      ),
      destinations: [
        const NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('POS')),
        const NavigationRailDestination(icon: Icon(Icons.inventory_2), label: Text('Products')),
        const NavigationRailDestination(icon: Icon(Icons.category), label: Text('Categories')),
        const NavigationRailDestination(icon: Icon(Icons.people), label: Text('Customers')),
        NavigationRailDestination(
          icon: Badge(
            isLabelVisible: heldBillsCount > 0,
            label: Text('$heldBillsCount'),
            child: const Icon(Icons.pause_circle_outline),
          ),
          label: const Text('Held Bills'),
        ),
        const NavigationRailDestination(icon: Icon(Icons.history), label: Text('History')),
        const NavigationRailDestination(icon: Icon(Icons.insights), label: Text('Reports')),
        const NavigationRailDestination(icon: Icon(Icons.wb_twilight), label: Text('Day End')),
        const NavigationRailDestination(icon: Icon(Icons.build), label: Text('Repairs')),
        const NavigationRailDestination(icon: Icon(Icons.assignment_return), label: Text('Returns')),
        const NavigationRailDestination(icon: Icon(Icons.qr_code_2), label: Text('Barcodes')),
        const NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
      ],
    );
  }
}

class _DrawerEntry {
  final int index;
  final String title;
  final IconData icon;
  final String? badge;

  _DrawerEntry(this.index, this.title, this.icon, {this.badge});
}

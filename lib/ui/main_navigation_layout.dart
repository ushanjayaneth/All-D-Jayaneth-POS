import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<int> _navHistory = [0];
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _keyboardFocusNode = FocusNode();

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
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void navigateTo(int index) {
    if (selectedIndex != index) {
      setState(() {
        _navHistory.add(index);
        selectedIndex = index;
      });
    }
  }

  void handleBack() {
    if (_navHistory.length > 1) {
      setState(() {
        _navHistory.removeLast();
        selectedIndex = _navHistory.last;
      });
    }
  }

  void openDrawer() {
    if (MediaQuery.of(context).size.width <= 900) {
      _showNavigationBottomSheet(context);
    } else {
      scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final pos = Provider.of<PosProvider>(context);
    final settings = Provider.of<SettingsProvider>(context).settings;
    final sync = Provider.of<SyncProvider>(context);

    return PopScope(
      canPop: _navHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBack();
      },
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.f1) {
              navigateTo(0);
            } else if (event.logicalKey == LogicalKeyboardKey.f2) {
              navigateTo(1);
            } else if (event.logicalKey == LogicalKeyboardKey.f3) {
              navigateTo(2);
            } else if (event.logicalKey == LogicalKeyboardKey.f4) {
              navigateTo(3);
            } else if (event.logicalKey == LogicalKeyboardKey.f5) {
              navigateTo(4);
            } else if (event.logicalKey == LogicalKeyboardKey.f6) {
              navigateTo(5);
            } else if (event.logicalKey == LogicalKeyboardKey.f7) {
              navigateTo(6);
            } else if (event.logicalKey == LogicalKeyboardKey.f8) {
              navigateTo(7);
            } else if (event.logicalKey == LogicalKeyboardKey.f9) {
              navigateTo(11);
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              } else if (_navHistory.length > 1) {
                handleBack();
              }
            }
          }
        },
        child: Scaffold(
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
        ),
      ),
    );
  }

  void _showNavigationBottomSheet(BuildContext context) {
    final pos = Provider.of<PosProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cyberBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.dimText.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cyberBgTertiary,
                        border: Border.all(color: AppTheme.neonCyan, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront, color: AppTheme.neonCyan, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.storeName.isNotEmpty ? settings.storeName : 'Jayaneth Demo',
                            style: const TextStyle(
                              color: AppTheme.lightText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Main Navigation Menu',
                            style: TextStyle(
                              color: AppTheme.slateText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Navigation Cards List
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildMenuCard(
                        ctx,
                        emoji: '📦',
                        title: 'Products',
                        subtitle: 'Manage stock, prices & barcodes',
                        index: 1,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '🏷️',
                        title: 'Categories',
                        subtitle: 'Manage product categories',
                        index: 2,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '👥',
                        title: 'Customers & Dues',
                        subtitle: 'Manage credit & loan customers',
                        index: 3,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '⏸',
                        title: 'Held Bills',
                        subtitle: 'View & resume parked bills',
                        badge: pos.heldBills.isNotEmpty ? '${pos.heldBills.length}' : null,
                        index: 4,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '📜',
                        title: 'Sales History',
                        subtitle: 'View past sales & receipts',
                        index: 5,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '📊',
                        title: 'Reports',
                        subtitle: 'View sales & daily reports',
                        index: 6,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '⚙️',
                        title: 'Settings',
                        subtitle: 'Printer & system settings',
                        index: 11,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '💰',
                        title: 'Day End & Expenses',
                        subtitle: 'Daily cash balance & expense log',
                        index: 7,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '🔧',
                        title: 'Repairs',
                        subtitle: 'Device repair tracking & tickets',
                        index: 8,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '🔄',
                        title: 'Returns',
                        subtitle: 'Customer returns & refunds',
                        index: 9,
                      ),
                      _buildMenuCard(
                        ctx,
                        emoji: '🏷️',
                        title: 'Barcodes',
                        subtitle: 'Print & scan barcodes',
                        index: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext sheetContext, {
    required String emoji,
    required String title,
    required String subtitle,
    required int index,
    String? badge,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.neonCyan.withOpacity(0.08) : AppTheme.cyberBgTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.neonCyan.withOpacity(0.5) : AppTheme.cardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(sheetContext);
            navigateTo(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.lightText,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.orangeWarning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.slateText,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.neonCyan, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String storeName, bool isOnline, int heldBillsCount) {
    final drawerItems = [
      _DrawerEntry(0, '🏪 POS (Sales)', Icons.point_of_sale),
      _DrawerEntry(1, '📦 Products', Icons.inventory_2),
      _DrawerEntry(2, '🏷️ Categories', Icons.category),
      _DrawerEntry(3, '👥 Customers & Dues', Icons.people),
      _DrawerEntry(4, '⏸ Held Bills', Icons.pause_circle_outline, badge: heldBillsCount > 0 ? '$heldBillsCount' : null),
      _DrawerEntry(5, '📜 Sales History', Icons.history),
      _DrawerEntry(6, '📊 Reports', Icons.insights),
      _DrawerEntry(7, '💰 Day End', Icons.wb_twilight),
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
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cyberBgTertiary,
                      border: Border.all(color: AppTheme.neonCyan, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront, color: AppTheme.neonCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName.isNotEmpty ? storeName : 'Jayaneth Demo',
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
                              isOnline ? 'Online' : 'Offline',
                              style: const TextStyle(color: AppTheme.slateText, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                'Jayaneth Demo • v1.0.0',
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

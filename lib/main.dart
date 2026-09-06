import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/db_init.dart';
import 'theme/app_theme.dart';
import 'providers/pos_provider.dart';
import 'providers/product_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/repairs_provider.dart';
import 'providers/sync_provider.dart';
import 'ui/main_navigation_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop FFI database initialization (Windows, macOS, Linux)
  // Cleanly handled via conditional imports so Web doesn't load dart:ffi
  initializeDatabasePlatform();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()..loadCustomers()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()..loadReports()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => RepairsProvider()..loadAll()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: const PosApp(),
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: settingsProv.settings.storeName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProv.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavigationLayout(),
    );
  }
}

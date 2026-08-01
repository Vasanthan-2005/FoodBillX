import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'dashboard/home_dashboard_screen.dart';
import 'billing/billing_screen.dart';
import 'customers/customer_management_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'expenses/expense_tracker_screen.dart';
import 'menu/menu_management_screen.dart';
import 'reports/orders_screen.dart';
import 'settings/settings_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  void _onSelectTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      HomeDashboardScreen(
        key: const PageStorageKey('HomeDashboardScreen'),
        onNavigateToTab: _onSelectTab,
        onOpenSettings: _openSettings,
      ),
      BillingScreen(
        key: const PageStorageKey('BillingScreen'),
        onOpenSettings: _openSettings,
      ),
      DashboardScreen(
        key: const PageStorageKey('DashboardScreen'),
        onGoToBilling: () => _onSelectTab(1),
        onOpenSettings: _openSettings,
      ),
      MenuManagementScreen(
        key: const PageStorageKey('MenuManagementScreen'),
        onOpenSettings: _openSettings,
      ),
      CustomerManagementScreen(
        key: const PageStorageKey('CustomerManagementScreen'),
        onOpenSettings: _openSettings,
      ),
      ExpenseTrackerScreen(
        key: const PageStorageKey('ExpenseTrackerScreen'),
        onOpenSettings: _openSettings,
      ),
      OrdersScreen(
        key: const PageStorageKey('OrdersScreen'),
        onOpenSettings: _openSettings,
      ),
    ];

    const navDestinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(
          Icons.point_of_sale_rounded,
          color: AppColors.primary,
        ),
        label: 'Billing',
      ),
      NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
        label: 'Insights',
      ),
      NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(
          Icons.restaurant_menu_rounded,
          color: AppColors.primary,
        ),
        label: 'Menu',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_alt_outlined),
        selectedIcon: Icon(Icons.people_alt_rounded, color: AppColors.primary),
        label: 'Loyalty',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(
          Icons.receipt_long_rounded,
          color: AppColors.primary,
        ),
        label: 'Expenses',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
        label: 'Orders',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _currentIndex == 0
          ? null
          : Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: NavigationBar(
                  height: 65,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onSelectTab,
                  indicatorColor: AppColors.primary.withAlpha(40),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: navDestinations,
                ),
              ),
            ),
    );
  }
}

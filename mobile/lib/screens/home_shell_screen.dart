import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/settings_provider.dart';
import 'billing/billing_screen.dart';
import 'customers/customer_management_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'dashboard/home_dashboard_screen.dart';
import 'expenses/expense_tracker_screen.dart';
import 'menu/menu_management_screen.dart';
import 'reports/orders_screen.dart';
import 'settings/settings_screen.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _currentIndex = 0;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(5, null);
    _pages[0] = _buildPage(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchAppData();
    });
  }

  void _prefetchAppData() {
    if (!mounted) return;
    ref.read(menuProvider.notifier).loadCategoriesAndItems();
    ref.read(customerProvider.notifier).loadCustomers();
    ref.read(dashboardProvider.notifier).refresh();
    ref.read(settingsProvider.notifier).loadSettings();
    ref.read(expenseProvider.notifier).loadAll();
    ref.read(ordersProvider.notifier).loadOrders();
  }

  void _onSelectTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() {
      _pages[index] ??= _buildPage(index);
      _currentIndex = index;
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openMenuManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuManagementScreen(onOpenSettings: _openSettings),
      ),
    );
  }

  void _openExpenseTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseTrackerScreen(onOpenSettings: _openSettings),
      ),
    );
  }

  Widget _buildPage(int index) {
    return switch (index) {
      0 => HomeDashboardScreen(
        key: const PageStorageKey('HomeDashboardScreen'),
        onNavigateToTab: _onSelectTab,
        onOpenSettings: _openSettings,
        onOpenMenu: _openMenuManagement,
        onOpenExpenses: _openExpenseTracker,
      ),
      1 => BillingScreen(
        key: const PageStorageKey('BillingScreen'),
        onOpenSettings: _openSettings,
      ),
      2 => OrdersScreen(
        key: const PageStorageKey('OrdersScreen'),
        onOpenSettings: _openSettings,
      ),
      3 => CustomerManagementScreen(
        key: const PageStorageKey('CustomerManagementScreen'),
        onOpenSettings: _openSettings,
      ),
      4 => DashboardScreen(
        key: const PageStorageKey('DashboardScreen'),
        onGoToBilling: () => _onSelectTab(1),
        onOpenSettings: _openSettings,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = List<Widget>.generate(
      _pages.length,
      (index) => _pages[index] ?? const SizedBox.shrink(),
      growable: false,
    );

    const navDestinations = [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
        label: 'Dashboard',
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
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(
          Icons.receipt_long_rounded,
          color: AppColors.primary,
        ),
        label: 'Orders',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_alt_outlined),
        selectedIcon: Icon(Icons.people_alt_rounded, color: AppColors.primary),
        label: 'Customers',
      ),
      NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
        label: 'Insights',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            height: 65,
            selectedIndex: _currentIndex,
            onDestinationSelected: _onSelectTab,
            indicatorColor: AppColors.primary.withAlpha(35),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: navDestinations,
          ),
        ),
      ),
    );
  }
}

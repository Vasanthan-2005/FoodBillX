import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/realtime_sync_service.dart';
import '../core/constants/app_colors.dart';
import '../core/services/background_sync_service.dart';
import '../core/services/sync_manager.dart';
import '../core/widgets/onboarding_dialog.dart';
import 'billing/billing_screen.dart';
import 'customers/customer_management_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'dashboard/home_dashboard_screen.dart';
import 'expenses/expense_tracker_screen.dart';
import 'menu/menu_management_screen.dart';
import 'reports/orders_screen.dart';
import 'settings/settings_screen.dart';

import '../providers/dashboard_provider.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  late int _currentIndex;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = List<Widget?>.filled(5, null);
    _pages[_currentIndex] = _buildPage(_currentIndex);

    // Initialize and keep the realtime sync service alive for the app session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeSyncProvider); // Ensures socket + polling starts
      OnboardingDialog.showIfNeeded(context);
      // Quietly evaluate if daily 8 PM sync is due and run in background
      BackgroundSyncService.checkAndRunForegroundEveningSync(ref.read(syncManagerProvider));
    });
  }

  void _onSelectTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() {
      _pages[index] = _buildPage(index);
      _currentIndex = index;
    });

    if (index == 3 || index == 4) {
      ref.read(dashboardProvider.notifier).refresh();
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openPreviousOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdersScreen(onOpenSettings: _openSettings),
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
      0 => BillingScreen(
        key: const PageStorageKey('BillingScreen'),
        onOpenSettings: _openSettings,
      ),
      1 => MenuManagementScreen(
        key: const PageStorageKey('MenuManagementScreen'),
        onOpenSettings: _openSettings,
      ),
      2 => CustomerManagementScreen(
        key: const PageStorageKey('CustomerManagementScreen'),
        onOpenSettings: _openSettings,
      ),
      3 => DashboardScreen(
        key: const PageStorageKey('ReportsScreen'),
        onGoToBilling: () => _onSelectTab(0),
        onOpenSettings: _openSettings,
      ),
      4 => HomeDashboardScreen(
        key: const PageStorageKey('HomeDashboardScreen'),
        onNavigateToTab: _onSelectTab,
        onOpenSettings: _openSettings,
        onOpenOrders: _openPreviousOrders,
        onOpenExpenses: _openExpenseTracker,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _pages[_currentIndex] ??= _buildPage(_currentIndex);

    final screens = List<Widget>.generate(
      _pages.length,
      (index) => _pages[index] ?? const SizedBox.shrink(),
      growable: false,
    );

    const navDestinations = [
      NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(
          Icons.point_of_sale_rounded,
          color: AppColors.primary,
        ),
        label: 'Billing',
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
        selectedIcon: Icon(
          Icons.people_alt_rounded,
          color: AppColors.primary,
        ),
        label: 'Customers',
      ),
      NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(
          Icons.bar_chart_rounded,
          color: AppColors.primary,
        ),
        label: 'Reports',
      ),
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
        label: 'Dashboard',
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
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

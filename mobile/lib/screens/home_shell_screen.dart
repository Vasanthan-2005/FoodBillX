import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/realtime_sync_service.dart';
import '../core/constants/app_colors.dart';
import '../core/services/background_sync_service.dart';
import '../core/services/onboarding_service.dart';
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
import '../providers/sync_provider.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> with WidgetsBindingObserver {
  late int _currentIndex;
  late final List<Widget?> _pages;
  bool _isTourActive = false;
  int _tourStepIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pages = List<Widget?>.filled(5, null);
    _pages[_currentIndex] = _buildPage(_currentIndex);

    // Initialize and keep services alive; push pending data in background if online
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(realtimeSyncProvider); // Ensures socket + polling starts
      ref.read(syncProvider.notifier).autoSyncIfOnline();
      final isFirst = await OnboardingService.isFirstLaunch();
      if (isFirst && mounted) {
        _startGuidedTour();
      }
    });
  }

  void _startGuidedTour() {
    if (!mounted || guidedTourSteps.isEmpty) return;
    _goToTourStep(0);
  }

  void _goToTourStep(int stepIndex) {
    final safeIdx = stepIndex.clamp(0, guidedTourSteps.length - 1);
    final step = guidedTourSteps[safeIdx];
    final targetTab = step.tabIndex.clamp(0, _pages.length - 1);
    setState(() {
      _isTourActive = true;
      _tourStepIndex = safeIdx;
      _pages[targetTab] ??= _buildPage(targetTab);
      _currentIndex = targetTab;
    });
    if (targetTab == 3 || targetTab == 4) {
      ref.read(dashboardProvider.notifier).refresh();
    }
  }

  Future<void> _finishGuidedTour() async {
    await OnboardingService.markOnboardingComplete();
    if (!mounted) return;
    setState(() {
      _isTourActive = false;
      _tourStepIndex = 0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BackgroundSyncService.checkAndRunForegroundEveningSync(ref.read(syncManagerProvider));
      ref.read(syncProvider.notifier).autoSyncIfOnline();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

  void _openExpenseTracker({bool openAdd = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseTrackerScreen(
          onOpenSettings: _openSettings,
          openAddOnLoad: openAdd,
        ),
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
      3 => HomeDashboardScreen(
        key: const PageStorageKey('HomeDashboardScreen'),
        onNavigateToTab: _onSelectTab,
        onOpenSettings: _openSettings,
        onOpenOrders: _openPreviousOrders,
        onOpenExpenses: () => _openExpenseTracker(openAdd: true),
        reportsTabIndex: 4,
      ),
      4 => DashboardScreen(
        key: const PageStorageKey('ReportsScreen'),
        onGoToBilling: () => _onSelectTab(0),
        onOpenSettings: _openSettings,
        onOpenOrders: _openPreviousOrders,
        onOpenExpenses: () => _openExpenseTracker(openAdd: true),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(onboardingTourTriggerProvider, (prev, next) {
      if (next != prev && next > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startGuidedTour();
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    _pages[_currentIndex] ??= _buildPage(_currentIndex);

    final screens = List<Widget>.generate(
      _pages.length,
      (index) => _pages[index] ?? const SizedBox.shrink(),
      growable: false,
    );

    final OnboardingStep? activeTourStep =
        (_isTourActive && _tourStepIndex < guidedTourSteps.length)
            ? guidedTourSteps[_tourStepIndex]
            : null;

    final Widget baseContent = IndexedStack(index: _currentIndex, children: screens);
    final Widget visibleWorkspace = activeTourStep == null
        ? baseContent
        : switch (activeTourStep.targetSpace) {
            TourTargetSpace.expenses =>
              ExpenseTrackerScreen(onOpenSettings: _openSettings),
            TourTargetSpace.orders => OrdersScreen(onOpenSettings: _openSettings),
            TourTargetSpace.settings => const SettingsScreen(),
            _ => baseContent,
          };

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
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(
          Icons.bar_chart_rounded,
          color: AppColors.primary,
        ),
        label: 'Reports',
      ),
    ];

    final theme = Theme.of(context);
    final isAmoled = theme.scaffoldBackgroundColor == AppColors.amoledBackground;

    return PopScope(
      canPop: !_isTourActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isTourActive) {
          if (_tourStepIndex > 0) {
            _goToTourStep(_tourStepIndex - 1);
          } else {
            _finishGuidedTour();
          }
        }
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: _isTourActive ? 195 : 0),
            child: AbsorbPointer(
              absorbing: _isTourActive,
              child: visibleWorkspace,
            ),
          ),
          if (activeTourStep != null) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(0),
                        Colors.black.withAlpha(110),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: GuidedTourOverlayCard(
                step: activeTourStep,
                stepIndex: _tourStepIndex,
                totalSteps: guidedTourSteps.length,
                onBack: _tourStepIndex > 0
                    ? () => _goToTourStep(_tourStepIndex - 1)
                    : null,
                onNext: () {
                  if (_tourStepIndex < guidedTourSteps.length - 1) {
                    _goToTourStep(_tourStepIndex + 1);
                  } else {
                    _finishGuidedTour();
                  }
                },
                onSkip: _finishGuidedTour,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isAmoled ? AppColors.amoledBackground : theme.colorScheme.surface,
          border: isAmoled
              ? const Border(top: BorderSide(color: AppColors.amoledBorder, width: 1))
              : null,
          boxShadow: isAmoled
              ? null
              : [
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
            backgroundColor: isAmoled ? AppColors.amoledBackground : null,
            selectedIndex: _currentIndex,
            onDestinationSelected: _isTourActive ? null : _onSelectTab,
            indicatorColor: theme.colorScheme.primary.withAlpha(35),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: navDestinations,
          ),
        ),
      ),
    ),
    );
  }
}

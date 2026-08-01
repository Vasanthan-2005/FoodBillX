import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/metric_card_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenExpenses;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onOpenSettings,
    required this.onOpenMenu,
    required this.onOpenExpenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardProvider);
    final settings = ref.watch(settingsProvider).settings;
    final customerState = ref.watch(customerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.now());

    final customerCount = customerState.customers.length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  settings?.businessName ?? 'HMB Bills',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded),
            tooltip: 'Menu Management',
            onPressed: onOpenMenu,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Expense Tracker',
            onPressed: onOpenExpenses,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refresh();
          await ref.read(customerProvider.notifier).loadCustomers();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Text(
                'Today\'s Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // 4 Compact Dashboard Summary Cards in a 2x2 Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  MetricCardWidget(
                    title: 'Orders Today',
                    value: metrics.todayOrderCount.toString(),
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    subtitle: 'Sales completed',
                  ),
                  MetricCardWidget(
                    title: 'Revenue Today',
                    value: CurrencyFormatter.format(metrics.todayRevenue),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.secondary,
                    subtitle: 'Gross sales',
                  ),
                  MetricCardWidget(
                    title: 'Profit Today',
                    value: CurrencyFormatter.format(metrics.netProfitToday),
                    icon: Icons.trending_up_rounded,
                    color: Colors.blue,
                    subtitle: 'Net earnings',
                  ),
                  MetricCardWidget(
                    title: 'Active Customers',
                    value: customerCount > 0 ? customerCount.toString() : '0',
                    icon: Icons.people_outline_rounded,
                    color: Colors.purple,
                    subtitle: 'Registered guests',
                  ),
                ],
              ).animate().fade(duration: 400.ms),

              const SizedBox(height: 20),

              // Quick Action Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickActionChip(
                      context: context,
                      label: 'New Bill',
                      icon: Icons.add_shopping_cart_rounded,
                      color: AppColors.primary,
                      onTap: () => onNavigateToTab(1), // Billing
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Manage Menu',
                      icon: Icons.restaurant_menu_rounded,
                      color: Colors.amber.shade800,
                      onTap: onOpenMenu,
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Expenses',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.red.shade600,
                      onTap: onOpenExpenses,
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      context: context,
                      label: 'Analytics',
                      icon: Icons.analytics_rounded,
                      color: Colors.purple,
                      onTap: () => onNavigateToTab(4), // Insights
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Weekly Revenue Trend Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Sales Trend',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => onNavigateToTab(4), // Insights
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('Full Report'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '7-Day Revenue',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(metrics.weekRevenue),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${metrics.weekOrderCount} orders',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (metrics.isLoading)
                        const SkeletonLoader(height: 100, width: double.infinity)
                      else
                        _buildSimpleBarChart(metrics.recentDailyRevenue, isDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Top Selling Items Section
              Text(
                'Top Dishes Today',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              if (metrics.isLoading)
                const Column(
                  children: [
                    SkeletonLoader(height: 50, width: double.infinity),
                    SizedBox(height: 8),
                    SkeletonLoader(height: 50, width: double.infinity),
                  ],
                )
              else if (metrics.topSellingItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No dishes billed today yet.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: metrics.topSellingItems.map((item) {
                    final name = item['name'] ?? 'Item';
                    final qty = item['quantity'] ?? 0;
                    final total = (item['total'] as num?)?.toDouble() ?? 0.0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(25),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('$qty units sold'),
                        trailing: Text(
                          CurrencyFormatter.format(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 13,
        ),
      ),
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(60)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildSimpleBarChart(List<double> data, bool isDark) {
    final maxVal = data.fold<double>(1.0, (m, e) => e > m ? e : m);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final val = data[index];
          final heightPct = (val / maxVal).clamp(0.08, 1.0);
          final dayLabel = index < days.length ? days[index] : '';

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: 70 * heightPct,
                decoration: BoxDecoration(
                  color: val > 0
                      ? AppColors.primary
                      : (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

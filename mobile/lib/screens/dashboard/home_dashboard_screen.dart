import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/metric_card_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../api/api_client.dart';
import '../../providers/settings_provider.dart';

final homeSummaryMetricsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final apiClient = ref.watch(apiClientProvider);
      try {
        final response = await apiClient.dio.get('/reports/dashboard');
        return response.data['data']['summary'] ?? {};
      } catch (e) {
        // Return empty fallback structure when server is offline or fails
        return {
          'todayRevenue': 0.0,
          'todayOrderCount': 0,
          'netProfitToday': 0.0,
          'monthRevenue': 0.0,
          'todayExpense': 0.0,
          'topSellingItems': [],
        };
      }
    });

class HomeDashboardScreen extends ConsumerWidget {
  final Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenSettings;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(homeSummaryMetricsProvider);
    final settings = ref.watch(settingsProvider).settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings?.businessName ?? 'FoodBillX POS',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(100)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppColors.secondary, size: 8),
                SizedBox(width: 6),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => ref.invalidate(homeSummaryMetricsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(homeSummaryMetricsProvider),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Quick Billing Banner
              InkWell(
                onTap: () => onNavigateToTab(1), // Billing Tab
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(90),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OPEN POS BILLING',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quick checkout & printable invoices',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 350.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              // Business Performance Overview Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Overview",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateToTab(2), // Insights
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Full Insights'),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Metric Cards Grid
              metricsAsync.when(
                loading: () => const Row(
                  children: [
                    Expanded(child: MetricCardSkeleton()),
                    SizedBox(width: 12),
                    Expanded(child: MetricCardSkeleton()),
                  ],
                ),
                error: (err, stack) => _buildMetricsGrid(
                  todayRevenue: 0.0,
                  todayOrders: 0,
                  netProfit: 0.0,
                  expenses: 0.0,
                  topItem: 'None',
                  onTapInsights: () => onNavigateToTab(2),
                ),
                data: (summary) {
                  final double todayRevenue =
                      (summary['todayRevenue'] as num?)?.toDouble() ?? 0.0;
                  final int todayOrderCount = summary['todayOrderCount'] ?? 0;
                  final double netProfitToday =
                      (summary['netProfitToday'] as num?)?.toDouble() ?? 0.0;
                  final double todayExpense =
                      (summary['todayExpense'] as num?)?.toDouble() ?? 0.0;
                  final List topItems = summary['topSellingItems'] ?? [];
                  final String topItemName = topItems.isNotEmpty
                      ? (topItems.first['_id'] ?? 'Dish')
                      : 'None';

                  return _buildMetricsGrid(
                    todayRevenue: todayRevenue,
                    todayOrders: todayOrderCount,
                    netProfit: netProfitToday,
                    expenses: todayExpense,
                    topItem: topItemName,
                    onTapInsights: () => onNavigateToTab(2),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Quick Module Navigation Section
              Text(
                "POS Modules & Management",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildModuleCard(
                    context,
                    title: 'Billing',
                    subtitle: 'Create POS Bills',
                    emoji: '🧾',
                    color: AppColors.primary,
                    onTap: () => onNavigateToTab(1),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Insights',
                    subtitle: 'Sales & Analytics',
                    emoji: '📊',
                    color: Colors.purple,
                    onTap: () => onNavigateToTab(2),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Menu',
                    subtitle: 'Manage Food Items',
                    emoji: '🍽',
                    color: AppColors.secondary,
                    onTap: () => onNavigateToTab(3),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Loyalty',
                    subtitle: 'Customers & Points',
                    emoji: '👥',
                    color: Colors.blue,
                    onTap: () => onNavigateToTab(4),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Expenses',
                    subtitle: 'Track Costs',
                    emoji: '💸',
                    color: Colors.red,
                    onTap: () => onNavigateToTab(5),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Orders',
                    subtitle: 'Order History',
                    emoji: '📜',
                    color: Colors.amber.shade800,
                    onTap: () => onNavigateToTab(6),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Settings',
                    subtitle: 'Store & PIN Setup',
                    emoji: '⚙',
                    color: Colors.blueGrey,
                    onTap: () => onNavigateToTab(7),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid({
    required double todayRevenue,
    required int todayOrders,
    required double netProfit,
    required double expenses,
    required String topItem,
    required VoidCallback onTapInsights,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCardWidget(
                title: "Today's Revenue",
                value: CurrencyFormatter.format(todayRevenue),
                icon: Icons.payments_rounded,
                color: AppColors.secondary,
                subtitle: "Sales",
                onTap: onTapInsights,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCardWidget(
                title: "Today's Orders",
                value: '$todayOrders',
                icon: Icons.receipt_long_rounded,
                color: AppColors.primary,
                subtitle: "Orders",
                onTap: onTapInsights,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCardWidget(
                title: "Net Profit",
                value: CurrencyFormatter.format(netProfit),
                icon: Icons.trending_up_rounded,
                color: netProfit >= 0 ? AppColors.secondary : Colors.red,
                subtitle: netProfit >= 0 ? "+Profit" : "Loss",
                onTap: onTapInsights,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCardWidget(
                title: "Top Seller",
                value: topItem,
                icon: Icons.star_rounded,
                color: Colors.amber.shade700,
                subtitle: "Popular",
                onTap: onTapInsights,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withAlpha(50)),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

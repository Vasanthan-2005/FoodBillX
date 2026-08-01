import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/orders_provider.dart';
import '../../local_db/schemas/order_schema.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const OrdersScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPaymentFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History & Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(ordersProvider.notifier).loadOrders(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Payment Filter Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by Order ID or customer...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Payment Filter Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['ALL', 'CASH', 'UPI', 'CARD'].map((method) {
                final isSelected = _selectedPaymentFilter == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedPaymentFilter = method),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ordersState.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (ctx, idx) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: MetricCardSkeleton(),
                    ),
                  )
                : ordersState.errorMessage != null
                ? ErrorStateWidget(
                    title: 'Unable to load orders',
                    message: ordersState.errorMessage!,
                    onRetry: () =>
                        ref.read(ordersProvider.notifier).loadOrders(),
                  )
                : _buildOrdersList(ordersState.orders, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderSchema> orders, bool isDark) {
    final filtered = orders.where((order) {
      final orderNum = order.orderNumber.toLowerCase();
      final customer = order.customerName.toLowerCase();
      final payment = order.paymentMethod.toUpperCase();

      final matchesQuery =
          orderNum.contains(_searchQuery) || customer.contains(_searchQuery);
      final matchesPayment =
          _selectedPaymentFilter == 'ALL' || payment == _selectedPaymentFilter;

      return matchesQuery && matchesPayment;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        iconEmoji: '🧾',
        title: 'No orders yet',
        description: _searchQuery.isNotEmpty
            ? 'No orders match "$_searchQuery".'
            : 'Start processing transactions on the Billing screen to see order history.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (ctx, index) {
        final order = filtered[index];
        final orderNum = order.orderNumber;
        final customerName = order.customerName;
        final grandTotal = order.grandTotal;
        final paymentMethod = order.paymentMethod.toUpperCase();
        final items = order.items;
        final dateStr = order.createdAt;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderNum,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.secondary.withAlpha(80),
                        ),
                      ),
                      child: Text(
                        paymentMethod,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Customer: $customerName  •  ${dateStr.day}/${dateStr.month}/${dateStr.year} ${dateStr.hour.toString().padLeft(2, '0')}:${dateStr.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const Divider(height: 16),
                Text(
                  '${items.length} items: ${items.map((i) => '${i.name} (${i.quantity}x)').join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.format(grandTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 25).ms);
      },
    );
  }
}

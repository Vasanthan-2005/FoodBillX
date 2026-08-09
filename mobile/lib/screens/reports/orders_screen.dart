import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/pdf_invoice_helper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/settings_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const OrdersScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );

    if (picked != null) {
      ref.read(ordersProvider.notifier).loadOrders(
            dateFilter: OrderDateFilter.custom,
            customRange: DateTimeRange(
              start: DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
              end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Pick Custom Date Range',
            onPressed: _pickCustomDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(ordersProvider.notifier).loadOrders(forceSpinner: true),
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
          // Date Filter Quick Chips (Today, Yesterday, This Week, This Month, Custom Date Range)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                _buildFilterChip('Today', OrderDateFilter.today, ordersState.dateFilter),
                _buildFilterChip('Yesterday', OrderDateFilter.yesterday, ordersState.dateFilter),
                _buildFilterChip('This Week', OrderDateFilter.thisWeek, ordersState.dateFilter),
                _buildFilterChip('This Month', OrderDateFilter.thisMonth, ordersState.dateFilter),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: Text(
                      ordersState.dateFilter == OrderDateFilter.custom && ordersState.customDateRange != null
                          ? '${DateFormat('d MMM').format(ordersState.customDateRange!.start)} - ${DateFormat('d MMM').format(ordersState.customDateRange!.end)}'
                          : 'Custom Range',
                    ),
                    backgroundColor: ordersState.dateFilter == OrderDateFilter.custom
                        ? AppColors.primary
                        : null,
                    labelStyle: TextStyle(
                      color: ordersState.dateFilter == OrderDateFilter.custom ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: _pickCustomDateRange,
                  ),
                ),
              ],
            ),
          ),

          // Search & Payment Filter Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search bill # or customer name...',
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
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['ALL', 'CASH', 'UPI', 'CARD'].map((method) {
                final isSelected = ordersState.selectedPaymentFilter == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      ref.read(ordersProvider.notifier).loadOrders(paymentFilter: method);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

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
                        title: 'Unable to load previous orders',
                        message: ordersState.errorMessage!,
                        onRetry: () => ref.read(ordersProvider.notifier).loadOrders(),
                      )
                    : _buildOrdersList(ordersState, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, OrderDateFilter filter, OrderDateFilter currentFilter) {
    final isSelected = currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) {
          ref.read(ordersProvider.notifier).loadOrders(dateFilter: filter);
        },
      ),
    );
  }

  Widget _buildOrdersList(OrdersState ordersState, bool isDark) {
    final orders = ordersState.orders;
    final filtered = orders.where((order) {
      final orderNum = order.orderNumber.toLowerCase();
      final customer = order.customerName.toLowerCase();
      return orderNum.contains(_searchQuery) || customer.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        iconEmoji: '🧾',
        title: 'No previous orders found',
        description: _searchQuery.isNotEmpty
            ? 'No orders match "$_searchQuery".'
            : 'No orders created for the selected date range.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(forceSpinner: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: filtered.length,
        itemBuilder: (ctx, index) {
          final order = filtered[index];
          final dateStr = order.createdAt;
          final isRefunded = order.orderStatus == 'refunded';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isRefunded ? Colors.red.withAlpha(30) : AppColors.secondary.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isRefunded ? 'REFUNDED' : 'COMPLETED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isRefunded ? Colors.red : AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.paymentMethod.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customer: ${order.customerName}  •  ${DateFormat('d MMM yyyy, h:mm a').format(dateStr)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const Divider(height: 16),
                  Text(
                    '${order.items.length} items: ${order.items.map((i) => '${i.name} (${i.quantity}x)').join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(order.grandTotal),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          decoration: isRefunded ? TextDecoration.lineThrough : null,
                          color: isRefunded ? Colors.grey : AppColors.primary,
                        ),
                      ),
                      Row(
                        children: [
                          if (!isRefunded)
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Refund Order?'),
                                    content: Text('Are you sure you want to refund order #${order.orderNumber}? This will deduct from total revenue and profit.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Refund'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final success = await ref.read(ordersProvider.notifier).refundOrder(order.id);
                                  if (mounted && success) {
                                    SnackbarUtils.showSuccess(context, 'Order #${order.orderNumber} refunded.');
                                  }
                                }
                              },
                              icon: const Icon(Icons.undo_rounded, size: 16, color: Colors.red),
                              label: const Text('Refund', style: TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _showOrderBillDialog(context, order),
                            icon: const Icon(Icons.receipt_long_rounded, size: 16),
                            label: const Text('View Bill', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 20).ms);
        },
      ),
    );
  }

  void _showOrderBillDialog(BuildContext context, OrderModel order) {
    final settings = ref.read(settingsProvider).settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withAlpha(60)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 36),
                        const SizedBox(height: 6),
                        Text(
                          settings?.businessName ?? 'HMB Bills',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        if ((settings?.address ?? '').isNotEmpty)
                          Text(
                            settings!.address,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        if ((settings?.phone ?? '').isNotEmpty)
                          Text(
                            'Ph: ${settings!.phone}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bill Meta Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            DateFormat('d MMM yyyy, h:mm a').format(order.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.paymentMethod.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Customer Details Card
                  if (order.customerName.isNotEmpty && order.customerName != 'Walk-in Customer') ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer: ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          if (order.customerPhone.isNotEmpty)
                            Text('Phone: ${order.customerPhone}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Itemized Receipt Table
                  const Text('Items Billed:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} x${item.quantity}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 20),

                  // Financial Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text(CurrencyFormatter.format(order.subtotal)),
                    ],
                  ),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text('- ${CurrencyFormatter.format(order.discountAmount)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  if (order.gstAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GST Tax:'),
                        Text(CurrencyFormatter.format(order.gstAmount)),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyFormatter.format(order.grandTotal),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () async {
                try {
                  final file = await PdfInvoiceHelper.generateInvoicePdf(
                    businessName: settings?.businessName ?? 'HMB Bills',
                    businessPhone: settings?.phone ?? '',
                    businessAddress: settings?.address ?? '',
                    gstin: settings?.gstin ?? '',
                    invoicePrefix: settings?.invoicePrefix ?? 'INV-',
                    orderNumber: order.orderNumber,
                    orderDate: order.createdAt,
                    customerName: order.customerName,
                    customerPhone: order.customerPhone,
                    loyaltyCardNumber: order.loyaltyCardNumber,
                    visitCount: order.visitCount,
                    rewardStatus: order.rewardStatus,
                    items: order.items.map((i) => {
                          'name': i.name,
                          'price': i.price,
                          'quantity': i.quantity,
                          'subtotal': i.subtotal,
                        }).toList(),
                    subtotal: order.subtotal,
                    discount: order.discountAmount,
                    gstAmount: order.gstAmount,
                    serviceChargeAmount: order.serviceChargeAmount,
                    grandTotal: order.grandTotal,
                    paymentMethod: order.paymentMethod,
                  );
                  await PdfInvoiceHelper.shareInvoiceViaWhatsApp(file, order.customerPhone, order.orderNumber);
                } catch (_) {
                  if (ctx.mounted) {
                    SnackbarUtils.showError(ctx, 'Failed to share PDF bill');
                  }
                }
              },
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
              label: const Text('Share PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

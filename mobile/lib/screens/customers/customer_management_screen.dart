import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';

class CustomerManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const CustomerManagementScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState
    extends ConsumerState<CustomerManagementScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = val.trim().toLowerCase());
      }
    });
  }

  void _showCustomerFormDialog([CustomerModel? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final cardController = TextEditingController(text: existing?.loyaltyCardNumber ?? '');

    final isEdit = existing != null;
    final String? customerId = existing?.id;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Customer' : 'Add New Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardController,
                decoration: const InputDecoration(
                  labelText: 'Loyalty Card Number (Optional)',
                  hintText: 'Auto-generated if left blank',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final card = cardController.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                SnackbarUtils.showError(ctx, 'Name and phone are required');
                return;
              }

              final customers = ref.read(customerProvider).customers;
              if (!isEdit && customers.any((c) => c.phone.trim() == phone)) {
                SnackbarUtils.showError(ctx, 'Customer already exists with this mobile number.');
                return;
              }

              final notifier = ref.read(customerProvider.notifier);
              final data = {
                'name': name,
                'phone': phone,
                if (card.isNotEmpty) 'loyaltyCardNumber': card,
              };

              bool ok;
              if (isEdit && customerId != null) {
                ok = await notifier.updateCustomer(customerId, data);
              } else {
                ok = await notifier.createCustomer(data);
              }

              if (ctx.mounted) {
                if (ok) {
                  Navigator.pop(ctx);
                  SnackbarUtils.showSuccess(
                    ctx,
                    isEdit
                        ? '$name updated successfully'
                        : '$name added to loyalty directory',
                  );
                } else {
                  SnackbarUtils.showError(
                    ctx,
                    ref.read(customerProvider).errorMessage ??
                        'Customer already exists with this mobile number.',
                  );
                }
              }
            },
            child: Text(isEdit ? 'Save Changes' : 'Add Customer'),
          ),
        ],
      ),
    );
  }

  void _showAssignCardDialog(String? customerId, String currentCard) {
    if (customerId == null) return;
    final cardController = TextEditingController(text: currentCard);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Assign Loyalty Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: cardController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: 'e.g. HMB-102030',
            prefixIcon: Icon(Icons.credit_card_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final card = cardController.text.trim();
              if (card.isEmpty) return;
              final notifier = ref.read(customerProvider.notifier);
              Navigator.pop(ctx);
              final ok = await notifier.assignLoyaltyCard(customerId, card);
              if (mounted) {
                if (ok) {
                  SnackbarUtils.showSuccess(context, 'Card #$card assigned');
                } else {
                  SnackbarUtils.showError(
                    context,
                    ref.read(customerProvider).errorMessage ??
                        'Failed to assign card',
                  );
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCustomer(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          'Remove "$name" from the directory? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final ok = await ref.read(customerProvider.notifier).deleteCustomer(id);
      if (mounted) {
        if (ok) {
          SnackbarUtils.showSuccess(context, '$name deleted');
        } else {
          SnackbarUtils.showError(context, 'Failed to delete customer');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer & Loyalty Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(customerProvider.notifier).loadCustomers(forceSpinner: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customer_fab',
        onPressed: () => _showCustomerFormDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Customer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 6,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search customer name or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _debounceTimer?.cancel();
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: customerState.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (ctx, idx) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: MetricCardSkeleton(),
                    ),
                  )
                : (customerState.errorMessage != null &&
                        customerState.customers.isEmpty)
                ? ErrorStateWidget(
                    title: 'Unable to load customers',
                    message: customerState.errorMessage!,
                    onRetry: () =>
                        ref.read(customerProvider.notifier).loadCustomers(forceSpinner: true),
                  )
                : _buildCustomerList(customerState.customers),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(List<CustomerModel> customers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = customers.where((c) {
      final name = c.name.toLowerCase();
      final phone = c.phone.toLowerCase();
      return name.contains(_searchQuery) || phone.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        iconEmoji: '👥',
        title: 'No customers found',
        description: _searchQuery.isNotEmpty
            ? 'No customer matches "$_searchQuery".'
            : 'Tap Add Customer to register your first customer & loyalty program.',
        actionLabel: 'Add Customer',
        onActionPressed: () => _showCustomerFormDialog(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customerProvider.notifier).loadCustomers(forceSpinner: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: filtered.length,
        itemBuilder: (ctx, index) {
          final c = filtered[index];
          final String name = c.name;
          final String phone = c.phone;
          final String cardNum = c.loyaltyCardNumber;
          final double spent = c.totalSpent;
          final int visits = c.totalVisits;
          final int points = c.loyaltyPoints;
          final String customerId = c.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withAlpha(30),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') _showCustomerFormDialog(c);
                          if (val == 'card') {
                            _showAssignCardDialog(customerId, cardNum);
                          }
                          if (val == 'delete') {
                            _confirmDeleteCustomer(customerId, name);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Customer'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'card',
                            child: Row(
                              children: [
                                const Icon(Icons.credit_card_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  cardNum.isNotEmpty
                                      ? 'Change Card'
                                      : 'Assign Card',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (cardNum.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showAssignCardDialog(customerId, cardNum),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.secondary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.credit_card_rounded,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Card #$cardNum',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showAssignCardDialog(customerId, cardNum),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.credit_card_outlined,
                              size: 14,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Assign Loyalty Card',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatChip(label: 'Visits', value: '$visits'),
                      _StatChip(
                        label: 'Points',
                        value: '$points pts',
                        color: AppColors.primary,
                      ),
                      _StatChip(
                        label: 'Spent',
                        value: CurrencyFormatter.format(spent),
                        color: AppColors.secondary,
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
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

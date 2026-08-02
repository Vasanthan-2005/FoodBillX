import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/pdf_invoice_helper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/menu_provider.dart';

import '../../core/widgets/dish_image_widget.dart';
import '../../core/widgets/live_badge_widget.dart';
import '../../core/widgets/loyalty_input_field_widget.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const BillingScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  void _onSearchInputChanged(String val) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  static final Map<String, String> _emojiCache = {};

  String _getItemEmoji(String name, bool isVeg) {
    final key = '$name-$isVeg';
    if (_emojiCache.containsKey(key)) return _emojiCache[key]!;

    final lower = name.toLowerCase();
    String emoji;
    if (lower.contains('burger')) {
      emoji = '🍔';
    } else if (lower.contains('pizza')) {
      emoji = '🍕';
    } else if (lower.contains('biryani') || lower.contains('rice')) {
      emoji = '🍚';
    } else if (lower.contains('roll') || lower.contains('wrap')) {
      emoji = '🌯';
    } else if (lower.contains('fries')) {
      emoji = '🍟';
    } else if (lower.contains('drink') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('soda')) {
      emoji = '🥤';
    } else if (lower.contains('ice') ||
        lower.contains('dessert') ||
        lower.contains('cake')) {
      emoji = '🍨';
    } else if (lower.contains('chicken') || lower.contains('meat')) {
      emoji = '🍗';
    } else if (lower.contains('paneer') || isVeg) {
      emoji = '🥗';
    } else {
      emoji = '🍽';
    }

    _emojiCache[key] = emoji;
    return emoji;
  }

  void _showCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final cartState = ref.watch(billingProvider);
            final notifier = ref.read(billingProvider.notifier);
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Checkout Bill & Pay',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cartState.totalItemCount} Items',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Loyalty Card Identification Field
                    const LoyaltyInputFieldWidget(),
                    const SizedBox(height: 10),

                    // Customer Details / Quick Register Prompt
                    if (cartState.customerId != null ||
                        cartState.loyaltyCardNumber.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withAlpha(50)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Customer: ${cartState.customerName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Phone: ${cartState.customerPhone.isNotEmpty ? cartState.customerPhone : "N/A"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cartState.rewardStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cartState.isRewardEligible
                                    ? Colors.orange.shade800
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Loyalty card not registered?',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          TextButton.icon(
                            onPressed: () => _showQuickRegisterCustomerDialog(context, ref),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: const Text('Quick Register (5s)'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    const Text(
                      'Payment Method:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            label: const Center(child: Text('💵 Cash')),
                            selected: cartState.paymentMethod == 'cash',
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: cartState.paymentMethod == 'cash'
                                  ? Colors.white
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) =>
                                notifier.setPaymentMethod('cash'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            label: const Center(child: Text('📲 UPI / QR')),
                            selected: cartState.paymentMethod == 'upi',
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: cartState.paymentMethod == 'upi'
                                  ? Colors.white
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => notifier.setPaymentMethod('upi'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            label: const Center(child: Text('💳 Card')),
                            selected: cartState.paymentMethod == 'card',
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: cartState.paymentMethod == 'card'
                                  ? Colors.white
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) =>
                                notifier.setPaymentMethod('card'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bill Summary Box (NO GST)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(
                                CurrencyFormatter.format(cartState.subtotal),
                              ),
                            ],
                          ),
                          if (cartState.serviceChargeAmount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Service Charge (${cartState.serviceChargePercentage.toStringAsFixed(1)}%):',
                                ),
                                Text(
                                  CurrencyFormatter.format(
                                    cartState.serviceChargeAmount,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(cartState.grandTotal),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        elevation: 4,
                      ),
                      onPressed: cartState.isSubmitting
                          ? null
                          : () async {
                              if (cartState.loyaltyCardNumber.isEmpty &&
                                  cartState.customerId == null) {
                                _showQuickRegisterCustomerDialog(context, ref);
                                return;
                              }

                              final result = await notifier.checkoutAndGenerateInvoice();
                              if (context.mounted) {
                                Navigator.pop(context);
                                if (result != null) {
                                  _showPostPaymentInvoiceDialog(context, result);
                                }
                              }
                            },
                      child: cartState.isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Complete Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickRegisterCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cardCtrl = TextEditingController(
      text: ref.read(billingProvider).loyaltyCardNumber,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Quick Customer Registration'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cardCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Loyalty Card Number *',
                    hintText: 'e.g. HMB-1001',
                    prefixIcon: Icon(Icons.credit_card_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Loyalty card is required' : null,
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final phoneInput = phoneCtrl.text.trim();
                  final customers = ref.read(customerProvider).customers;
                  if (customers.any((c) => c.phone.trim() == phoneInput)) {
                    SnackbarUtils.showError(ctx, 'Customer already exists with this mobile number.');
                    return;
                  }

                  try {
                    final created = await ref.read(billingProvider.notifier).quickRegisterCustomerAndSelect(
                      name: nameCtrl.text.trim(),
                      phone: phoneInput,
                      loyaltyCardNumber: cardCtrl.text.trim(),
                    );
                    if (ctx.mounted) {
                      if (created != null) {
                        Navigator.pop(ctx);
                        SnackbarUtils.showSuccess(context, 'Registered ${created.name}!');
                      } else {
                        SnackbarUtils.showError(ctx, 'Customer already exists with this mobile number.');
                      }
                    }
                  } catch (_) {
                    if (ctx.mounted) {
                      SnackbarUtils.showError(ctx, 'Customer already exists with this mobile number.');
                    }
                  }
                }
              },
              child: const Text('Save & Attach', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPostPaymentInvoiceDialog(BuildContext context, CheckoutResult result) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Bill Receipt #${result.orderNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.secondary, size: 54),
                const SizedBox(height: 10),
                const Text('Order Completed Successfully!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text('Total Paid: ₹${result.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 18)),
                const SizedBox(height: 12),

                if (result.rewardStatus.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      result.rewardStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (result.warning != null)
                  Text(result.warning!, style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (result.invoiceFile != null) {
                  await PdfInvoiceHelper.shareInvoiceViaWhatsApp(
                    result.invoiceFile!,
                    result.customerPhone,
                    result.orderNumber,
                  );
                } else if (result.customerPhone.isNotEmpty) {
                  await WhatsAppHelper.sendBillViaWhatsApp(
                    phone: result.customerPhone,
                    orderNumber: result.orderNumber,
                    grandTotal: result.grandTotal,
                    customerName: result.customerName,
                    loyaltyCardNumber: result.loyaltyCardNumber,
                    visitCount: result.visitCount,
                    rewardStatus: result.rewardStatus,
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
              label: const Text('Share PDF Bill via WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final billingState = ref.watch(billingProvider);
    final billingNotifier = ref.read(billingProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = menuState.categories;
    final selectedCategory = menuState.selectedCategoryId;
    final filteredItems = menuState.items.where((item) {
      if (!item.isAvailable) return false;
      final matchesSearch = _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCat = selectedCategory == null || item.categoryId == selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Billing & Checkout'),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: LiveBadgeWidget(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  child: _buildMenuGridSection(
                    context,
                    menuState,
                    billingState,
                    categories,
                    selectedCategory,
                    filteredItems,
                    billingNotifier,
                  ),
                ),
                _buildCartPanelSection(
                  context,
                  billingState,
                  billingNotifier,
                  isDark,
                  width: 320,
                ),
              ],
            );
          } else {
            // Responsive Mobile View (Single Column + Floating Bottom Checkout Bar)
            return Stack(
              children: [
                _buildMenuGridSection(
                  context,
                  menuState,
                  billingState,
                  categories,
                  selectedCategory,
                  filteredItems,
                  billingNotifier,
                  bottomPadding: billingState.cartItems.isNotEmpty ? 90.0 : 20.0,
                ),

                if (billingState.cartItems.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 120 : 40),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${billingState.totalItemCount} Items',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Cart Total',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(billingState.grandTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFFE91E63)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5722).withAlpha(90),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _showCheckoutBottomSheet,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Checkout to Bill',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.3, duration: 250.ms).fadeIn(),
                  ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMenuGridSection(
    BuildContext context,
    dynamic menuState,
    BillingState billingState,
    List categories,
    String? selectedCategory,
    List filteredItems,
    BillingNotifier billingNotifier, {
    double bottomPadding = 80.0,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchInputChanged,
            decoration: InputDecoration(
              hintText: 'Search food dishes...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchInputChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // Category Chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: FilterChip(
                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  label: const Text('All Dishes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: selectedCategory == null,
                  onSelected: (_) => ref
                      .read(menuProvider.notifier)
                      .selectCategory(null),
                ),
              ),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    label: Text(cat.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    selected: selectedCategory == cat.id,
                    onSelected: (_) => ref
                        .read(menuProvider.notifier)
                        .selectCategory(cat.id),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: menuState.isLoading
              ? const GridSkeletonLoader()
              : filteredItems.isEmpty
                  ? const EmptyStateWidget(
                      iconEmoji: '🍲',
                      title: 'No dishes found',
                      description: 'Try searching for another dish or clear filter.',
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 125,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (ctx, index) {
                        final item = filteredItems[index];
                        final emoji = _getItemEmoji(item.name, item.isVeg);

                        final cartIndex = billingState.cartItems.indexWhere(
                          (c) => c.menuItem.id == item.id,
                        );
                        final cartQty = cartIndex >= 0
                            ? billingState.cartItems[cartIndex].quantity
                            : 0;

                        return Card(
                          elevation: 1.5,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => billingNotifier.addToCart(item),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  DishImageWidget(
                                    imageUrl: item.image,
                                    fallbackEmoji: emoji,
                                    size: 34,
                                    borderRadius: 10,
                                  ),
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          CurrencyFormatter.format(item.price),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (cartQty == 0)
                                        InkWell(
                                          onTap: () =>
                                              billingNotifier.addToCart(item),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.add,
                                                color: Colors.white, size: 12),
                                          ),
                                        )
                                      else
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.primary.withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: AppColors.primary
                                                    .withAlpha(80)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => billingNotifier
                                                    .decrementQuantity(item.id),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: Icon(Icons.remove,
                                                      color: AppColors.primary,
                                                      size: 11),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                child: Text(
                                                  '$cartQty',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () => billingNotifier
                                                    .incrementQuantity(item.id),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: Icon(Icons.add,
                                                      color: AppColors.primary,
                                                      size: 11),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 12).ms);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCartPanelSection(
    BuildContext context,
    BillingState billingState,
    BillingNotifier billingNotifier,
    bool isDark, {
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Cart',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (billingState.cartItems.isNotEmpty)
                  TextButton(
                    onPressed: () => billingNotifier.clearCart(),
                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: billingState.cartItems.isEmpty
                ? const EmptyStateWidget(
                    iconEmoji: '🛒',
                    title: 'Cart is empty',
                    description: 'Tap on any dish to add it to the bill.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: billingState.cartItems.length,
                    separatorBuilder: (c, i) => const Divider(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = billingState.cartItems[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.menuItem.price),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () => billingNotifier.decrementQuantity(item.menuItem.id),
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => billingNotifier.incrementQuantity(item.menuItem.id),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),

          if (billingState.cartItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        CurrencyFormatter.format(billingState.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showCheckoutBottomSheet,
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white),
                      label: const Text('Checkout to Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

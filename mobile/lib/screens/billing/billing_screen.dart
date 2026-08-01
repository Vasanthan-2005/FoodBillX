import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/pdf_invoice_helper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/menu_item_model.dart';
import '../../providers/billing_provider.dart';
import '../../providers/menu_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  const BillingScreen({super.key, required this.onOpenSettings});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getItemEmoji(String name, bool isVeg) {
    final lower = name.toLowerCase();
    if (lower.contains('burger')) return '🍔';
    if (lower.contains('pizza')) return '🍕';
    if (lower.contains('biryani') || lower.contains('rice')) return '🍚';
    if (lower.contains('roll') || lower.contains('wrap')) return '🌯';
    if (lower.contains('fries')) return '🍟';
    if (lower.contains('drink') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('soda')) {
      return '🥤';
    }
    if (lower.contains('ice') ||
        lower.contains('dessert') ||
        lower.contains('cake')) {
      return '🍨';
    }
    if (lower.contains('chicken') || lower.contains('meat')) return '🍗';
    if (lower.contains('paneer') || isVeg) return '🥗';
    return '🍽';
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
                          'Checkout Order Bill',
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

                    // Customer Details
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Customer Phone (Optional for Loyalty)',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) {
                        notifier.setCustomerInfo(
                          name: cartState.customerName,
                          phone: val,
                          id: cartState.customerId,
                        );
                      },
                    ),
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

                    // Bill Summary Calculation Box
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
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GST Tax (5%):'),
                              Text(
                                CurrencyFormatter.format(cartState.gstAmount),
                              ),
                            ],
                          ),
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
                        elevation: 4,
                      ),
                      onPressed: cartState.isSubmitting
                          ? null
                          : () async {
                              final pdfFile = await notifier
                                  .checkoutAndGenerateInvoice();
                              if (context.mounted) Navigator.pop(ctx);

                              if (pdfFile != null && context.mounted) {
                                SnackbarUtils.showSuccess(
                                  context,
                                  'Order Placed! PDF Invoice Generated.',
                                );

                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text(
                                      'Share Invoice via WhatsApp?',
                                    ),
                                    content: const Text(
                                      'Would you like to share the digital PDF invoice now?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx),
                                        child: const Text('Skip'),
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.share),
                                        label: const Text('Share WhatsApp'),
                                        onPressed: () {
                                          Navigator.pop(dialogCtx);
                                          PdfInvoiceHelper.shareInvoiceViaWhatsApp(
                                            pdfFile,
                                            cartState.customerPhone,
                                            'POS Bill',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              } else if (context.mounted) {
                                SnackbarUtils.showError(
                                  context,
                                  'Failed to process checkout',
                                );
                              }
                            },
                      child: cartState.isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'CONFIRM & PRINT BILL (${CurrencyFormatter.format(cartState.grandTotal)})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final cartState = ref.watch(billingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile POS Billing'),
        actions: [
          if (cartState.cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: 'Clear Cart',
              onPressed: () => ref.read(billingProvider.notifier).clearCart(),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      bottomNavigationBar: cartState.cartItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cartState.totalItemCount} Items In Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
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
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _showCheckoutBottomSheet,
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text(
                        'VIEW BILL & PAY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 250.ms)
          : null,
      body: Column(
        children: [
          // Search Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  ref.read(menuProvider.notifier).setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search food menu items...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(menuProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Categories Horizontal Chips Bar
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: const Text('All Dishes'),
                    selected: menuState.selectedCategoryId == null,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: menuState.selectedCategoryId == null
                          ? Colors.white
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) =>
                        ref.read(menuProvider.notifier).selectCategory(null),
                  ),
                ),
                ...menuState.categories.map((c) {
                  final isSelected = menuState.selectedCategoryId == c.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) =>
                          ref.read(menuProvider.notifier).selectCategory(c.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Food Items Grid View
          Expanded(
            child: menuState.isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: 6,
                    itemBuilder: (ctx, idx) => const MetricCardSkeleton(),
                  )
                : menuState.items.isEmpty
                ? const EmptyStateWidget(
                    iconEmoji: '🍔',
                    title: 'No food items available',
                    description:
                        'No menu items match your filter or search criteria.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.05,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: menuState.items.length,
                    itemBuilder: (ctx, index) {
                      final MenuItemModel item = menuState.items[index];
                      final cartIndex = cartState.cartItems.indexWhere(
                        (c) => c.menuItem.id == item.id,
                      );
                      final inCartQty = cartIndex >= 0
                          ? cartState.cartItems[cartIndex].quantity
                          : 0;
                      final emoji = _getItemEmoji(item.name, item.isVeg);

                      return InkWell(
                        onTap: item.isAvailable
                            ? () => ref
                                  .read(billingProvider.notifier)
                                  .addToCart(item)
                            : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: item.isAvailable
                              ? (isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard)
                              : (isDark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade200),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Veg / Non-Veg Tag Badge
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: item.isVeg
                                              ? AppColors.vegGreen
                                              : AppColors.nonVegRed,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: item.isVeg
                                            ? AppColors.vegGreen
                                            : AppColors.nonVegRed,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const Spacer(),
                                    if (inCartQty > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '$inCartQty in cart',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),

                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: item.isAvailable
                                        ? null
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(item.price),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: item.isAvailable
                                            ? AppColors.primary
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (item.isAvailable)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 20).ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

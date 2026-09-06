import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../models/customer_model.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';

class LoyaltyInputFieldWidget extends ConsumerStatefulWidget {
  const LoyaltyInputFieldWidget({super.key});

  @override
  ConsumerState<LoyaltyInputFieldWidget> createState() =>
      _LoyaltyInputFieldWidgetState();
}

class _LoyaltyInputFieldWidgetState
    extends ConsumerState<LoyaltyInputFieldWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showSuggestions = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val, BillingNotifier notifier) {
    setState(() {
      _showSuggestions = true;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (val.trim().isNotEmpty) {
        notifier.lookupAndSelectByLoyaltyCard(val.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final cartState = ref.watch(billingProvider);
    final notifier = ref.read(billingProvider.notifier);

    // Keep controller in sync if cart loyaltyCardNumber changes externally
    if (!_focusNode.hasFocus &&
        _controller.text != cartState.loyaltyCardNumber) {
      _controller.text = cartState.loyaltyCardNumber;
    }

    final query = _controller.text.trim().toLowerCase();
    final allCards = customerState.customers
        .where((c) => c.loyaltyCardNumber.trim().isNotEmpty)
        .toList();

    final List<CustomerModel> suggestions = query.isEmpty
        ? allCards.take(8).toList()
        : allCards.where((c) {
            return c.loyaltyCardNumber.toLowerCase().contains(query) ||
                c.phone.contains(query) ||
                c.name.toLowerCase().contains(query);
          }).take(8).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Loyalty Card Number *',
            hintText: 'Click or type card number (e.g. HMB-1001)...',
            prefixIcon: const Icon(Icons.credit_card_rounded),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    tooltip: 'Clear card',
                    onPressed: () {
                      _controller.clear();
                      notifier.clearCustomer();
                      setState(() {
                        _showSuggestions = _focusNode.hasFocus;
                      });
                    },
                  )
                : (_showSuggestions
                    ? IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        tooltip: 'Hide suggestions',
                        onPressed: () {
                          _focusNode.unfocus();
                          setState(() => _showSuggestions = false);
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                        tooltip: 'Show registered cards',
                        onPressed: () {
                          _focusNode.requestFocus();
                          setState(() => _showSuggestions = true);
                        },
                      )),
          ),
          onTap: () {
            setState(() => _showSuggestions = true);
          },
          onChanged: (val) => _onSearchChanged(val, notifier),
        ),

        // Inline Suggestion List - Appears directly underneath the field, always visible
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withAlpha(90),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(18),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.loyalty_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            query.isEmpty
                                ? 'Registered Cards (${allCards.length} found):'
                                : 'Matching Cards (${suggestions.length}):',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          _focusNode.unfocus();
                          setState(() => _showSuggestions = false);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            '✕ Close',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 48),
                    itemBuilder: (context, index) {
                      final customer = suggestions[index];
                      final isSelected = cartState.customerId == customer.id;
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.credit_card_rounded,
                            size: 18,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                customer.loyaltyCardNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '📞 ${customer.phone.isNotEmpty ? customer.phone : "No phone"} • ${customer.totalVisits} visits',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 22,
                              )
                            : const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                        onTap: () {
                          _controller.text = customer.loyaltyCardNumber;
                          notifier.selectCustomer(customer);
                          _focusNode.unfocus();
                          setState(() => _showSuggestions = false);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

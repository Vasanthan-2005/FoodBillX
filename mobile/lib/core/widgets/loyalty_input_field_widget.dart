import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Timer? _debounceTimer;

  void _onSearchChanged(String val, BillingNotifier notifier) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (val.trim().isNotEmpty) {
        notifier.lookupAndSelectByLoyaltyCard(val.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final cartState = ref.watch(billingProvider);
    final notifier = ref.read(billingProvider.notifier);

    return RawAutocomplete<CustomerModel>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<CustomerModel>.empty();
        return customerState.customers.where((c) {
          return c.loyaltyCardNumber.toLowerCase().contains(query) ||
              c.phone.contains(query) ||
              c.name.toLowerCase().contains(query);
        });
      },
      onSelected: (CustomerModel selection) {
        notifier.selectCustomer(selection);
      },
      displayStringForOption: (CustomerModel option) => option.loyaltyCardNumber,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        if (textEditingController.text.isEmpty &&
            cartState.loyaltyCardNumber.isNotEmpty) {
          textEditingController.text = cartState.loyaltyCardNumber;
        }
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Loyalty Card Number *',
            hintText: 'Enter loyalty card number (e.g. HMB-1001)...',
            prefixIcon: const Icon(Icons.credit_card_rounded),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      textEditingController.clear();
                      notifier.clearCustomer();
                    },
                  )
                : null,
          ),
          onChanged: (val) => _onSearchChanged(val, notifier),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 320,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final CustomerModel option = options.elementAt(index);
                  return ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(
                      '${option.name} (${option.loyaltyCardNumber})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Phone: ${option.phone}'),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

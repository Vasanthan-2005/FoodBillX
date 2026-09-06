import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pdf_invoice_helper.dart';
import '../models/cart_item_model.dart';
import '../models/customer_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import 'customer_provider.dart';
import 'dashboard_provider.dart';
import 'orders_provider.dart';
import 'settings_provider.dart';
import 'sync_provider.dart';

class CheckoutResult {
  final String orderNumber;
  final File? invoiceFile;
  final String? warning;
  final String customerPhone;
  final String customerName;
  final String loyaltyCardNumber;
  final int visitCount;
  final String rewardStatus;
  final double grandTotal;

  const CheckoutResult({
    required this.orderNumber,
    this.invoiceFile,
    this.warning,
    required this.customerPhone,
    required this.customerName,
    required this.loyaltyCardNumber,
    required this.visitCount,
    required this.rewardStatus,
    required this.grandTotal,
  });
}

class BillingState {
  final List<CartItem> cartItems;
  final String customerName;
  final String customerPhone;
  final String? customerId;
  final String loyaltyCardNumber;
  final int currentVisitCount;
  final String rewardStatus;
  final bool isRewardEligible;

  final String paymentMethod;
  final double discountAmount;
  final double serviceChargePercentage;
  final bool isSubmitting;
  final String? errorMessage;

  BillingState({
    required this.cartItems,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.customerId,
    this.loyaltyCardNumber = '',
    this.currentVisitCount = 1,
    this.rewardStatus = '',
    this.isRewardEligible = false,
    this.paymentMethod = 'cash',
    this.discountAmount = 0.0,
    this.serviceChargePercentage = 0.0,
    this.isSubmitting = false,
    this.errorMessage,
  });

  factory BillingState.initial() => BillingState(cartItems: []);

  double get subtotal {
    return cartItems.fold(
      0.0,
      (sum, item) => sum + item.menuItem.price * item.quantity,
    );
  }

  double get totalDiscount {
    final itemDiscounts = cartItems.fold(
      0.0,
      (sum, item) => sum + item.discountAmount,
    );
    return itemDiscounts + discountAmount;
  }

  double get subtotalAfterDiscount {
    final res = subtotal - totalDiscount;
    return res < 0 ? 0 : res;
  }

  double get gstAmount => 0.0;

  double get grandTotal {
    return (subtotalAfterDiscount + serviceChargeAmount).roundToDouble();
  }

  double get serviceChargeAmount =>
      subtotalAfterDiscount * serviceChargePercentage / 100;

  int get totalItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  BillingState copyWith({
    List<CartItem>? cartItems,
    String? customerName,
    String? customerPhone,
    String? customerId,
    String? loyaltyCardNumber,
    int? currentVisitCount,
    String? rewardStatus,
    bool? isRewardEligible,
    bool clearCustomer = false,
    String? paymentMethod,
    double? discountAmount,
    double? serviceChargePercentage,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      customerName: clearCustomer
          ? 'Walk-in Customer'
          : (customerName ?? this.customerName),
      customerPhone: clearCustomer ? '' : (customerPhone ?? this.customerPhone),
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      loyaltyCardNumber: clearCustomer ? '' : (loyaltyCardNumber ?? this.loyaltyCardNumber),
      currentVisitCount: clearCustomer ? 1 : (currentVisitCount ?? this.currentVisitCount),
      rewardStatus: clearCustomer ? '' : (rewardStatus ?? this.rewardStatus),
      isRewardEligible: clearCustomer ? false : (isRewardEligible ?? this.isRewardEligible),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceChargePercentage:
          serviceChargePercentage ?? this.serviceChargePercentage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  final OrderRepository _orderRepo;
  final Ref _ref;

  BillingNotifier(
    this._orderRepo,
    this._ref,
  ) : super(BillingState.initial());

  void addToCart(MenuItemModel item) {
    final existingIndex = state.cartItems.indexWhere(
      (c) => c.menuItem.id == item.id,
    );
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.cartItems);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      state = state.copyWith(cartItems: updatedItems);
    } else {
      state = state.copyWith(
        cartItems: [
          ...state.cartItems,
          CartItem(menuItem: item),
        ],
      );
    }
  }

  void incrementQuantity(String itemId) {
    final list = state.cartItems.map((item) {
      if (item.menuItem.id == itemId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
    state = state.copyWith(cartItems: list);
  }

  void decrementQuantity(String itemId) {
    final list = <CartItem>[];
    for (final item in state.cartItems) {
      if (item.menuItem.id == itemId) {
        if (item.quantity > 1) {
          list.add(item.copyWith(quantity: item.quantity - 1));
        }
      } else {
        list.add(item);
      }
    }
    state = state.copyWith(cartItems: list);
  }

  void removeFromCart(String itemId) {
    final list = state.cartItems.where((i) => i.menuItem.id != itemId).toList();
    state = state.copyWith(cartItems: list);
  }

  Future<CustomerModel?> lookupAndSelectByLoyaltyCard(String cardNumber) async {
    final card = cardNumber.trim();
    if (card.isEmpty) return null;

    final customerNotifier = _ref.read(customerProvider.notifier);
    final customer = await customerNotifier.searchByLoyaltyCardNumber(card);

    if (customer != null) {
      selectCustomer(customer);
    }
    return customer;
  }

  void selectCustomer(CustomerModel customer) {
    final settings = _ref.read(settingsProvider).settings;
    final targetVisits = settings?.loyaltyTargetVisits ?? 6;
    final rewardType = settings?.loyaltyRewardType ?? 'Free Drink';

    final nextVisits = customer.totalVisits + 1;
    final isEligible = (nextVisits % targetVisits == 0);
    final rewardText = isEligible
        ? '🎉 Loyalty Reward Available: $rewardType'
        : 'Visit #$nextVisits (${targetVisits - (nextVisits % targetVisits)} more visits for $rewardType)';

    state = state.copyWith(
      customerName: customer.name,
      customerPhone: customer.phone,
      customerId: customer.id,
      loyaltyCardNumber: customer.loyaltyCardNumber,
      currentVisitCount: nextVisits,
      rewardStatus: rewardText,
      isRewardEligible: isEligible,
    );
  }

  Future<CustomerModel?> quickRegisterCustomerAndSelect({
    required String name,
    required String phone,
    required String loyaltyCardNumber,
  }) async {
    final customerNotifier = _ref.read(customerProvider.notifier);
    final created = await customerNotifier.quickCreateCustomer(
      name: name.trim(),
      phone: phone.trim(),
      loyaltyCardNumber: loyaltyCardNumber.trim(),
    );

    if (created != null) {
      selectCustomer(created);
    }
    return created;
  }

  void setCustomerInfo({
    String? name,
    String? phone,
    String? id,
    String? loyaltyCardNumber,
    int? visits,
  }) {
    final settings = _ref.read(settingsProvider).settings;
    final targetVisits = settings?.loyaltyTargetVisits ?? 6;
    final rewardType = settings?.loyaltyRewardType ?? 'Free Drink';

    final effectivePhone = phone ?? state.customerPhone;
    CustomerModel? matchedCustomer;

    if (effectivePhone.isNotEmpty) {
      matchedCustomer = _ref.read(customerProvider.notifier).findByPhone(effectivePhone);
    }

    final custName = name ?? matchedCustomer?.name ?? (effectivePhone.isNotEmpty ? 'Registered Customer' : 'Walk-in Customer');
    final custId = id ?? matchedCustomer?.id;
    final custCard = loyaltyCardNumber ?? matchedCustomer?.loyaltyCardNumber ?? '';
    final nextVisits = (visits ?? matchedCustomer?.totalVisits ?? 0) + 1;

    final isEligible = (nextVisits % targetVisits == 0);
    final rewardText = isEligible
        ? '🎉 Loyalty Reward Available: $rewardType'
        : 'Visit #$nextVisits (${targetVisits - (nextVisits % targetVisits)} more visits for $rewardType)';

    state = state.copyWith(
      customerName: custName,
      customerPhone: effectivePhone,
      customerId: custId,
      loyaltyCardNumber: custCard,
      currentVisitCount: nextVisits,
      rewardStatus: rewardText,
      isRewardEligible: isEligible,
    );
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setDiscountAmount(double discount) {
    state = state.copyWith(discountAmount: discount);
  }

  void setServiceChargePercentage(double percentage) {
    state = state.copyWith(serviceChargePercentage: percentage);
  }

  void clearCart() {
    state = BillingState(
      cartItems: const [],
      serviceChargePercentage: state.serviceChargePercentage,
    );
  }

  Future<CheckoutResult?> checkoutAndGenerateInvoice() async {
    if (state.cartItems.isEmpty) return null;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final checkout = state;
      final settings = _ref.read(settingsProvider).settings;
      final prefix = settings?.invoicePrefix ?? 'B';

      final items = checkout.cartItems.map((ci) {
        return OrderItemModel(
          menuItemId: ci.menuItem.id,
          name: ci.menuItem.name,
          price: ci.menuItem.price,
          quantity: ci.quantity,
          gstPercentage: 0.0,
          subtotal: ci.subtotal,
          notes: ci.notes,
        );
      }).toList();

      final createdOrder = await _orderRepo.create(
        customerServerId: checkout.customerId,
        customerName: checkout.customerName,
        customerPhone: checkout.customerPhone,
        loyaltyCardNumber: checkout.loyaltyCardNumber,
        items: items,
        subtotal: checkout.subtotal,
        discountAmount: checkout.totalDiscount,
        gstAmount: checkout.gstAmount,
        serviceChargeAmount: checkout.serviceChargeAmount,
        grandTotal: checkout.grandTotal,
        paymentMethod: checkout.paymentMethod,
      );

      final orderNumber = createdOrder.orderNumber;

      // Auto-refresh Dashboard and Orders data
      _ref.read(dashboardProvider.notifier).refresh();
      _ref.read(ordersProvider.notifier).loadOrders(forceSpinner: false);
      if (checkout.customerPhone.isNotEmpty) {
        _ref.read(customerProvider.notifier).loadCustomers();
      }

      clearCart();
      _ref.read(syncProvider.notifier).autoSyncIfOnline();

      try {
        final pdfFile = await PdfInvoiceHelper.generateInvoicePdf(
          businessName: settings?.businessName ?? 'HMB Bills',
          businessPhone: settings?.phone ?? '',
          businessAddress: settings?.address ?? '',
          gstin: settings?.gstin ?? '',
          invoicePrefix: prefix,
          invoiceFooter:
              settings?.invoiceFooter ?? 'Thank you for dining with us!',
          orderNumber: orderNumber,
          orderDate: DateTime.now(),
          customerName: checkout.customerName,
          customerPhone: checkout.customerPhone,
          loyaltyCardNumber: checkout.loyaltyCardNumber,
          visitCount: checkout.currentVisitCount,
          rewardStatus: checkout.rewardStatus,
          items: checkout.cartItems.map((i) {
            return {
              'name': i.menuItem.name,
              'price': i.menuItem.price,
              'quantity': i.quantity,
              'subtotal': i.subtotal,
            };
          }).toList(),
          subtotal: checkout.subtotal,
          discount: checkout.totalDiscount,
          gstAmount: checkout.gstAmount,
          serviceChargeAmount: checkout.serviceChargeAmount,
          grandTotal: checkout.grandTotal,
          paymentMethod: checkout.paymentMethod,
        );
        return CheckoutResult(
          orderNumber: orderNumber,
          invoiceFile: pdfFile,
          customerPhone: checkout.customerPhone,
          customerName: checkout.customerName,
          loyaltyCardNumber: checkout.loyaltyCardNumber,
          visitCount: checkout.currentVisitCount,
          rewardStatus: checkout.rewardStatus,
          grandTotal: checkout.grandTotal,
        );
      } catch (error) {
        return CheckoutResult(
          orderNumber: orderNumber,
          warning: 'Order saved, but the PDF invoice could not be generated.',
          customerPhone: checkout.customerPhone,
          customerName: checkout.customerName,
          loyaltyCardNumber: checkout.loyaltyCardNumber,
          visitCount: checkout.currentVisitCount,
          rewardStatus: checkout.rewardStatus,
          grandTotal: checkout.grandTotal,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }
}

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>((
  ref,
) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  final notifier = BillingNotifier(
    orderRepo,
    ref,
  );
  final initialServiceCharge =
      ref.read(settingsProvider).settings?.serviceChargePercentage ?? 0;
  notifier.setServiceChargePercentage(initialServiceCharge);
  ref.listen<double>(
    settingsProvider.select(
      (state) => state.settings?.serviceChargePercentage ?? 0,
    ),
    (_, next) => notifier.setServiceChargePercentage(next),
  );
  return notifier;
});

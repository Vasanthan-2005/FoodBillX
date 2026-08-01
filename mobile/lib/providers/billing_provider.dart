import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/order_number_generator.dart';
import '../core/sync/sync_status_notifier.dart';
import '../core/utils/pdf_invoice_helper.dart';
import '../local_db/isar_database.dart';
import '../local_db/schemas/order_schema.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';
import '../repositories/customer_repository.dart';
import '../repositories/order_repository.dart';
import 'settings_provider.dart';

class BillingState {
  final List<CartItem> cartItems;
  final String customerName;
  final String customerPhone;
  final String? customerId;
  final String paymentMethod;
  final double discountAmount;
  final bool isSubmitting;
  final String? errorMessage;

  BillingState({
    required this.cartItems,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.customerId,
    this.paymentMethod = 'cash',
    this.discountAmount = 0.0,
    this.isSubmitting = false,
    this.errorMessage,
  });

  factory BillingState.initial() => BillingState(cartItems: []);

  double get subtotal {
    return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
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

  // Calculate GST using per-item gstPercentage
  double get gstAmount {
    return cartItems.fold(0.0, (sum, item) {
      final itemNet = item.menuItem.finalPrice * item.quantity;
      return sum + (itemNet * item.menuItem.gstPercentage / 100);
    });
  }

  double get grandTotal {
    return (subtotalAfterDiscount + gstAmount).roundToDouble();
  }

  int get totalItemCount {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  BillingState copyWith({
    List<CartItem>? cartItems,
    String? customerName,
    String? customerPhone,
    String? customerId,
    bool clearCustomer = false,
    String? paymentMethod,
    double? discountAmount,
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
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discountAmount: discountAmount ?? this.discountAmount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  final OrderRepository _orderRepo;
  final CustomerRepository _customerRepo;
  final OrderNumberGenerator _orderNumGen;
  final SyncStatusNotifier _syncStatus;
  final Ref _ref;

  BillingNotifier(
    this._orderRepo,
    this._customerRepo,
    this._orderNumGen,
    this._syncStatus,
    this._ref,
  ) : super(BillingState.initial());

  void addToCart(MenuItemModel item) {
    final existingIndex = state.cartItems.indexWhere(
      (c) => c.menuItem.id == item.id,
    );
    if (existingIndex >= 0) {
      // Create a brand-new immutable list with the updated CartItem
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
        // quantity == 1 → remove from cart
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

  void setCustomerInfo({String? name, String? phone, String? id}) {
    state = state.copyWith(
      customerName: name ?? 'Walk-in Customer',
      customerPhone: phone ?? '',
      customerId: id,
    );
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setDiscountAmount(double discount) {
    state = state.copyWith(discountAmount: discount);
  }

  void clearCart() {
    state = BillingState.initial();
  }

  /// Checkout: saves order locally (instant), generates PDF, queues sync.
  Future<File?> checkoutAndGenerateInvoice() async {
    if (state.cartItems.isEmpty) return null;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final settings = _ref.read(settingsProvider).settings;
      final prefix = settings?.invoicePrefix ?? 'INV-';

      // 1. Generate order number locally.
      final orderNumber = await _orderNumGen.generate(prefix);

      // 2. Build embedded order items.
      final items = state.cartItems.map((ci) {
        return OrderItemEmbedded()
          ..menuItemServerId = ci.menuItem.id
          ..name = ci.menuItem.name
          ..price = ci.menuItem.price
          ..quantity = ci.quantity
          ..gstPercentage = ci.menuItem.gstPercentage
          ..subtotal = ci.subtotal
          ..notes = ci.notes;
      }).toList();

      // 3. Save order to Isar (instant — no network needed).
      await _orderRepo.create(
        orderNumber: orderNumber,
        customerServerId: state.customerId,
        customerName: state.customerName,
        customerPhone: state.customerPhone,
        items: items,
        subtotal: state.subtotal,
        discountAmount: state.totalDiscount,
        gstAmount: state.gstAmount,
        grandTotal: state.grandTotal,
        paymentMethod: state.paymentMethod,
      );

      // 4. Update customer visit stats locally (if linked).
      if (state.customerId != null) {
        await _customerRepo.recordVisit(state.customerId!, state.grandTotal);
      }

      // 5. Generate PDF invoice (pure local operation).
      final pdfFile = await PdfInvoiceHelper.generateInvoicePdf(
        businessName: settings?.businessName ?? 'Food Truck Outlet',
        businessPhone: settings?.phone ?? '',
        businessAddress: settings?.address ?? '',
        gstin: settings?.gstin ?? '',
        invoicePrefix: prefix,
        orderNumber: orderNumber,
        orderDate: DateTime.now(),
        customerName: state.customerName,
        customerPhone: state.customerPhone,
        items: state.cartItems.map((i) {
          return {
            'name': i.menuItem.name,
            'price': i.menuItem.price,
            'quantity': i.quantity,
            'subtotal': i.subtotal,
          };
        }).toList(),
        subtotal: state.subtotal,
        discount: state.totalDiscount,
        gstAmount: state.gstAmount,
        grandTotal: state.grandTotal,
        paymentMethod: state.paymentMethod,
      );

      _syncStatus.refreshPending();
      clearCart();
      return pdfFile;
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
  final customerRepo = ref.watch(customerRepositoryProvider);
  final isar = ref.watch(isarProvider);
  final syncStatus = ref.watch(syncStatusProvider.notifier);
  final orderNumGen = OrderNumberGenerator(isar);
  return BillingNotifier(orderRepo, customerRepo, orderNumGen, syncStatus, ref);
});

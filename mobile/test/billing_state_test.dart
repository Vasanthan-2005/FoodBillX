import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/cart_item_model.dart';
import 'package:mobile/models/menu_item_model.dart';
import 'package:mobile/providers/billing_provider.dart';

void main() {
  test('billing totals apply item discount exactly once', () {
    final menuItem = MenuItemModel(
      id: 'local-1',
      categoryId: 'category-1',
      name: 'Test meal',
      description: '',
      price: 100,
      discount: 10,
      gstPercentage: 5,
      image: '',
      isVeg: true,
      isAvailable: true,
    );
    final state = BillingState(
      cartItems: [CartItem(menuItem: menuItem, quantity: 2)],
      discountAmount: 10,
      serviceChargePercentage: 10,
    );

    expect(state.subtotal, 200);
    expect(state.totalDiscount, 30);
    expect(state.subtotalAfterDiscount, 170);
    expect(state.gstAmount, closeTo(8.5, 0.001));
    expect(state.serviceChargeAmount, 17);
    expect(state.grandTotal, 196);
  });

  test('discounts cannot make the taxable subtotal negative', () {
    final menuItem = MenuItemModel(
      id: 'local-2',
      categoryId: 'category-1',
      name: 'Test drink',
      description: '',
      price: 50,
      discount: 0,
      gstPercentage: 5,
      image: '',
      isVeg: true,
      isAvailable: true,
    );
    final state = BillingState(
      cartItems: [CartItem(menuItem: menuItem)],
      discountAmount: 100,
    );

    expect(state.subtotalAfterDiscount, 0);
    expect(state.grandTotal, 0);
  });
}

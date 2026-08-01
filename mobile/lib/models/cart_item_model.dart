import 'menu_item_model.dart';

class CartItem {
  final MenuItemModel menuItem;
  final int quantity;
  final String notes;

  const CartItem({required this.menuItem, this.quantity = 1, this.notes = ''});

  CartItem copyWith({MenuItemModel? menuItem, int? quantity, String? notes}) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  double get subtotal => menuItem.finalPrice * quantity;

  double get discountAmount => menuItem.discount * quantity;
}

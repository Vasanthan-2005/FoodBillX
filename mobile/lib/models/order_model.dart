class OrderItemModel {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final double gstPercentage;
  final double subtotal;
  final String notes;

  OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.gstPercentage = 0.0,
    required this.subtotal,
    this.notes = '',
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      menuItemId: json['menuItem']?.toString() ?? json['menuItemId']?.toString() ?? '',
      name: json['name'] ?? 'Dish',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ??
          ((json['price'] as num?)?.toDouble() ?? 0.0) * ((json['quantity'] as num?)?.toInt() ?? 1),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'gstPercentage': gstPercentage,
      'subtotal': subtotal,
      'notes': notes,
    };
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String loyaltyCardNumber;
  final int visitCount;
  final String rewardStatus;
  final String orderStatus;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discountAmount;
  final double gstAmount;
  final double serviceChargeAmount;
  final double grandTotal;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.loyaltyCardNumber = '',
    this.visitCount = 1,
    this.rewardStatus = '',
    this.orderStatus = 'completed',
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.gstAmount = 0.0,
    this.serviceChargeAmount = 0.0,
    required this.grandTotal,
    required this.paymentMethod,
    this.paymentStatus = 'paid',
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? 'ORD-001',
      customerId: json['customerId']?.toString() ?? json['customer']?.toString(),
      customerName: json['customerName'] ?? 'Walk-in Customer',
      customerPhone: json['customerPhone'] ?? '',
      loyaltyCardNumber: json['loyaltyCardNumber'] ?? '',
      visitCount: (json['visitCount'] as num?)?.toInt() ?? 1,
      rewardStatus: json['rewardStatus'] ?? '',
      orderStatus: json['orderStatus'] ?? 'completed',
      items: rawItems
          .map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      serviceChargeAmount:
          (json['serviceChargeAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentStatus: json['paymentStatus'] ?? 'paid',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'loyaltyCardNumber': loyaltyCardNumber,
      'visitCount': visitCount,
      'rewardStatus': rewardStatus,
      'orderStatus': orderStatus,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'gstAmount': gstAmount,
      'serviceChargeAmount': serviceChargeAmount,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }
}

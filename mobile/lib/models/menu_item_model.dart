class MenuItemModel {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final double price;
  final double discount;
  final double gstPercentage;
  final String image;
  final bool isVeg;
  final bool isAvailable;

  MenuItemModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.discount,
    required this.gstPercentage,
    required this.image,
    required this.isVeg,
    required this.isAvailable,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    String catId = '';
    String? catName;

    if (json['category'] is Map) {
      catId = json['category']['_id'] ?? json['category']['id'] ?? '';
      catName = json['category']['name'];
    } else if (json['category'] is String) {
      catId = json['category'];
    }

    return MenuItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      categoryId: catId,
      categoryName: catName,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 5.0,
      image: json['image'] ?? '',
      isVeg: json['isVeg'] ?? true,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'category': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'discount': discount,
      'gstPercentage': gstPercentage,
      'image': image,
      'isVeg': isVeg,
      'isAvailable': isAvailable,
    };
    if (id.trim().isNotEmpty) {
      map['id'] = id;
      map['_id'] = id;
    }
    return map;
  }

  String get imageUrl => image;

  double get finalPrice {
    final res = price - discount;
    return res < 0 ? 0 : res;
  }
}

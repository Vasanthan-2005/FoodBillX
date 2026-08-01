class ExpenseCategoryModel {
  final String id;
  final String name;
  final String icon;
  final bool isActive;

  ExpenseCategoryModel({
    required this.id,
    required this.name,
    this.icon = 'receipt_long',
    this.isActive = true,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'receipt_long',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'isActive': isActive};
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String loyaltyCardNumber;
  final int totalVisits;
  final double totalSpent;
  final int loyaltyPoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.notes = '',
    this.loyaltyCardNumber = '',
    this.totalVisits = 0,
    this.totalSpent = 0.0,
    this.loyaltyPoints = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
      loyaltyCardNumber: json['loyaltyCardNumber'] ?? json['cardNumber'] ?? '',
      totalVisits: (json['totalVisits'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'loyaltyCardNumber': loyaltyCardNumber,
      'totalVisits': totalVisits,
      'totalSpent': totalSpent,
      'loyaltyPoints': loyaltyPoints,
    };
  }
}

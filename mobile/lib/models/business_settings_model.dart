class BusinessSettingsModel {
  final String id;
  final String businessName;
  final String logo;
  final String phone;
  final String address;
  final String gstin;
  final String currency;
  final String invoicePrefix;
  final double taxPercentage;
  final double serviceChargePercentage;
  final String invoiceFooter;
  final int loyaltyTargetVisits;
  final String loyaltyRewardType;
  final String loyaltyRewardDescription;

  BusinessSettingsModel({
    required this.id,
    required this.businessName,
    required this.logo,
    required this.phone,
    required this.address,
    required this.gstin,
    required this.currency,
    required this.invoicePrefix,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.invoiceFooter,
    this.loyaltyTargetVisits = 6,
    this.loyaltyRewardType = 'Free Drink',
    this.loyaltyRewardDescription = 'Free Drink',
  });

  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) {
    return BusinessSettingsModel(
      id: json['_id'] ?? json['id'] ?? '',
      businessName: json['businessName'] ?? 'HMB Bills',
      logo: json['logo'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      gstin: json['gstin'] ?? '',
      currency: json['currency'] ?? '₹',
      invoicePrefix: json['invoicePrefix'] ?? 'B',
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble() ?? 5.0,
      serviceChargePercentage:
          (json['serviceChargePercentage'] as num?)?.toDouble() ?? 0.0,
      invoiceFooter: json['invoiceFooter'] ?? 'Thank you for dining with us!',
      loyaltyTargetVisits: (json['loyaltyTargetVisits'] as num?)?.toInt() ?? 6,
      loyaltyRewardType: json['loyaltyRewardType'] ?? 'Free Drink',
      loyaltyRewardDescription: json['loyaltyRewardDescription'] ?? 'Free Drink',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'logo': logo,
      'phone': phone,
      'address': address,
      'gstin': gstin,
      'currency': currency,
      'invoicePrefix': invoicePrefix,
      'taxPercentage': taxPercentage,
      'serviceChargePercentage': serviceChargePercentage,
      'invoiceFooter': invoiceFooter,
      'loyaltyTargetVisits': loyaltyTargetVisits,
      'loyaltyRewardType': loyaltyRewardType,
      'loyaltyRewardDescription': loyaltyRewardDescription,
    };
  }
}

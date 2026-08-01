class ExpenseModel {
  final String id;
  final String category;
  final String title;
  final double amount;
  final DateTime date;
  final String notes;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.title,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['createdAt'];
    DateTime parsedDate = DateTime.now();
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }
    return ExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      category: json['category'] ?? 'Miscellaneous',
      title: json['title'] ?? json['category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}

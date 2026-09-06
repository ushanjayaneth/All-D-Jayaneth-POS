class Expense {
  final int? id;
  final double amount;
  final String? description;
  final String type; // e.g. Rent, Utilities, Salary, Other
  final int createdAt;

  Expense({
    this.id,
    required this.amount,
    this.description,
    this.type = 'General',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': type, // Map to DB category column
      'created_at': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description']?.toString(),
      type: map['type']?.toString() ?? map['category']?.toString() ?? 'General',
      createdAt: (map['created_at'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

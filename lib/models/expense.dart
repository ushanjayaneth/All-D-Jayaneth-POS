class Expense {
  final int id;
  final double amount;
  final String description;
  final String category; // 'utilities', 'salary', 'inventory', 'other'
  final int createdAt;

  Expense({
    this.id = 0,
    required this.amount,
    required this.description,
    this.category = 'other',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'created_at': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      category: map['category'] ?? 'other',
      createdAt: map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

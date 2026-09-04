class Category {
  final int id;
  final String name;
  final String? icon;
  final String? color;
  final int sortOrder;

  Category({
    this.id = 0,
    required this.name,
    this.icon,
    this.color,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      icon: map['icon'],
      color: map['color'],
      sortOrder: map['sort_order'] ?? 0,
    );
  }
}

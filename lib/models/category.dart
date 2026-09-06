import 'package:uuid/uuid.dart';

class Category {
  final int? id;
  final String name;
  final String? icon; // Emoji or icon name
  final String? color; // Hex color code e.g. #00D4FF
  final int sortOrder;
  final String syncId;
  final int synced;

  Category({
    this.id,
    required this.name,
    this.icon = '📱',
    this.color = '#00D4FF',
    this.sortOrder = 0,
    String? syncId,
    this.synced = 0,
  }) : syncId = syncId ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'sync_id': syncId,
      'synced': synced,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      icon: map['icon']?.toString() ?? '📱',
      color: map['color']?.toString() ?? '#00D4FF',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? (map['sortOrder'] as num?)?.toInt() ?? 0,
      syncId: map['sync_id']?.toString() ?? map['syncId']?.toString() ?? const Uuid().v4(),
      synced: (map['synced'] as int?) ?? 0,
    );
  }
}

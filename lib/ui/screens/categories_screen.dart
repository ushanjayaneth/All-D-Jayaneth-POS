import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/category.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  static const List<String> _emojiPresets = [
    '📱', '💻', '🎧', '🔌', '🔋', '🛡️', '📦', '🔧', '⌚', '📺', '🎮', '💡'
  ];

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.cyberBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.category, color: AppTheme.neonCyan, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Item Categories',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
              ),
              child: Text(
                '${prov.categories.length} Categories',
                style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () => _showCategoryDialog(context, null),
            ),
          ),
        ],
      ),
      body: prov.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: AppTheme.slateText.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No categories created yet.', style: TextStyle(color: AppTheme.slateText, fontSize: 16)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Category'),
                    onPressed: () => _showCategoryDialog(context, null),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: prov.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final c = prov.categories[i];
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cyberBgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.cyberBgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.icon ?? '📦',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      'ID: ${c.id ?? 0} | Sync: ${c.syncId.substring(0, 8)}...',
                      style: const TextStyle(color: AppTheme.dimText, fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 19, color: AppTheme.slateText),
                          onPressed: () => _showCategoryDialog(context, c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 19, color: AppTheme.redDanger),
                          onPressed: () => _confirmDelete(context, c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCategoryDialog(BuildContext context, Category? category) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    String selectedEmoji = category?.icon ?? '📱';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setCatState) => AlertDialog(
          backgroundColor: AppTheme.cyberBgSecondary,
          title: Row(
            children: [
              Icon(category == null ? Icons.add_circle : Icons.edit, color: AppTheme.neonCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                category == null ? 'Add Category' : 'Edit Category',
                style: const TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppTheme.lightText),
                  decoration: const InputDecoration(labelText: 'Category Name (වර්ගයේ නම) *'),
                ),
                const SizedBox(height: 14),
                const Text('Choose Icon / Emoji:', style: TextStyle(color: AppTheme.slateText, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emojiPresets.map((emoji) {
                    final isSel = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () => setCatState(() => selectedEmoji = emoji),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.neonCyan.withOpacity(0.2) : AppTheme.cyberBgTertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? AppTheme.neonCyan : AppTheme.cardBorder, width: isSel ? 1.5 : 1),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final cat = Category(
                  id: category?.id,
                  name: nameCtrl.text.trim(),
                  icon: selectedEmoji,
                  syncId: category?.syncId ?? const Uuid().v4(),
                  synced: 0,
                );
                final prov = Provider.of<ProductProvider>(context, listen: false);
                await prov.saveCategory(cat);
                Navigator.pop(ctx);
              },
              child: const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cyberBgSecondary,
        title: const Text('Delete Category', style: TextStyle(color: AppTheme.redDanger, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${category.name}"?', style: const TextStyle(color: AppTheme.lightText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redDanger, foregroundColor: Colors.white),
            onPressed: () async {
              if (category.id != null) {
                final prov = Provider.of<ProductProvider>(context, listen: false);
                await prov.deleteCategory(category.id!);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

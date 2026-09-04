import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../data/pos_repository.dart';

class ProductProvider extends ChangeNotifier {
  final PosRepository _repo = PosRepository();

  List<Product> _products = [];
  List<Category> _categories = [];
  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode != null && p.barcode!.contains(_searchQuery));
      final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    _products = await _repo.getProducts();
    _categories = await _repo.getCategories();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Product? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveProduct(Product product) async {
    if (product.id > 0) {
      await _repo.updateProduct(product);
    } else {
      await _repo.insertProduct(product);
    }
    await loadAll();
    return true;
  }

  Future<bool> deleteProduct(int id) async {
    await _repo.deleteProduct(id);
    await loadAll();
    return true;
  }

  Future<bool> saveCategory(Category category) async {
    if (category.id > 0) {
      await _repo.updateCategory(category);
    } else {
      await _repo.insertCategory(category);
    }
    await loadAll();
    return true;
  }

  Future<bool> deleteCategory(int id) async {
    await _repo.deleteCategory(id);
    await loadAll();
    return true;
  }
}

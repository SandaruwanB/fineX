import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/db_helper.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final double budget;
  final double spent;
  final Color color;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
    required this.color,
  });

  ExpenseCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    double? budget,
    double? spent,
    Color? color,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'budget': budget,
      'spent': spent,
      'color': color.toARGB32(),
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      budget: map['budget'] as double,
      spent: map['spent'] as double,
      color: Color(map['color'] as int),
    );
  }
}

class CategoriesNotifier extends StateNotifier<List<ExpenseCategory>> {
  CategoriesNotifier() : super([]) {
    loadCategories();
  }

  static final List<ExpenseCategory> _initialCategories = [
    ExpenseCategory(
      id: '1',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      budget: 800.0,
      spent: 420.50,
      color: const Color(0xFFEF4444), // Red
    ),
    ExpenseCategory(
      id: '2',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      budget: 500.0,
      spent: 310.20,
      color: const Color(0xFFF59E0B), // Amber
    ),
    ExpenseCategory(
      id: '3',
      name: 'Utilities',
      icon: Icons.bolt_rounded,
      budget: 300.0,
      spent: 185.00,
      color: const Color(0xFF3B82F6), // Blue
    ),
    ExpenseCategory(
      id: '4',
      name: 'Entertainment',
      icon: Icons.movie_filter_rounded,
      budget: 400.0,
      spent: 120.40,
      color: const Color(0xFF8B5CF6), // Purple
    ),
  ];

  Future<void> loadCategories() async {
    final list = await DbHelper.getCategories();
    if (list.isEmpty) {
      // First launch, populate defaults
      for (var cat in _initialCategories) {
        await DbHelper.insertCategory(cat.toMap());
      }
      state = _initialCategories;
    } else {
      state = list.map((item) => ExpenseCategory.fromMap(item)).toList();
    }
  }

  Future<void> addCategory(String name, IconData icon, double budget, Color color) async {
    final newCategory = ExpenseCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      budget: budget,
      spent: 0.0,
      color: color,
    );
    
    await DbHelper.insertCategory(newCategory.toMap());
    state = [...state, newCategory];
  }

  Future<void> deleteCategory(String id) async {
    await DbHelper.deleteCategory(id);
    state = state.where((cat) => cat.id != id).toList();
  }

  void refreshFromDatabase(List<ExpenseCategory> loadedCategories) {
    state = loadedCategories;
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<ExpenseCategory>>((ref) {
  return CategoriesNotifier();
});

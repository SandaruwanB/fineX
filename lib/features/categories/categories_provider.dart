import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.budget,
    required this.spent,
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
}

class CategoriesNotifier extends StateNotifier<List<ExpenseCategory>> {
  CategoriesNotifier() : super(_initialCategories);

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

  void addCategory(String name, IconData icon, double budget, Color color) {
    final newCategory = ExpenseCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      budget: budget,
      spent: 0.0,
      color: color,
    );
    state = [...state, newCategory];
  }

  void deleteCategory(String id) {
    state = state.where((cat) => cat.id != id).toList();
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<ExpenseCategory>>((ref) {
  return CategoriesNotifier();
});

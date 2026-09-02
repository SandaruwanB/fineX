import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/db_helper.dart';
import '../../core/theme/app_theme.dart';

class AppCategory {
  final String id;
  final String name;
  final IconData icon;
  final double budget;
  final double spent;
  final Color color;
  final String categoryType; // 'EXPENSE' | 'INCOME' | 'TRANSFER'
  final String? parentId;

  AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
    required this.color,
    required this.categoryType,
    this.parentId,
  });

  AppCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    double? budget,
    double? spent,
    Color? color,
    String? categoryType,
    String? parentId,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      color: color ?? this.color,
      categoryType: categoryType ?? this.categoryType,
      parentId: parentId ?? this.parentId,
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
      'category_type': categoryType,
      'parent_id': parentId,
    };
  }

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      // ignore: non_const_argument_for_const_parameter
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      budget: (map['budget'] as num).toDouble(),
      spent: (map['spent'] as num).toDouble(),
      color: Color(map['color'] as int),
      categoryType: map['category_type'] as String? ?? 'EXPENSE',
      parentId: map['parent_id'] as String?,
    );
  }
}

class CategoriesNotifier extends StateNotifier<List<AppCategory>> {
  CategoriesNotifier() : super([]) {
    loadCategories();
  }

  static final List<AppCategory> _initialCategories = [
    AppCategory(
      id: 'housing',
      name: 'Housing',
      icon: Icons.home_rounded,
      budget: 1500.0,
      spent: 0.0,
      color: AppTheme.dangerRed,
      categoryType: 'EXPENSE',
    ),
    AppCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      budget: 800.0,
      spent: 0.0,
      color: AppTheme.goldAccent,
      categoryType: 'EXPENSE',
    ),
    AppCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      budget: 400.0,
      spent: 0.0,
      color: const Color(0xFF8B5CF6), 
      categoryType: 'EXPENSE',
    ),
    AppCategory(
      id: 'utilities',
      name: 'Utilities',
      icon: Icons.bolt_rounded,
      budget: 300.0,
      spent: 0.0,
      color: AppTheme.neonBlue,
      categoryType: 'EXPENSE',
    ),
    AppCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie_filter_rounded,
      budget: 400.0,
      spent: 0.0,
      color: const Color(0xFFEC4899), // Pink
      categoryType: 'EXPENSE',
    ),

    AppCategory(
      id: 'earned_income',
      name: 'Earned Income',
      icon: Icons.work_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.emeraldGreen,
      categoryType: 'INCOME',
    ),
    AppCategory(
      id: 'salary',
      name: 'Salary',
      icon: Icons.payments_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.emeraldGreen,
      categoryType: 'INCOME',
      parentId: 'earned_income',
    ),
    AppCategory(
      id: 'investment',
      name: 'Investment',
      icon: Icons.trending_up_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.neonBlue,
      categoryType: 'INCOME',
    ),
    AppCategory(
      id: 'dividends',
      name: 'Dividends',
      icon: Icons.account_balance_wallet_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.neonBlue,
      categoryType: 'INCOME',
      parentId: 'investment',
    ),
  ];

  Future<void> loadCategories() async {
    final list = await DbHelper.getCategories();
    if (list.isEmpty) {
      final roots = _initialCategories.where((c) => c.parentId == null).toList();
      final children = _initialCategories.where((c) => c.parentId != null).toList();

      for (var cat in roots) {
        await DbHelper.insertCategory(cat.toMap());
      }
      for (var cat in children) {
        await DbHelper.insertCategory(cat.toMap());
      }
      state = _initialCategories;
    } else {
      state = list.map((item) => AppCategory.fromMap(item)).toList();
    }
  }

  Future<void> addCategory(
    String name,
    IconData icon,
    double budget,
    Color color,
    String categoryType, {
    String? parentId,
  }) async {
    final newCategory = AppCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      budget: budget,
      spent: 0.0,
      color: color,
      categoryType: categoryType,
      parentId: parentId,
    );
    
    await DbHelper.insertCategory(newCategory.toMap());
    state = [...state, newCategory];
  }

  Future<void> deleteCategory(String id) async {
    await DbHelper.deleteCategory(id);
    state = state.where((cat) => cat.id != id).toList();
  }

  void refreshFromDatabase(List<AppCategory> loadedCategories) {
    state = loadedCategories;
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<AppCategory>>((ref) {
  return CategoriesNotifier();
});

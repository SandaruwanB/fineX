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
  final bool? _isEssential; // True: Essential/Mandatory (Need), False: Discretionary/Optional (Want)
  final bool? _isDefault; // True: Default category for quick/fast transactions

  bool get isEssential => _isEssential ?? true;
  bool get isDefault => _isDefault ?? false;

  AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
    required this.color,
    required this.categoryType,
    this.parentId,
    bool isEssential = true,
    bool isDefault = false,
  })  : _isEssential = isEssential,
        _isDefault = isDefault;

  AppCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    double? budget,
    double? spent,
    Color? color,
    String? categoryType,
    String? parentId,
    bool? isEssential,
    bool? isDefault,
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
      isEssential: isEssential ?? this.isEssential,
      isDefault: isDefault ?? this.isDefault,
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
      'is_essential': isEssential ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
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
      isEssential: map['is_essential'] == null || map['is_essential'] == 1 || map['is_essential'] == true,
      isDefault: map['is_default'] == 1 || map['is_default'] == true,
    );
  }
}

class CategoriesNotifier extends StateNotifier<List<AppCategory>> {
  CategoriesNotifier() : super([]) {
    loadCategories();
  }

  static final List<AppCategory> _initialCategories = [
    // Flat Expense Categories
    AppCategory(
      id: 'housing',
      name: 'Housing & Rent',
      icon: Icons.home_rounded,
      budget: 1500.0,
      spent: 0.0,
      color: AppTheme.dangerRed,
      categoryType: 'EXPENSE',
      isEssential: true,
      isDefault: false,
    ),
    AppCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      budget: 800.0,
      spent: 0.0,
      color: AppTheme.goldAccent,
      categoryType: 'EXPENSE',
      isEssential: true,
      isDefault: true,
    ),
    AppCategory(
      id: 'transport',
      name: 'Transport & Fuel',
      icon: Icons.directions_car_rounded,
      budget: 400.0,
      spent: 0.0,
      color: const Color(0xFF8B5CF6),
      categoryType: 'EXPENSE',
      isEssential: true,
      isDefault: false,
    ),
    AppCategory(
      id: 'utilities',
      name: 'Utilities & Bills',
      icon: Icons.bolt_rounded,
      budget: 300.0,
      spent: 0.0,
      color: AppTheme.neonBlue,
      categoryType: 'EXPENSE',
      isEssential: true,
      isDefault: false,
    ),
    AppCategory(
      id: 'healthcare',
      name: 'Healthcare & Medical',
      icon: Icons.medical_services_rounded,
      budget: 250.0,
      spent: 0.0,
      color: const Color(0xFF10B981),
      categoryType: 'EXPENSE',
      isEssential: true,
      isDefault: false,
    ),
    AppCategory(
      id: 'entertainment',
      name: 'Entertainment & Leisure',
      icon: Icons.movie_filter_rounded,
      budget: 400.0,
      spent: 0.0,
      color: const Color(0xFFEC4899),
      categoryType: 'EXPENSE',
      isEssential: false,
      isDefault: false,
    ),
    AppCategory(
      id: 'shopping',
      name: 'Shopping & Luxuries',
      icon: Icons.shopping_bag_rounded,
      budget: 350.0,
      spent: 0.0,
      color: const Color(0xFFF59E0B),
      categoryType: 'EXPENSE',
      isEssential: false,
      isDefault: false,
    ),

    // Flat Income Categories
    AppCategory(
      id: 'salary',
      name: 'Salary',
      icon: Icons.payments_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.emeraldGreen,
      categoryType: 'INCOME',
      isEssential: true,
      isDefault: true,
    ),
    AppCategory(
      id: 'business',
      name: 'Business & Freelance',
      icon: Icons.work_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.wealthGreen,
      categoryType: 'INCOME',
      isEssential: true,
      isDefault: false,
    ),
    AppCategory(
      id: 'investment',
      name: 'Investments & Returns',
      icon: Icons.trending_up_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.neonBlue,
      categoryType: 'INCOME',
      isEssential: true,
      isDefault: false,
    ),
    AppCategory(
      id: 'dividends',
      name: 'Dividends & Yield',
      icon: Icons.account_balance_wallet_rounded,
      budget: 0.0,
      spent: 0.0,
      color: const Color(0xFF6366F1),
      categoryType: 'INCOME',
      isEssential: true,
      isDefault: false,
    ),
    AppCategory(
      id: 'rental',
      name: 'Rental & Side Income',
      icon: Icons.domain_rounded,
      budget: 0.0,
      spent: 0.0,
      color: AppTheme.goldAccent,
      categoryType: 'INCOME',
      isEssential: true,
      isDefault: false,
    ),
  ];

  Future<void> loadCategories() async {
    final list = await DbHelper.getCategories();
    if (list.isEmpty) {
      for (var cat in _initialCategories) {
        await DbHelper.insertCategory(cat.toMap());
      }
      state = _initialCategories;
    } else {
      state = list.map((item) => AppCategory.fromMap(item)).toList();
    }
  }

  Future<void> addCategory({
    required String name,
    required IconData icon,
    required double budget,
    required Color color,
    required String categoryType,
    String? parentId,
    bool isEssential = true,
    bool isDefault = false,
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    // If marked default, clear existing default for same category type
    if (isDefault) {
      await DbHelper.clearDefaultCategory(categoryType);
      state = state.map((c) {
        if (c.categoryType == categoryType && c.isDefault) {
          return c.copyWith(isDefault: false);
        }
        return c;
      }).toList();
    }

    final newCategory = AppCategory(
      id: newId,
      name: name,
      icon: icon,
      budget: budget,
      spent: 0.0,
      color: color,
      categoryType: categoryType,
      parentId: parentId,
      isEssential: isEssential,
      isDefault: isDefault,
    );

    await DbHelper.insertCategory(newCategory.toMap());
    state = [...state, newCategory];
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required IconData icon,
    required double budget,
    required Color color,
    required String categoryType,
    String? parentId,
    required bool isEssential,
    required bool isDefault,
  }) async {
    final existingIndex = state.indexWhere((c) => c.id == id);
    if (existingIndex == -1) return;

    if (isDefault) {
      await DbHelper.clearDefaultCategory(categoryType);
    }

    final updated = state[existingIndex].copyWith(
      name: name,
      icon: icon,
      budget: budget,
      color: color,
      categoryType: categoryType,
      parentId: parentId,
      isEssential: isEssential,
      isDefault: isDefault,
    );

    await DbHelper.updateCategory(id, updated.toMap());

    state = state.map((c) {
      if (c.id == id) {
        return updated;
      }
      if (isDefault && c.categoryType == categoryType && c.isDefault) {
        return c.copyWith(isDefault: false);
      }
      return c;
    }).toList();
  }

  Future<void> setDefaultCategory(String id, String categoryType) async {
    await DbHelper.clearDefaultCategory(categoryType);
    await DbHelper.updateCategory(id, {'is_default': 1});

    state = state.map((c) {
      if (c.id == id) {
        return c.copyWith(isDefault: true);
      }
      if (c.categoryType == categoryType && c.isDefault) {
        return c.copyWith(isDefault: false);
      }
      return c;
    }).toList();
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

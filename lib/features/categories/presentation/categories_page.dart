import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_drawer.dart';
import '../categories_provider.dart';
import '../../../core/services/preference_service.dart';
import '../../../core/constants/currencies.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showAddCategoryBottomSheet(String defaultType) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    
    IconData selectedIcon = Icons.restaurant_rounded;
    Color selectedColor = AppTheme.emeraldGreen;
    String? selectedParentId;

    final icons = [
      Icons.restaurant_rounded,
      Icons.shopping_bag_rounded,
      Icons.bolt_rounded,
      Icons.movie_filter_rounded,
      Icons.directions_car_rounded,
      Icons.flight_takeoff_rounded,
      Icons.medical_services_rounded,
      Icons.school_rounded,
      Icons.payments_rounded,
      Icons.trending_up_rounded,
    ];

    final colors = [
      AppTheme.emeraldGreen,
      AppTheme.neonBlue,
      AppTheme.goldAccent,
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Purple
    ];

    final categories = ref.read(categoriesProvider);
    // Find potential parents (must be roots of matching type)
    final parentOptions = categories.where((c) => c.categoryType == defaultType && c.parentId == null).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161C2A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Custom Category (${defaultType.toLowerCase()})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Rent, Gas, Dividend Yield',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // If EXPENSE, show budget text field
                    if (defaultType == 'EXPENSE') ...[
                      TextField(
                        controller: budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monthly Budget Limit',
                          hintText: 'e.g. 500.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                    // Parent Category dropdown selector
                    if (parentOptions.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        value: selectedParentId,
                        decoration: const InputDecoration(
                          labelText: 'Parent Category (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None (Root Category)'),
                          ),
                          ...parentOptions.map((opt) {
                            return DropdownMenuItem<String?>(
                              value: opt.id,
                              child: Text(opt.name),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedParentId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Choose Icon',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: icons.length,
                        itemBuilder: (context, index) {
                          final icon = icons[index];
                          final isSelected = selectedIcon == icon;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIcon = icon;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? selectedColor : Colors.grey.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? selectedColor : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Theme Color Accent',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final budget = double.tryParse(budgetController.text.trim()) ?? 0.0;
                              if (name.isNotEmpty) {
                                ref.read(categoriesProvider.notifier).addCategory(
                                      name,
                                      selectedIcon,
                                      budget,
                                      selectedColor,
                                      defaultType,
                                      parentId: selectedParentId,
                                    );
                                Navigator.pop(ctx);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Create Category'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MainDrawer(activeRoute: '/categories'),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text('Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategoryTab('EXPENSE'),
            _buildCategoryTab('INCOME'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String type) {
    final categories = ref.watch(categoriesProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';
    final typeCategories = categories.where((cat) => cat.categoryType == type).toList();

    final rootCategories = typeCategories.where((cat) => cat.parentId == null).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Action button
          ElevatedButton.icon(
            onPressed: () => _showAddCategoryBottomSheet(type),
            icon: const Icon(Icons.add_rounded, color: Colors.black),
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'INCOME' ? AppTheme.emeraldGreen : const Color(0xFFF43F5E),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text('Add New ${type.toLowerCase()} Category', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          // Categories Tree hierarchy
          Expanded(
            child: rootCategories.isEmpty
                ? const Center(
                    child: Text(
                      'No categories created yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: rootCategories.length,
                    itemBuilder: (context, index) {
                      final parent = rootCategories[index];
                      // Find subcategories of this parent root
                      final children = typeCategories.where((c) => c.parentId == parent.id).toList();

                      if (children.isEmpty) {
                        return _buildCategoryItemRow(parent, isDark);
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDark ? const Color(0xFF161C2A) : Colors.white,
                        child: ExpansionTile(
                          leading: Icon(parent.icon, color: parent.color),
                          title: Text(
                            parent.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          trailing: type == 'EXPENSE'
                              ? Text(
                                  '$symbol${parent.budget.toStringAsFixed(0)} limit',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                )
                              : null,
                          childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
                          shape: const Border(), // Removes bottom line borders
                          children: children.map((child) {
                            return _buildCategoryItemRow(child, isDark, isChild: true);
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItemRow(AppCategory category, bool isDark, {bool isChild = false}) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';

    return Container(
      margin: EdgeInsets.only(bottom: isChild ? 4 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(category.icon, color: category.color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontWeight: isChild ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (category.categoryType == 'EXPENSE')
            Text(
              '$symbol${category.budget.toStringAsFixed(0)} limit',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed, size: 18),
            onPressed: () {
              ref.read(categoriesProvider.notifier).deleteCategory(category.id);
            },
          ),
        ],
      ),
    );
  }
}

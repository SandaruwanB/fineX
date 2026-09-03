import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../core/widgets/currency_display.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../core/widgets/drawer_blur_wrapper.dart';
import '../categories_provider.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late TabController _tabController;

  static final List<IconData> _availableIcons = [
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.home_rounded,
    Icons.bolt_rounded,
    Icons.directions_car_rounded,
    Icons.local_gas_station_rounded,
    Icons.movie_filter_rounded,
    Icons.sports_esports_rounded,
    Icons.flight_takeoff_rounded,
    Icons.medical_services_rounded,
    Icons.fitness_center_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.payments_rounded,
    Icons.trending_up_rounded,
    Icons.account_balance_rounded,
    Icons.coffee_rounded,
    Icons.pets_rounded,
    Icons.card_giftcard_rounded,
    Icons.receipt_long_rounded,
  ];

  static final List<Color> _availableColors = [
    AppTheme.wealthGreen,
    AppTheme.neonBlue,
    AppTheme.goldAccent,
    const Color(0xFFEF4444), // Crimson Red
    const Color(0xFF8B5CF6), // Royal Purple
    const Color(0xFFEC4899), // Hot Pink
    const Color(0xFF0EA5E9), // Sky Blue
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF6366F1), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCategoryModal({AppCategory? existing, String? defaultType}) {
    final isEditing = existing != null;
    final type = existing?.categoryType ?? defaultType ?? (_tabController.index == 0 ? 'EXPENSE' : 'INCOME');

    final nameController = TextEditingController(text: existing?.name ?? '');
    final budgetController = TextEditingController(text: existing != null && existing.budget > 0 ? existing.budget.toStringAsFixed(0) : '');

    IconData selectedIcon = existing?.icon ?? _availableIcons.first;
    Color selectedColor = existing?.color ?? _availableColors.first;
    String? selectedParentId = existing?.parentId;
    bool isEssential = existing?.isEssential ?? true;
    bool isDefault = existing?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final categories = ref.watch(categoriesProvider);
            final parentOptions = categories
                .where((c) => c.categoryType == type && c.parentId == null && (existing == null || c.id != existing.id))
                .toList();

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101726) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Category' : 'Create ${type == 'INCOME' ? 'Income' : 'Expense'} Category',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: selectedColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(selectedIcon, size: 14, color: selectedColor),
                              const SizedBox(width: 4),
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: selectedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        hintText: type == 'INCOME' ? 'e.g. Salary, Freelance, Dividend' : 'e.g. Groceries, Fuel, Rent',
                        prefixIcon: Icon(selectedIcon, color: selectedColor, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Monthly Budget Limit (For Expenses)
                    if (type == 'EXPENSE') ...[
                      TextField(
                        controller: budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monthly Budget Limit (Optional)',
                          hintText: 'e.g. 15000',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Essential vs Discretionary (Need vs Want)
                      const Text(
                        'Spending Classification',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setModalState(() => isEssential = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isEssential
                                      ? AppTheme.emeraldGreen.withValues(alpha: 0.15)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isEssential
                                        ? AppTheme.emeraldGreen
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: isEssential ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.bolt_rounded, size: 15, color: isEssential ? AppTheme.emeraldGreen : Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Need (Mandatory)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: isEssential ? AppTheme.emeraldGreen : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Bills, Food, Rent, Medical', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setModalState(() => isEssential = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isEssential
                                      ? AppTheme.purpleAccent.withValues(alpha: 0.15)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !isEssential
                                        ? AppTheme.purpleAccent
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: !isEssential ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.theater_comedy_rounded, size: 15, color: !isEssential ? AppTheme.purpleAccent : Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Want (Discretionary)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: !isEssential ? AppTheme.purpleAccent : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('Dining Out, Gaming, Leisure', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Default Category Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: isDefault ? AppTheme.goldAccent : Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Default Quick Category',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                ),
                                Text(
                                  'Pre-select this category automatically during fast transaction logging.',
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isDefault,
                            activeTrackColor: AppTheme.goldAccent,
                            onChanged: (val) => setModalState(() => isDefault = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Parent Category Selector (Optional Subcategory)
                    if (parentOptions.isNotEmpty) ...[
                      const Text(
                        'Parent Category (Optional Nesting)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedParentId,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('None (Root Category)')),
                          ...parentOptions.map((p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Row(
                                  children: [
                                    Icon(p.icon, size: 16, color: p.color),
                                    const SizedBox(width: 8),
                                    Text(p.name),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (val) => setModalState(() => selectedParentId = val),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Icon Picker Grid
                    const Text(
                      'Choose Icon',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _availableIcons.length,
                        itemBuilder: (context, idx) {
                          final icon = _availableIcons[idx];
                          final isSelected = selectedIcon.codePoint == icon.codePoint;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIcon = icon),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? selectedColor.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? selectedColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(icon, color: isSelected ? selectedColor : Colors.grey, size: 20),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Color Palette
                    const Text(
                      'Accent Hue',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _availableColors.map((color) {
                        final isSelected = selectedColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = color),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final budget = double.tryParse(budgetController.text.trim()) ?? 0.0;
                              if (name.isNotEmpty) {
                                if (isEditing) {
                                  ref.read(categoriesProvider.notifier).updateCategory(
                                        id: existing.id,
                                        name: name,
                                        icon: selectedIcon,
                                        budget: budget,
                                        color: selectedColor,
                                        categoryType: type,
                                        parentId: selectedParentId,
                                        isEssential: isEssential,
                                        isDefault: isDefault,
                                      );
                                } else {
                                  ref.read(categoriesProvider.notifier).addCategory(
                                        name: name,
                                        icon: selectedIcon,
                                        budget: budget,
                                        color: selectedColor,
                                        categoryType: type,
                                        parentId: selectedParentId,
                                        isEssential: isEssential,
                                        isDefault: isDefault,
                                      );
                                }
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Category ${isEditing ? "updated" : "created"} successfully.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(isEditing ? 'Save Changes' : 'Create Category'),
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

  void _confirmDeleteCategory(BuildContext context, AppCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete "${category.name}"? Sub-categories and transactions will remain intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).deleteCategory(category.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${category.name} deleted successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider);

    final expenseCategories = categories.where((c) => c.categoryType == 'EXPENSE').toList();
    final incomeCategories = categories.where((c) => c.categoryType == 'INCOME').toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MainDrawer(activeRoute: '/categories'),
        drawerScrimColor: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: 0.45),
        onDrawerChanged: (isOpen) {
          if (_isDrawerOpen != isOpen) {
            setState(() => _isDrawerOpen = isOpen);
          }
        },
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: const Text('Categories & Budgets'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add Category',
              onPressed: () => _showCategoryModal(),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Expenses (${expenseCategories.length})'),
              Tab(text: 'Income (${incomeCategories.length})'),
            ],
          ),
        ),
        body: DrawerBlurWrapper(
          isDrawerOpen: _isDrawerOpen,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryTab('EXPENSE', expenseCategories, isDark),
              _buildCategoryTab('INCOME', incomeCategories, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String type, List<AppCategory> typeCategories, bool isDark) {
    final isExpense = type == 'EXPENSE';
    final rootCategories = typeCategories.where((cat) => cat.parentId == null).toList();

    double totalBudget = 0.0;
    double essentialBudget = 0.0;
    double discretionaryBudget = 0.0;

    for (var cat in typeCategories) {
      totalBudget += cat.budget;
      if (cat.isEssential) {
        essentialBudget += cat.budget;
      } else {
        discretionaryBudget += cat.budget;
      }
    }

    final defaultCategory = typeCategories.firstWhere(
      (c) => c.isDefault,
      orElse: () => typeCategories.isNotEmpty ? typeCategories.first : AppCategory(id: '', name: 'None', icon: Icons.help, spent: 0, budget: 0, color: Colors.grey, categoryType: type),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Top Category Budget Summary Card
            FadeSlideTransition(
              delay: Duration.zero,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D2E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isExpense ? 'TOTAL EXPENSE BUDGET' : 'INCOME CATEGORIES',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isExpense)
                              CurrencyDisplay(
                                amount: totalBudget,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              )
                            else
                              Text(
                                '${typeCategories.length} Streams Active',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCategoryModal(defaultType: type),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Add Category', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpense ? const Color(0xFFF43F5E) : AppTheme.emeraldGreen,
                            foregroundColor: Colors.white,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Quick Insights Pills
                    Row(
                      children: [
                        if (isExpense) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 13, color: AppTheme.emeraldGreen),
                                  const SizedBox(width: 4),
                                  const Text('Needs: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Flexible(
                                    child: CurrencyDisplay(
                                      amount: essentialBudget,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.emeraldGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.purpleAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.theater_comedy_rounded, size: 13, color: AppTheme.purpleAccent),
                                  const SizedBox(width: 4),
                                  const Text('Wants: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Flexible(
                                    child: CurrencyDisplay(
                                      amount: discretionaryBudget,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.purpleAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.goldAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppTheme.goldAccent),
                                  const SizedBox(width: 6),
                                  const Text('Default Log: ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Flexible(
                                    child: Text(
                                      defaultCategory.name,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.goldAccent),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category List
            Expanded(
              child: rootCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, size: 44, color: Colors.grey.withValues(alpha: 0.35)),
                          const SizedBox(height: 12),
                          Text('No ${type.toLowerCase()} categories found', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Tap "+ Add Category" to create your first one.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: rootCategories.length,
                      itemBuilder: (context, index) {
                        final parent = rootCategories[index];
                        final children = typeCategories.where((c) => c.parentId == parent.id).toList();

                        return _buildCompactCategoryTile(parent, children, isDark, type);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCategoryTile(
    AppCategory category,
    List<AppCategory> children,
    bool isDark,
    String type,
  ) {
    final bool isExpense = type == 'EXPENSE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCategoryModal(existing: category, defaultType: type),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: category.color.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Icon(category.icon, color: category.color, size: 20),
                    ),
                    const SizedBox(width: 12),

                    // Category Details (Name & Badges)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (category.isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 10, color: AppTheme.goldAccent),
                                      SizedBox(width: 2),
                                      Text(
                                        'DEFAULT',
                                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppTheme.goldAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (isExpense) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: category.isEssential
                                        ? AppTheme.emeraldGreen.withValues(alpha: 0.12)
                                        : AppTheme.purpleAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category.isEssential ? 'MANDATORY (NEED)' : 'OPTIONAL (WANT)',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: category.isEssential ? AppTheme.emeraldGreen : AppTheme.purpleAccent,
                                    ),
                                  ),
                                ),
                              ],
                              if (children.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• ${children.length} sub-items',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Budget or Limit
                    if (isExpense && category.budget > 0) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CurrencyDisplay(
                            amount: category.budget,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'monthly limit',
                            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Action Menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey[400]),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showCategoryModal(existing: category, defaultType: type);
                        } else if (val == 'default') {
                          ref.read(categoriesProvider.notifier).setDefaultCategory(category.id, type);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${category.name}" set as default quick category.')),
                          );
                        } else if (val == 'delete') {
                          _confirmDeleteCategory(context, category);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        if (!category.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.star_outline_rounded, size: 16, color: AppTheme.goldAccent),
                                SizedBox(width: 8),
                                Text('Set as Default', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRed),
                              SizedBox(width: 8),
                              Text('Delete Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.dangerRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Sub-categories list if any
                if (children.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  ...children.map((child) => Padding(
                        padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
                        child: Row(
                          children: [
                            Icon(child.icon, size: 14, color: child.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                child.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (child.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('DEFAULT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.goldAccent)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              color: Colors.grey[400],
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => _showCategoryModal(existing: child, defaultType: type),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

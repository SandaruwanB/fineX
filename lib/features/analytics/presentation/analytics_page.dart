import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/currency_display.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../core/widgets/drawer_blur_wrapper.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../categories/categories_provider.dart';
import '../../transactions/transactions_provider.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _selectedTab = 'EXPENSE'; // 'EXPENSE' | 'INCOME'
  int _touchedIndex = -1;
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final periodTransactions = transactions.where((tx) => tx.timestamp.isAfter(thirtyDaysAgo)).toList();

    double totalInflow = 0.0;
    double totalOutflow = 0.0;
    
    final Map<String, double> categorySums = {};

    for (var tx in periodTransactions) {
      if (tx.flowDirection == 'INFLOW') {
        totalInflow += tx.amount;
      } else if (tx.flowDirection == 'OUTFLOW') {
        totalOutflow += tx.amount;
      }

      if (tx.flowDirection == _selectedTab) {
        if (tx.splits.isEmpty) {
          final catId = tx.categoryId ?? '';
          categorySums[catId] = (categorySums[catId] ?? 0.0) + tx.amount;
        } else {
          for (var split in tx.splits) {
            final catId = split.categoryId;
            categorySums[catId] = (categorySums[catId] ?? 0.0) + split.amount;
          }
        }
      }
    }

    final double activeTotal = _selectedTab == 'EXPENSE' ? totalOutflow : totalInflow;

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
        drawer: const MainDrawer(activeRoute: '/analytics'),
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
          title: const Text('Analytics'),
        ),
      body: DrawerBlurWrapper(
        isDrawerOpen: _isDrawerOpen,
        child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideTransition(
                  delay: Duration.zero,
                  child: _buildCashComparisonCard(isDark, totalInflow, totalOutflow),
                ),
                const SizedBox(height: 32),

                FadeSlideTransition(
                  delay: const Duration(milliseconds: 70),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTabsSelector(isDark),
                      const SizedBox(height: 24),
                      if (activeTotal <= 0)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 64.0),
                            child: Text(
                              'No transactions recorded for this period.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          '${_selectedTab == 'EXPENSE' ? 'Expense' : 'Income'} Share Breakdown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        _buildDonutChart(categorySums, categories, activeTotal),
                        const SizedBox(height: 32),
                        _buildDonutLegend(categorySums, categories, activeTotal, isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ));
  }

  Widget _buildCashComparisonCard(bool isDark, double inflow, double outflow) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C2A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAST 30 DAYS PERFORMANCE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Inflow', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    CurrencyDisplay(
                      amount: inflow,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.emeraldGreen),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 44, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Outflow', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    CurrencyDisplay(
                      amount: outflow,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.dangerRed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSelector(bool isDark) {
    final activeColor = _selectedTab == 'EXPENSE' ? const Color(0xFFF43F5E) : AppTheme.emeraldGreen;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'EXPENSE'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 'EXPENSE' ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Expenses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 'EXPENSE' ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'INCOME'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 'INCOME' ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Income',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 'INCOME' ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, double> categorySums, List<AppCategory> categories, double total) {
    final List<PieChartSectionData> sections = [];
    int idx = 0;

    categorySums.forEach((catId, amount) {
      final cat = categories.firstWhere(
        (c) => c.id == catId,
        orElse: () => AppCategory(
          id: '',
          name: 'Uncategorized',
          icon: Icons.help_outline_rounded,
          spent: 0.0,
          budget: 0.0,
          color: Colors.grey,
          categoryType: 'EXPENSE',
        ),
      );

      final isTouched = touchedSectionIdx(idx);
      final double radius = isTouched ? 50.0 : 40.0;
      final percentage = (amount / total) * 100;

      sections.add(PieChartSectionData(
        color: cat.color,
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ));

      idx++;
    });

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 4,
          centerSpaceRadius: 50,
          sections: sections,
        ),
      ),
    );
  }

  Widget _buildDonutLegend(
    Map<String, double> categorySums,
    List<AppCategory> categories,
    double total,
    bool isDark,
  ) {
    return Column(
      children: categorySums.entries.map((entry) {
        final catId = entry.key;
        final amount = entry.value;
        final percentage = (amount / total) * 100;

        final cat = categories.firstWhere(
          (c) => c.id == catId,
          orElse: () => AppCategory(
            id: '',
            name: 'Uncategorized',
            icon: Icons.help_outline_rounded,
            spent: 0.0,
            budget: 0.0,
            color: Colors.grey,
            categoryType: 'EXPENSE',
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161C2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(cat.icon, color: cat.color, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              CurrencyDisplay(
                amount: amount,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool touchedSectionIdx(int idx) {
    return idx == _touchedIndex;
  }
}

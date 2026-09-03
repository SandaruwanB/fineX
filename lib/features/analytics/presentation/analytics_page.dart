import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/currency_display.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../core/widgets/drawer_blur_wrapper.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../categories/categories_provider.dart';
import '../../transactions/transaction_model.dart';
import '../../transactions/transactions_provider.dart';

enum AnalyticsHorizon {
  past30Days,
  thisMonth,
  past90Days,
  pastYear,
  allTime,
}

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  AnalyticsHorizon _selectedHorizon = AnalyticsHorizon.past30Days;
  String _selectedFlow = 'EXPENSE'; // 'EXPENSE' | 'INCOME'
  String _chartViewType = 'DONUT'; // 'DONUT' | 'TREND'
  int _touchedDonutIndex = -1;
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);

    final now = DateTime.now();

    // 1. Filter Transactions by Horizon
    final List<Transaction> periodTransactions = transactions.where((tx) {
      switch (_selectedHorizon) {
        case AnalyticsHorizon.past30Days:
          return tx.timestamp.isAfter(now.subtract(const Duration(days: 30)));
        case AnalyticsHorizon.thisMonth:
          return tx.timestamp.year == now.year && tx.timestamp.month == now.month;
        case AnalyticsHorizon.past90Days:
          return tx.timestamp.isAfter(now.subtract(const Duration(days: 90)));
        case AnalyticsHorizon.pastYear:
          return tx.timestamp.isAfter(now.subtract(const Duration(days: 365)));
        case AnalyticsHorizon.allTime:
          return true;
      }
    }).toList();

    // 2. Aggregate Cash Flow Figures
    double totalInflow = 0.0;
    double totalOutflow = 0.0;
    double essentialOutflow = 0.0;
    double discretionaryOutflow = 0.0;

    final Map<String, double> categorySums = {};

    for (var tx in periodTransactions) {
      if (tx.flowDirection == 'INFLOW') {
        totalInflow += tx.amount;
      } else if (tx.flowDirection == 'OUTFLOW') {
        totalOutflow += tx.amount;

        // Categorize Essential vs Discretionary
        if (tx.splits.isEmpty) {
          final cat = categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => AppCategory(id: '', name: 'Uncategorized', icon: Icons.help, spent: 0, budget: 0, color: Colors.grey, categoryType: 'EXPENSE'));
          if (cat.isEssential) {
            essentialOutflow += tx.amount;
          } else {
            discretionaryOutflow += tx.amount;
          }
        } else {
          for (var split in tx.splits) {
            final cat = categories.firstWhere((c) => c.id == split.categoryId, orElse: () => AppCategory(id: '', name: 'Uncategorized', icon: Icons.help, spent: 0, budget: 0, color: Colors.grey, categoryType: 'EXPENSE'));
            if (cat.isEssential) {
              essentialOutflow += split.amount;
            } else {
              discretionaryOutflow += split.amount;
            }
          }
        }
      }

      // Aggregate Category breakdown for active flow
      if (tx.flowDirection == _selectedFlow) {
        if (tx.splits.isEmpty) {
          final catId = tx.categoryId ?? 'uncategorized';
          categorySums[catId] = (categorySums[catId] ?? 0.0) + tx.amount;
        } else {
          for (var split in tx.splits) {
            final catId = split.categoryId;
            categorySums[catId] = (categorySums[catId] ?? 0.0) + split.amount;
          }
        }
      }
    }

    final double netCashFlow = totalInflow - totalOutflow;
    final double savingsRate = totalInflow > 0 ? ((totalInflow - totalOutflow) / totalInflow) * 100 : 0.0;
    final double activeTotal = _selectedFlow == 'EXPENSE' ? totalOutflow : totalInflow;

    // Daily Average Burn
    int daysCount = 30;
    if (_selectedHorizon == AnalyticsHorizon.past90Days) daysCount = 90;
    if (_selectedHorizon == AnalyticsHorizon.pastYear) daysCount = 365;
    if (_selectedHorizon == AnalyticsHorizon.thisMonth) daysCount = now.day;
    final double avgDailyBurn = daysCount > 0 ? (totalOutflow / daysCount) : 0.0;

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
          title: const Text('Cash Flow Intelligence'),
          actions: [
            IconButton(
              icon: Icon(_chartViewType == 'DONUT' ? Icons.bar_chart_rounded : Icons.pie_chart_outline_rounded),
              tooltip: _chartViewType == 'DONUT' ? 'Switch to Trend Bar Chart' : 'Switch to Donut Breakdown',
              onPressed: () {
                setState(() {
                  _chartViewType = _chartViewType == 'DONUT' ? 'TREND' : 'DONUT';
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: DrawerBlurWrapper(
          isDrawerOpen: _isDrawerOpen,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horizon Filter Pills
                    _buildHorizonSelector(isDark),
                    const SizedBox(height: 16),

                    // Net Cash Flow & Savings Rate Banner
                    FadeSlideTransition(
                      delay: Duration.zero,
                      child: _buildNetCashFlowCard(isDark, netCashFlow, savingsRate, totalInflow, totalOutflow, avgDailyBurn),
                    ),
                    const SizedBox(height: 16),

                    // 50/30/20 Budgeting Intelligence (For Expenses)
                    if (totalInflow > 0 || totalOutflow > 0)
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 60),
                        child: _buildBudgetRatioCard(isDark, totalInflow, essentialOutflow, discretionaryOutflow, netCashFlow),
                      ),
                    const SizedBox(height: 20),

                    // Flow Toggle (Expense vs Income)
                    _buildFlowToggle(isDark),
                    const SizedBox(height: 18),

                    // Visual Chart Section
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131D2E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                                Text(
                                  '${_selectedFlow == 'EXPENSE' ? 'EXPENSE' : 'INCOME'} ALLOCATION',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Colors.grey,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (_selectedFlow == 'EXPENSE' ? AppTheme.dangerRed : AppTheme.emeraldGreen).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _chartViewType == 'DONUT' ? 'Ring Breakdown' : 'Cash Trend',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedFlow == 'EXPENSE' ? AppTheme.dangerRed : AppTheme.emeraldGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            CurrencyDisplay(
                              amount: activeTotal,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 16),

                            if (activeTotal <= 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(
                                  child: Text(
                                    'No transactions recorded in this period.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                              )
                            else if (_chartViewType == 'DONUT')
                              _buildDonutChart(categorySums, categories, activeTotal, isDark)
                            else
                              _buildTrendBarChart(periodTransactions, isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Itemized Category Share Drilldown
                    if (categorySums.isNotEmpty && activeTotal > 0) ...[
                      const Text(
                        'Category Share & Drilldown',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryShareList(categorySums, categories, activeTotal, isDark),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Horizon Filter Selector ---

  Widget _buildHorizonSelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildHorizonChip('30 Days', AnalyticsHorizon.past30Days, isDark),
          _buildHorizonChip('This Month', AnalyticsHorizon.thisMonth, isDark),
          _buildHorizonChip('90 Days', AnalyticsHorizon.past90Days, isDark),
          _buildHorizonChip('Past 1 Year', AnalyticsHorizon.pastYear, isDark),
          _buildHorizonChip('All Time', AnalyticsHorizon.allTime, isDark),
        ],
      ),
    );
  }

  Widget _buildHorizonChip(String label, AnalyticsHorizon horizon, bool isDark) {
    final isSelected = _selectedHorizon == horizon;
    return GestureDetector(
      onTap: () => setState(() => _selectedHorizon = horizon),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.emeraldGreen
              : (isDark ? const Color(0xFF131D2E) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.emeraldGreen : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  // --- 2. Net Cash Flow & Savings Rate Executive Card ---

  Widget _buildNetCashFlowCard(
    bool isDark,
    double netFlow,
    double savingsRate,
    double inflow,
    double outflow,
    double avgDailyBurn,
  ) {
    final isPositive = netFlow >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPositive
              ? AppTheme.emeraldGreen.withValues(alpha: 0.3)
              : AppTheme.dangerRed.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppTheme.emeraldGreen : AppTheme.dangerRed).withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NET CASH SURPLUS / DEFICIT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.emeraldGreen : AppTheme.dangerRed).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isPositive ? "+" : ""}${savingsRate.toStringAsFixed(1)}% Saved',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isPositive ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          CurrencyDisplay(
            amount: netFlow,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isPositive ? AppTheme.emeraldGreen : AppTheme.dangerRed,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Dual Stream Metrics (Inflow vs Outflow vs Daily Burn)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward_rounded, size: 12, color: AppTheme.emeraldGreen),
                        const SizedBox(width: 3),
                        const Text('Total Inflow', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    CurrencyDisplay(
                      amount: inflow,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: AppTheme.emeraldGreen),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 12, color: AppTheme.dangerRed),
                        const SizedBox(width: 3),
                        const Text('Total Outflow', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    CurrencyDisplay(
                      amount: outflow,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: AppTheme.dangerRed),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 12, color: AppTheme.goldAccent),
                        const SizedBox(width: 3),
                        const Text('Daily Burn', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    CurrencyDisplay(
                      amount: avgDailyBurn,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
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

  // --- 3. 50/30/20 Wealth Intelligence Rule Card ---

  Widget _buildBudgetRatioCard(
    bool isDark,
    double inflow,
    double needs,
    double wants,
    double savings,
  ) {
    final double totalExpenses = needs + wants;
    final double baseIncome = inflow > 0 ? inflow : totalExpenses;

    final double needsPercent = baseIncome > 0 ? ((needs / baseIncome) * 100).clamp(0, 100) : 0.0;
    final double wantsPercent = baseIncome > 0 ? ((wants / baseIncome) * 100).clamp(0, 100) : 0.0;
    final double savingsPercent = baseIncome > 0 ? ((savings.clamp(0, double.infinity) / baseIncome) * 100).clamp(0, 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '50/30/20 BUDGET INTELLIGENCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.electricIndigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Recommended Model',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppTheme.electricIndigo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Multi-color Segmented Ratio Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (needsPercent > 0)
                    Flexible(
                      flex: (needsPercent * 10).round(),
                      child: Container(color: AppTheme.emeraldGreen),
                    ),
                  if (wantsPercent > 0)
                    Flexible(
                      flex: (wantsPercent * 10).round(),
                      child: Container(color: AppTheme.purpleAccent),
                    ),
                  if (savingsPercent > 0)
                    Flexible(
                      flex: (savingsPercent * 10).round(),
                      child: Container(color: AppTheme.neonBlue),
                    ),
                  if (needsPercent == 0 && wantsPercent == 0 && savingsPercent == 0)
                    Expanded(child: Container(color: Colors.grey.withValues(alpha: 0.2))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRatioMetricItem('Needs (Mandatory)', needs, needsPercent, AppTheme.emeraldGreen, 'Target ~50%'),
              _buildRatioMetricItem('Wants (Discretionary)', wants, wantsPercent, AppTheme.purpleAccent, 'Target ~30%'),
              _buildRatioMetricItem('Savings (Retained)', savings > 0 ? savings : 0.0, savingsPercent, AppTheme.neonBlue, 'Target ~20%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioMetricItem(String title, double amount, double percent, Color color, String target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text('${percent.toStringAsFixed(0)}% ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
            CurrencyDisplay(amount: amount, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
        Text(target, style: TextStyle(fontSize: 8.5, color: Colors.grey.shade500)),
      ],
    );
  }

  // --- 4. Flow Direction Toggle ---

  Widget _buildFlowToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFlow = 'EXPENSE'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedFlow == 'EXPENSE' ? AppTheme.dangerRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Expenses (Outflow)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: _selectedFlow == 'EXPENSE' ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFlow = 'INFLOW'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedFlow == 'INFLOW' ? AppTheme.emeraldGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Income (Inflow)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: _selectedFlow == 'INFLOW' ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Donut Chart Component ---

  Widget _buildDonutChart(
    Map<String, double> categorySums,
    List<AppCategory> categories,
    double total,
    bool isDark,
  ) {
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
          categoryType: _selectedFlow,
        ),
      );

      final isTouched = idx == _touchedDonutIndex;
      final double radius = isTouched ? 36.0 : 28.0;
      final percentage = (amount / total) * 100;

      sections.add(PieChartSectionData(
        color: cat.color,
        value: amount,
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
      ));

      idx++;
    });

    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedDonutIndex = -1;
                      return;
                    }
                    _touchedDonutIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 54,
              sections: sections,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${categorySums.length}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const Text(
                'Categories',
                style: TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. Trend Bar Chart Component ---

  Widget _buildTrendBarChart(List<Transaction> periodTransactions, bool isDark) {
    final now = DateTime.now();
    // Group last 7 days or weeks
    final List<double> inflowBars = List.filled(7, 0.0);
    final List<double> outflowBars = List.filled(7, 0.0);
    final List<String> dayLabels = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E').format(date));
    }

    for (var tx in periodTransactions) {
      final diffDays = now.difference(tx.timestamp).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        final slot = 6 - diffDays;
        if (tx.flowDirection == 'INFLOW') {
          inflowBars[slot] += tx.amount;
        } else if (tx.flowDirection == 'OUTFLOW') {
          outflowBars[slot] += tx.amount;
        }
      }
    }

    double maxY = 100.0;
    for (int i = 0; i < 7; i++) {
      if (inflowBars[i] > maxY) maxY = inflowBars[i];
      if (outflowBars[i] > maxY) maxY = outflowBars[i];
    }
    maxY *= 1.2;

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isCredit = rodIndex == 0;
                return BarTooltipItem(
                  '${isCredit ? "Inflow" : "Outflow"}\n${rod.toY.toStringAsFixed(0)}',
                  TextStyle(color: isCredit ? AppTheme.emeraldGreen : AppTheme.dangerRed, fontWeight: FontWeight.w800, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < dayLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(dayLabels[idx], style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: inflowBars[i],
                  color: AppTheme.emeraldGreen,
                  width: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: outflowBars[i],
                  color: AppTheme.dangerRed,
                  width: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- 7. Itemized Category Share Drilldown List ---

  Widget _buildCategoryShareList(
    Map<String, double> categorySums,
    List<AppCategory> categories,
    double total,
    bool isDark,
  ) {
    // Sort categories by expenditure descending
    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((entry) {
        final catId = entry.key;
        final amount = entry.value;
        final percentage = (amount / total) * 100;

        final cat = categories.firstWhere(
          (c) => c.id == catId,
          orElse: () => AppCategory(
            id: '',
            name: 'Uncategorized',
            icon: Icons.category_outlined,
            spent: 0.0,
            budget: 0.0,
            color: Colors.grey,
            categoryType: _selectedFlow,
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cat.color.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 17),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                cat.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedFlow == 'EXPENSE') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: cat.isEssential
                                      ? AppTheme.emeraldGreen.withValues(alpha: 0.12)
                                      : AppTheme.purpleAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cat.isEssential ? 'NEED' : 'WANT',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    color: cat.isEssential ? AppTheme.emeraldGreen : AppTheme.purpleAccent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${percentage.toStringAsFixed(1)}% of total ${_selectedFlow == "EXPENSE" ? "spend" : "income"}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  CurrencyDisplay(
                    amount: amount,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: _selectedFlow == 'EXPENSE'
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : AppTheme.emeraldGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Relative proportion bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

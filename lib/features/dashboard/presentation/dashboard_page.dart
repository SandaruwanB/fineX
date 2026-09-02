import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/preference_service.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../core/widgets/currency_display.dart';
import '../../accounts/accounts_provider.dart';
import '../../categories/categories_provider.dart';
import '../../transactions/transactions_provider.dart';
import '../../transactions/transaction_model.dart';
import '../../transactions/presentation/add_transaction_modal.dart';
import '../../transactions/presentation/fast_log_modal.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Offset _fabPosition = const Offset(-1, -1);
  bool _isMenuOpen = false;
  DateTime? _lastBackPressTime;

  void _openFastLog({String flow = 'OUTFLOW'}) {
    HapticFeedback.lightImpact();
    setState(() => _isMenuOpen = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FastLogModal(initialFlow: flow),
    );
  }

  void _openDetailedEntry() {
    HapticFeedback.lightImpact();
    setState(() => _isMenuOpen = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddTransactionModal(),
    );
  }

  void _showTransactionDetail(Transaction tx, AppCategory cat, Account acc, bool isDark) {
    final baseCurrency = ref.read(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101726) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(24),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description ?? cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tx.timestamp.toIso8601String().substring(0, 16).replaceAll('T', ' ')} • ${acc.name}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${tx.flowDirection == 'INFLOW' ? '+' : '-'}$symbol${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: tx.flowDirection == 'INFLOW' ? AppTheme.emeraldGreen : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Metadata items
            _buildMetaRow('Flow Type', tx.flowDirection, isDark),
            _buildMetaRow('Category', cat.name, isDark),
            _buildMetaRow('Account', acc.name, isDark),
            _buildMetaRow('Tax Status', tx.isTaxDeductible ? 'Tax Deductible' : 'Standard Expense', isDark),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRed),
                    label: const Text('Delete Record', style: TextStyle(color: AppTheme.dangerRed)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.dangerRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wealthGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;

    // Financial Metrics
    double totalInflow = 0.0;
    double totalOutflow = 0.0;
    for (var tx in transactions) {
      if (tx.flowDirection == 'INFLOW') {
        totalInflow += tx.amount;
      } else if (tx.flowDirection == 'OUTFLOW') {
        totalOutflow += tx.amount;
      }
    }
    final netCashFlow = totalInflow - totalOutflow;
    final savingsRate = totalInflow > 0 ? ((totalInflow - totalOutflow) / totalInflow * 100) : 0.0;

    double liquidTotal = 0.0;
    double liabilityTotal = 0.0;
    for (var acc in accounts) {
      if (acc.type == 'credit') {
        liabilityTotal += acc.balance.abs();
      } else {
        liquidTotal += acc.balance;
      }
    }
    final totalNetWorth = liquidTotal - liabilityTotal;

    if (_fabPosition == const Offset(-1, -1)) {
      _fabPosition = Offset(
        (size.width - 72).clamp(16.0, 1000.0),
        (size.height - 240).clamp(100.0, 2000.0),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isMenuOpen) {
          setState(() => _isMenuOpen = false);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit fineX'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
      drawer: const MainDrawer(activeRoute: '/dashboard'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Center(
              child: InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161C2A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'fineX',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppTheme.lightPrimary,
              ),
            ),
            const SizedBox(width: 8)
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161C2A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              baseCurrency,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.emeraldGreen : AppTheme.lightPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wealth Hub Hero: Net Worth with Integrated Sparkline Curve
                    _buildWealthHeroUnit(isDark, totalNetWorth, liquidTotal, liabilityTotal),
                    const SizedBox(height: 20),

                    // Executive Summary Dual Cards (Liquidity + Cash Flow)
                    _buildExecutiveMetricsRow(isDark, liquidTotal, liabilityTotal, totalInflow, totalOutflow, netCashFlow, savingsRate),
                    const SizedBox(height: 28),

                    // Accounts Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PORTFOLIO ACCOUNTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go('/accounts'),
                          child: const Text(
                            'Manage Deck →',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.emeraldGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAccountsCarousel(accounts, isDark),
                    const SizedBox(height: 28),

                    // Enterprise Feed Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ENTERPRISE ACTIVITY FEED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go('/analytics'),
                          child: const Text(
                            'Full Ledger',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF101726) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 36, color: Colors.grey.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              const Text('No transactions recorded yet', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('Tap the + button below for rapid 3-second logging', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...transactions.take(8).map((tx) {
                        final cat = categories.firstWhere(
                          (c) => c.id == tx.categoryId,
                          orElse: () => AppCategory(
                            id: '',
                            name: tx.flowDirection == 'TRANSFER' ? 'Transfer' : 'General',
                            icon: tx.flowDirection == 'TRANSFER' ? Icons.swap_horiz_rounded : Icons.payments_rounded,
                            spent: 0.0,
                            budget: 0.0,
                            color: AppTheme.emeraldGreen,
                            categoryType: 'EXPENSE',
                          ),
                        );

                        final acc = accounts.firstWhere(
                          (a) => a.id == tx.accountId,
                          orElse: () => Account(
                            id: '',
                            name: 'Primary Vault',
                            balance: 0.0,
                            type: 'checking',
                            color: Colors.grey,
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () => _showTransactionDetail(tx, cat, acc, isDark),
                            borderRadius: BorderRadius.circular(16),
                            child: _buildTransactionActivityRow(context, tx, cat, acc, isDark),
                          ),
                        );
                      }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Speed-Dial Modal Backdrop
          if (_isMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isMenuOpen = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: Colors.black.withValues(alpha: 0.6),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Speed-Dial FAB Menu
          ..._buildDraggableFabMenu(context, isDark, size),
        ],
      ),
    ));
  }

  // --- Hero Unit with Integrated Sparkline ---
  Widget _buildWealthHeroUnit(bool isDark, double netWorth, double liquid, double liability) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.obsidianBlackCard : AppTheme.platinumGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Sparkline Graphic
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 90,
            child: Opacity(
              opacity: isDark ? 0.25 : 0.15,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3.0),
                        FlSpot(1, 4.2),
                        FlSpot(2, 3.8),
                        FlSpot(3, 6.0),
                        FlSpot(4, 5.5),
                        FlSpot(5, 7.8),
                        FlSpot(6, 8.5),
                      ],
                      isCurved: true,
                      color: AppTheme.emeraldGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.emeraldGreen.withValues(alpha: 0.4),
                            AppTheme.emeraldGreen.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL NET WORTH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.wealthGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up_rounded, color: AppTheme.emeraldGreen, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '+4.8% this month',
                            style: TextStyle(
                              color: AppTheme.emeraldGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CurrencyDisplay(
                  amount: netWorth,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Liquid vs Liabilities Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppTheme.emeraldGreen),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Liquid Assets', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              CurrencyDisplay(
                                amount: liquid,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.credit_card_rounded, size: 14, color: AppTheme.dangerRed),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Liabilities', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              CurrencyDisplay(
                                amount: liability,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.dangerRed),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Executive Metrics (Liquidity & Cash Flow Dual Row) ---
  Widget _buildExecutiveMetricsRow(
    bool isDark,
    double liquid,
    double liability,
    double inflow,
    double outflow,
    double net,
    double savingsRate,
  ) {
    final rateColor = net >= 0 ? AppTheme.emeraldGreen : AppTheme.dangerRed;

    return Row(
      children: [
        // Cash Flow Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101726) : Colors.white,
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
                      'NET CASH FLOW',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8),
                    ),
                    Text(
                      '${savingsRate.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: rateColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CurrencyDisplay(
                  amount: net,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: net >= 0 ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 12, color: AppTheme.emeraldGreen),
                    Text(inflow.toStringAsFixed(0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_upward_rounded, size: 12, color: AppTheme.dangerRed),
                    Text(outflow.toStringAsFixed(0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Total Liquidity Ratio Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101726) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIQUIDITY RATIO',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8),
                    ),
                    Icon(Icons.shield_outlined, size: 14, color: AppTheme.emeraldGreen),
                  ],
                ),
                const SizedBox(height: 8),
                CurrencyDisplay(
                  amount: liquid,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (liquid + liability) > 0 ? (liquid / (liquid + liability)).clamp(0.0, 1.0) : 1.0,
                    backgroundColor: AppTheme.dangerRed.withValues(alpha: 0.3),
                    color: AppTheme.emeraldGreen,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Accounts Carousel ---
  Widget _buildAccountsCarousel(List<Account> accounts, bool isDark) {
    if (accounts.isEmpty) return const SizedBox();
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        itemBuilder: (context, idx) {
          final acc = accounts[idx];
          return Container(
            width: 165,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101726) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: acc.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        acc.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.type.toUpperCase(),
                      style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    CurrencyDisplay(
                      amount: acc.balance,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: acc.type == 'credit' ? AppTheme.dangerRed : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Enterprise Transaction Row ---
  Widget _buildTransactionActivityRow(
    BuildContext context,
    Transaction tx,
    AppCategory cat,
    Account acc,
    bool isDark,
  ) {
    final bool isInflow = tx.flowDirection == 'INFLOW';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101726) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.icon, color: cat.color, size: 18),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      acc.name,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    if (tx.isTaxDeductible) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.wealthGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TAX',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.emeraldGreen),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isInflow ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isInflow ? AppTheme.emeraldGreen : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.timestamp.toIso8601String().substring(0, 10),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Speed-Dial Menu ---
  List<Widget> _buildDraggableFabMenu(BuildContext context, bool isDark, Size screenSize) {
    if (screenSize.width <= 0 || screenSize.height <= 0) return const [];
    if (_fabPosition == const Offset(-1, -1)) {
      _fabPosition = Offset(
        (screenSize.width - 72).clamp(16.0, 1000.0),
        (screenSize.height - 240).clamp(100.0, 2000.0),
      );
    }

    final showUpward = _fabPosition.dy > screenSize.height / 2;

    final items = [
      _FabItem(
        icon: Icons.flash_on_rounded,
        label: 'Fast 3s Log',
        color: AppTheme.wealthGreen,
        onTap: () => _openFastLog(flow: 'OUTFLOW'),
      ),
      _FabItem(
        icon: Icons.add_circle_outline_rounded,
        label: '+ Income',
        color: AppTheme.emeraldGreen,
        onTap: () => _openFastLog(flow: 'INFLOW'),
      ),
      _FabItem(
        icon: Icons.receipt_long_rounded,
        label: 'Tax Filing Hub',
        color: AppTheme.neonBlue,
        onTap: () {
          setState(() => _isMenuOpen = false);
          context.go('/tax');
        },
      ),
      _FabItem(
        icon: Icons.edit_calendar_rounded,
        label: 'Detailed Entry',
        color: AppTheme.electricIndigo,
        onTap: _openDetailedEntry,
      ),
    ];

    List<Widget> stackChildren = [];

    if (_isMenuOpen) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final double topOffset = showUpward
            ? (_fabPosition.dy - 50 - (i * 50)).clamp(60.0, screenSize.height - 100)
            : (_fabPosition.dy + 68 + (i * 50)).clamp(60.0, screenSize.height - 100);

        final double rightOffset = (screenSize.width - _fabPosition.dx - 56).clamp(8.0, screenSize.width - 80);

        stackChildren.add(
          Positioned(
            right: rightOffset,
            top: topOffset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101726) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  heroTag: 'fab-${item.label}',
                  onPressed: item.onTap,
                  backgroundColor: item.color,
                  foregroundColor: Colors.white,
                  child: Icon(item.icon, size: 18),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      }
    }

    stackChildren.add(
      Positioned(
        left: _fabPosition.dx.clamp(16.0, (screenSize.width - 72).clamp(16.0, 1000.0)),
        top: _fabPosition.dy.clamp(kToolbarHeight + 16, (screenSize.height - 90).clamp(60.0, 2000.0)),
        child: GestureDetector(
          onPanUpdate: (details) {
            _updateFabPosition(details.delta, screenSize);
          },
          onTap: () {
            // Direct Fast-Log on tap for 0-friction speed
            _openFastLog(flow: 'OUTFLOW');
          },
          onLongPress: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _isMenuOpen = !_isMenuOpen;
            });
          },
          child: FloatingActionButton(
            heroTag: 'main-fab',
            onPressed: null,
            backgroundColor: AppTheme.wealthGreen,
            foregroundColor: Colors.white,
            elevation: 4,
            child: AnimatedRotation(
              turns: _isMenuOpen ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add_rounded, size: 30),
            ),
          ),
        ),
      ),
    );

    return stackChildren;
  }

  void _updateFabPosition(Offset delta, Size screenSize) {
    setState(() {
      double newX = _fabPosition.dx + delta.dx;
      double newY = _fabPosition.dy + delta.dy;

      const double padding = 16.0;
      final double minX = padding;
      final double maxX = screenSize.width - 56.0 - padding;

      final double minY = kToolbarHeight + padding;
      final double maxY = screenSize.height - 80.0 - padding;

      _fabPosition = Offset(
        newX.clamp(minX, maxX),
        newY.clamp(minY, maxY),
      );
    });
  }
}

class _FabItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _FabItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

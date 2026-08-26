import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/currency_display.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../accounts/accounts_provider.dart';
import '../../categories/categories_provider.dart';
import '../../transactions/presentation/add_transaction_modal.dart';
import '../../transactions/transactions_provider.dart';
import '../../../core/services/preference_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isMenuOpen = false;
  Offset _fabPosition = const Offset(-1, -1);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;

    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);

    final isPrivacyEnabled = ref.watch(privacyModeProvider);

    // Dynamic calculations for Net Cash Flow card
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

    // Accounts totals
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
      _fabPosition = Offset(size.width - 72, size.height - 200);
    }

    return Scaffold(
      drawer: const MainDrawer(activeRoute: '/dashboard'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('fineX'),
        actions: [
          // Privacy Mode Switcher (eye icon)
          IconButton(
            icon: Icon(
              isPrivacyEnabled ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isPrivacyEnabled ? AppTheme.emeraldGreen : null,
            ),
            onPressed: () {
              ref.read(privacyModeProvider.notifier).togglePrivacyMode();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable layout
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Net Worth Card (with privacy support)
                    _buildNetWorthCard(isDark, totalNetWorth, liquidTotal, liabilityTotal),
                    const SizedBox(height: 24),

                    // Net Cash Flow summary card
                    _buildNetCashFlowCard(isDark, totalInflow, totalOutflow, netCashFlow, savingsRate),
                    const SizedBox(height: 24),

                    // Account Balances Stack / swipable list
                    Text(
                      'Liquid Accounts & Liabilities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildAccountsCarousel(accounts, isDark),
                    const SizedBox(height: 32),

                    // Recent Activity list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (transactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Text(
                            'No transactions recorded yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...transactions.take(5).map((tx) {
                        // Find matching category details
                        final cat = categories.firstWhere(
                          (c) => c.id == tx.categoryId,
                          orElse: () => AppCategory(
                            id: '',
                            name: tx.flowDirection == 'TRANSFER' ? 'Transfer' : 'Uncategorized',
                            icon: tx.flowDirection == 'TRANSFER'
                                ? Icons.swap_horiz_rounded
                                : Icons.help_outline_rounded,
                            spent: 0.0,
                            budget: 0.0,
                            color: Colors.grey,
                            categoryType: 'EXPENSE',
                          ),
                        );

                        // Find matching account details
                        final acc = accounts.firstWhere(
                          (a) => a.id == tx.accountId,
                          orElse: () => Account(
                            id: '',
                            name: 'Unknown Account',
                            balance: 0.0,
                            type: 'checking',
                            color: Colors.grey,
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildTransactionActivityRow(context, tx, cat, acc, isDark),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),

          // Backdrop Dimming when menu expands
          if (_isMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isMenuOpen = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: Colors.black.withValues(alpha: 0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Draggable / Movable FAB assembly
          ..._buildDraggableFabMenu(context, isDark, size),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(bool isDark, double netWorth, double liquid, double liability) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL NET WORTH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          CurrencyDisplay(
            amount: netWorth,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assets', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    CurrencyDisplay(
                      amount: liquid,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Liabilities', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    CurrencyDisplay(
                      amount: liability,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.dangerRed),
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

  Widget _buildNetCashFlowCard(
    bool isDark,
    double inflow,
    double outflow,
    double net,
    double savingsRate,
  ) {
    final rateColor = net >= 0 ? AppTheme.emeraldGreen : AppTheme.dangerRed;
    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NET CASH FLOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${savingsRate.toStringAsFixed(1)}% savings',
                  style: TextStyle(
                    color: rateColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CurrencyDisplay(
            amount: net,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: net >= 0 ? AppTheme.emeraldGreen : AppTheme.dangerRed,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, color: AppTheme.emeraldGreen, size: 16),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Inflow', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        CurrencyDisplay(
                          amount: inflow,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, color: AppTheme.dangerRed, size: 16),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Outflow', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        CurrencyDisplay(
                          amount: outflow,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    );
  }

  Widget _buildAccountsCarousel(List<Account> accounts, bool isDark) {
    if (accounts.isEmpty) return const SizedBox();
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        itemBuilder: (context, idx) {
          final acc = accounts[idx];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                      style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    CurrencyDisplay(
                      amount: acc.balance,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
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

  Widget _buildTransactionActivityRow(
    BuildContext context,
    dynamic tx,
    AppCategory cat,
    Account acc,
    bool isDark,
  ) {
    Color flowColor;
    String prefix;

    if (tx.flowDirection == 'INFLOW') {
      flowColor = AppTheme.emeraldGreen;
      prefix = '+';
    } else if (tx.flowDirection == 'OUTFLOW') {
      flowColor = isDark ? Colors.white : Colors.black;
      prefix = '-';
    } else {
      flowColor = const Color(0xFF6366F1);
      prefix = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(cat.icon, color: cat.color, size: 20),
          ),
          const SizedBox(width: 16),

          // Description & Account
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? cat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      acc.name,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (tx.flowDirection == 'TRANSFER') ...[
                      const Icon(Icons.arrow_right_alt_rounded, size: 12, color: Colors.grey),
                      Text(
                        tx.transferTargetAccountId ?? 'Target',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    prefix,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: flowColor),
                  ),
                  CurrencyDisplay(
                    amount: tx.amount,
                    showSign: false,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: flowColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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

  List<Widget> _buildDraggableFabMenu(BuildContext context, bool isDark, Size screenSize) {
    final showUpward = _fabPosition.dy > screenSize.height / 2;

    final items = [
      _FabItem(
        icon: Icons.add_rounded,
        label: 'Add Transaction',
        color: AppTheme.emeraldGreen,
        onTap: () {
          setState(() => _isMenuOpen = false);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const AddTransactionModal(),
          );
        },
      ),
    ];

    List<Widget> stackChildren = [];

    if (_isMenuOpen) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final double topOffset = showUpward
            ? _fabPosition.dy - 52 - (i * 52)
            : _fabPosition.dy + 68 + (i * 52);

        stackChildren.add(
          Positioned(
            right: screenSize.width - _fabPosition.dx - 56,
            top: topOffset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'fab-${item.label}',
                  onPressed: item.onTap,
                  backgroundColor: item.color,
                  foregroundColor: Colors.white,
                  child: Icon(item.icon, size: 20),
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
        left: _fabPosition.dx,
        top: _fabPosition.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            _updateFabPosition(details.delta, screenSize);
          },
          onTap: () {
            setState(() {
              _isMenuOpen = !_isMenuOpen;
            });
          },
          child: FloatingActionButton(
            heroTag: 'main-fab',
            onPressed: null,
            backgroundColor: AppTheme.emeraldGreen,
            foregroundColor: Colors.black,
            child: AnimatedRotation(
              turns: _isMenuOpen ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.add_rounded, size: 28),
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

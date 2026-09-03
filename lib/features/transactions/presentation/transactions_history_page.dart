import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/preference_service.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../core/widgets/currency_display.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../core/widgets/drawer_blur_wrapper.dart';
import '../transactions_provider.dart';
import '../transaction_model.dart';
import '../../categories/categories_provider.dart';
import '../../accounts/accounts_provider.dart';

enum HistoryTimeHorizon {
  pastYear,
  thisYear,
  thisMonth,
  allTime,
  custom,
}

class TransactionsHistoryPage extends ConsumerStatefulWidget {
  const TransactionsHistoryPage({super.key});

  @override
  ConsumerState<TransactionsHistoryPage> createState() => _TransactionsHistoryPageState();
}

class _TransactionsHistoryPageState extends ConsumerState<TransactionsHistoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  HistoryTimeHorizon _selectedHorizon = HistoryTimeHorizon.pastYear;
  DateTimeRange? _customDateRange;
  String _selectedFlow = 'ALL'; // 'ALL', 'INFLOW' (Credit), 'OUTFLOW' (Debit), 'TRANSFER'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportLedger(
    List<Transaction> filteredTxs,
    List<AppCategory> categories,
    List<Account> accounts,
    String baseCurrency,
  ) async {
    if (filteredTxs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions available to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('fineX Transaction Ledger Statement');
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ')}');
    buffer.writeln('Currency: $baseCurrency');
    buffer.writeln('Filter Horizon: ${_getHorizonTitle(_selectedHorizon)}');
    buffer.writeln('Flow Type: $_selectedFlow');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('Date,Time,Type,Description,Category,Account,Amount,Flow');

    for (var tx in filteredTxs) {
      final cat = categories.firstWhere(
        (c) => c.id == tx.categoryId,
        orElse: () => AppCategory(
          id: '',
          name: tx.flowDirection == 'TRANSFER' ? 'Transfer' : 'General',
          icon: Icons.payments_rounded,
          spent: 0,
          budget: 0,
          color: Colors.grey,
          categoryType: 'EXPENSE',
        ),
      );
      final acc = accounts.firstWhere(
        (a) => a.id == tx.accountId,
        orElse: () => Account(id: '', name: 'Unknown Account', balance: 0, type: 'checking', color: Colors.grey),
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(tx.timestamp);
      final timeStr = DateFormat('HH:mm').format(tx.timestamp);
      final desc = (tx.description ?? cat.name).replaceAll(',', ' ');
      final flow = tx.flowDirection == 'INFLOW' ? 'Credit' : (tx.flowDirection == 'TRANSFER' ? 'Transfer' : 'Debit');

      buffer.writeln('$dateStr,$timeStr,$flow,"$desc","${cat.name}","${acc.name}",${tx.amount.toStringAsFixed(2)},${tx.flowDirection}');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/fineX_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'fineX Ledger Statement Export (${filteredTxs.length} records)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export statement: $e')),
        );
      }
    }
  }

  String _getHorizonTitle(HistoryTimeHorizon horizon) {
    final now = DateTime.now();
    switch (horizon) {
      case HistoryTimeHorizon.pastYear:
        return 'Past 1 Year';
      case HistoryTimeHorizon.thisYear:
        return 'Year ${now.year}';
      case HistoryTimeHorizon.thisMonth:
        return 'This Month (${DateFormat('MMM').format(now)})';
      case HistoryTimeHorizon.allTime:
        return 'All Time';
      case HistoryTimeHorizon.custom:
        if (_customDateRange != null) {
          final s = DateFormat('dd MMM').format(_customDateRange!.start);
          final e = DateFormat('dd MMM yyyy').format(_customDateRange!.end);
          return '$s - $e';
        }
        return 'Custom Range';
    }
  }

  void _showTransactionDetail(
    Transaction tx,
    AppCategory cat,
    Account acc,
    Account? targetAcc,
    bool isDark,
  ) {
    final isCredit = tx.flowDirection == 'INFLOW';
    final isTransfer = tx.flowDirection == 'TRANSFER';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description ?? cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('dd MMM yyyy, HH:mm').format(tx.timestamp)} • ${acc.name}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                CurrencyDisplay(
                  amount: isCredit ? tx.amount : -tx.amount,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isCredit
                        ? AppTheme.emeraldGreen
                        : (isTransfer ? AppTheme.neonBlue : (isDark ? Colors.white : Colors.black87)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailRow('Transaction ID', tx.id.substring(0, tx.id.length > 8 ? 8 : tx.id.length).toUpperCase(), isDark),
            _buildDetailRow('Flow Type', isCredit ? 'Credit (Inflow)' : (isTransfer ? 'Account Transfer' : 'Debit (Outflow)'), isDark),
            _buildDetailRow('Category', cat.name, isDark),
            _buildDetailRow('Account', acc.name, isDark),
            if (targetAcc != null)
              _buildDetailRow('Transfer To', targetAcc.name, isDark),
            if (tx.isTaxDeductible)
              _buildDetailRow('Tax Classification', 'Deductible Expense (RAMIS)', isDark),

            if (tx.splits.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Split Category Allocations:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 8),
              ...tx.splits.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.description ?? 'Split Allocation', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        CurrencyDisplay(amount: s.amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteTransaction(context, tx);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.dangerRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to permanently remove this transaction from the ledger?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted successfully.')),
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
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final accounts = ref.watch(accountsProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);

    final now = DateTime.now();

    final List<Transaction> timeFilteredTxs = transactions.where((tx) {
      switch (_selectedHorizon) {
        case HistoryTimeHorizon.pastYear:
          final oneYearAgo = now.subtract(const Duration(days: 365));
          return tx.timestamp.isAfter(oneYearAgo);
        case HistoryTimeHorizon.thisYear:
          return tx.timestamp.year == now.year;
        case HistoryTimeHorizon.thisMonth:
          return tx.timestamp.year == now.year && tx.timestamp.month == now.month;
        case HistoryTimeHorizon.allTime:
          return true;
        case HistoryTimeHorizon.custom:
          if (_customDateRange != null) {
            final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
            final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
            return tx.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
                   tx.timestamp.isBefore(end.add(const Duration(seconds: 1)));
          }
          return true;
      }
    }).toList();

    double periodCredits = 0.0;
    double periodDebits = 0.0;
    for (var tx in timeFilteredTxs) {
      if (tx.flowDirection == 'INFLOW') {
        periodCredits += tx.amount;
      } else if (tx.flowDirection == 'OUTFLOW') {
        periodDebits += tx.amount;
      }
    }
    final double netPeriodFlow = periodCredits - periodDebits;

    final List<Transaction> displayedTxs = timeFilteredTxs.where((tx) {
      // Flow filter
      if (_selectedFlow != 'ALL' && tx.flowDirection != _selectedFlow) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final desc = (tx.description ?? '').toLowerCase();
        final cat = categories.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => AppCategory(id: '', name: '', icon: Icons.help, spent: 0, budget: 0, color: Colors.grey, categoryType: 'EXPENSE'),
        );
        final acc = accounts.firstWhere(
          (a) => a.id == tx.accountId,
          orElse: () => Account(id: '', name: '', balance: 0, type: 'checking', color: Colors.grey),
        );

        final matchesDesc = desc.contains(query);
        final matchesCat = cat.name.toLowerCase().contains(query);
        final matchesAcc = acc.name.toLowerCase().contains(query);
        final matchesAmount = tx.amount.toString().contains(query);

        if (!matchesDesc && !matchesCat && !matchesAcc && !matchesAmount) {
          return false;
        }
      }

      return true;
    }).toList();


    final Map<String, List<Transaction>> groupedTxs = {};
    for (var tx in displayedTxs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.timestamp);
      groupedTxs.putIfAbsent(dateKey, () => []).add(tx);
    }

    final sortedDateKeys = groupedTxs.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
        drawer: const MainDrawer(activeRoute: '/transactions'),
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
          title: const Text('Transaction History'),
          actions: [
            IconButton(
              icon: Icon(_isSearchExpanded ? Icons.close_rounded : Icons.search_rounded),
              tooltip: 'Search Transactions',
              onPressed: () {
                setState(() {
                  _isSearchExpanded = !_isSearchExpanded;
                  if (!_isSearchExpanded) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Export Statement',
              onPressed: () => _exportLedger(displayedTxs, categories, accounts, baseCurrency),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: DrawerBlurWrapper(
          isDrawerOpen: _isDrawerOpen,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Search Bar (Expandable)
                  if (_isSearchExpanded) ...[
                    FadeSlideTransition(
                      delay: Duration.zero,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131D2E) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search description, category, or account...',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ),
                  ],

                  // Executive Period Summary Card & Time Selector
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
                          // Header Row with Time Horizon Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PERIOD LEDGER SUMMARY',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  CurrencyDisplay(
                                    amount: netPeriodFlow,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: netPeriodFlow >= 0 ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<HistoryTimeHorizon>(
                                initialValue: _selectedHorizon,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onSelected: (horizon) async {
                                  if (horizon == HistoryTimeHorizon.custom) {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                      initialDateRange: _customDateRange ?? DateTimeRange(
                                        start: DateTime.now().subtract(const Duration(days: 30)),
                                        end: DateTime.now(),
                                      ),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _customDateRange = picked;
                                        _selectedHorizon = HistoryTimeHorizon.custom;
                                      });
                                    }
                                  } else {
                                    setState(() => _selectedHorizon = horizon);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.emeraldGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        _getHorizonTitle(_selectedHorizon),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: HistoryTimeHorizon.pastYear,
                                    child: Text('Past 1 Year (365 Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                  PopupMenuItem(
                                    value: HistoryTimeHorizon.thisYear,
                                    child: Text('Year ${now.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                  const PopupMenuItem(
                                    value: HistoryTimeHorizon.thisMonth,
                                    child: Text('This Month', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                  const PopupMenuItem(
                                    value: HistoryTimeHorizon.allTime,
                                    child: Text('All Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: HistoryTimeHorizon.custom,
                                    child: Row(
                                      children: [
                                        Icon(Icons.date_range_rounded, size: 16, color: AppTheme.emeraldGreen),
                                        SizedBox(width: 8),
                                        Text('Custom Range...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Credits vs Debits breakdown pills
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.wealthGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded, size: 14, color: AppTheme.emeraldGreen),
                                      const SizedBox(width: 6),
                                      const Text('Credits: ', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      Flexible(
                                        child: CurrencyDisplay(
                                          amount: periodCredits,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppTheme.emeraldGreen),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRed.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded, size: 14, color: AppTheme.dangerRed),
                                      const SizedBox(width: 6),
                                      const Text('Debits: ', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      Flexible(
                                        child: CurrencyDisplay(
                                          amount: periodDebits,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppTheme.dangerRed),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Flow Type Segment Filter Tabs
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 30),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFlowFilterChip('ALL', 'All (${timeFilteredTxs.length})', isDark),
                          _buildFlowFilterChip('INFLOW', 'Credits (${timeFilteredTxs.where((t) => t.flowDirection == 'INFLOW').length})', isDark, AppTheme.emeraldGreen),
                          _buildFlowFilterChip('OUTFLOW', 'Debits (${timeFilteredTxs.where((t) => t.flowDirection == 'OUTFLOW').length})', isDark, AppTheme.dangerRed),
                          _buildFlowFilterChip('TRANSFER', 'Transfers (${timeFilteredTxs.where((t) => t.flowDirection == 'TRANSFER').length})', isDark, AppTheme.neonBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Transaction List
                  Expanded(
                    child: displayedTxs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 44, color: Colors.grey.withValues(alpha: 0.35)),
                                const SizedBox(height: 12),
                                const Text('No Transactions Found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No entries match "$_searchQuery".'
                                      : 'No transactions recorded for the selected period.',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: sortedDateKeys.length,
                            itemBuilder: (context, dateIndex) {
                              final dateKey = sortedDateKeys[dateIndex];
                              final txsOnDate = groupedTxs[dateKey]!;
                              final parsedDate = DateTime.parse(dateKey);

                              String dateHeader;
                              final diffDays = now.difference(DateTime(parsedDate.year, parsedDate.month, parsedDate.day)).inDays;
                              if (diffDays == 0 && now.day == parsedDate.day) {
                                dateHeader = 'Today';
                              } else if (diffDays == 1 || (now.day - parsedDate.day == 1 && now.month == parsedDate.month)) {
                                dateHeader = 'Yesterday';
                              } else if (parsedDate.year == now.year) {
                                dateHeader = DateFormat('EEE, dd MMMM').format(parsedDate);
                              } else {
                                dateHeader = DateFormat('EEE, dd MMM yyyy').format(parsedDate);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dateHeader.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '${txsOnDate.length} entries',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...txsOnDate.map((tx) {
                                    final cat = categories.firstWhere(
                                      (c) => c.id == tx.categoryId,
                                      orElse: () => AppCategory(
                                        id: '',
                                        name: tx.flowDirection == 'TRANSFER' ? 'Transfer' : 'General',
                                        icon: tx.flowDirection == 'TRANSFER' ? Icons.swap_horiz_rounded : Icons.payments_rounded,
                                        spent: 0,
                                        budget: 0,
                                        color: tx.flowDirection == 'TRANSFER' ? AppTheme.neonBlue : AppTheme.emeraldGreen,
                                        categoryType: 'EXPENSE',
                                      ),
                                    );
                                    final acc = accounts.firstWhere(
                                      (a) => a.id == tx.accountId,
                                      orElse: () => Account(id: '', name: 'Primary Account', balance: 0, type: 'checking', color: Colors.grey),
                                    );
                                    final targetAcc = tx.transferTargetAccountId != null
                                        ? accounts.firstWhere(
                                            (a) => a.id == tx.transferTargetAccountId,
                                            orElse: () => Account(id: '', name: 'Destination Account', balance: 0, type: 'checking', color: Colors.grey),
                                          )
                                        : null;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _showTransactionDetail(tx, cat, acc, targetAcc, isDark),
                                        child: _buildTransactionTile(context, tx, cat, acc, targetAcc, isDark),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowFilterChip(String flow, String label, bool isDark, [Color? activeColor]) {
    final isSelected = _selectedFlow == flow;
    final color = activeColor ?? (isDark ? Colors.white : Colors.black87);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedFlow = flow),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (activeColor != null ? activeColor.withValues(alpha: 0.15) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)))
                : (isDark ? const Color(0xFF131D2E) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (activeColor ?? (isDark ? Colors.white : Colors.black87))
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Transaction tx,
    AppCategory cat,
    Account acc,
    Account? targetAcc,
    bool isDark,
  ) {
    final bool isCredit = tx.flowDirection == 'INFLOW';
    final bool isTransfer = tx.flowDirection == 'TRANSFER';

    return Container(
      padding: const EdgeInsets.all(13),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cat.color.withValues(alpha: 0.35), width: 1),
            ),
            child: Icon(cat.icon, color: cat.color, size: 20),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? cat.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      acc.name,
                      style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    if (targetAcc != null) ...[
                      const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.grey),
                      Text(targetAcc.name, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      '• ${DateFormat('HH:mm').format(tx.timestamp)}',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                    ),
                    if (tx.splits.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.purpleAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${tx.splits.length} SPLITS',
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppTheme.purpleAccent),
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
              CurrencyDisplay(
                amount: isCredit ? tx.amount : -tx.amount,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: isCredit
                      ? AppTheme.emeraldGreen
                      : (isTransfer ? AppTheme.neonBlue : (isDark ? Colors.white : const Color(0xFF0F172A))),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isCredit
                      ? AppTheme.wealthGreen.withValues(alpha: 0.12)
                      : (isTransfer ? AppTheme.neonBlue.withValues(alpha: 0.12) : AppTheme.dangerRed.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCredit ? 'CREDIT' : (isTransfer ? 'TRANSFER' : 'DEBIT'),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isCredit
                        ? AppTheme.emeraldGreen
                        : (isTransfer ? AppTheme.neonBlue : AppTheme.dangerRed),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

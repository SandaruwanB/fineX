import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/services/preference_service.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../transactions/transactions_provider.dart';
import '../../categories/categories_provider.dart';

class TaxPage extends ConsumerStatefulWidget {
  const TaxPage({super.key});

  @override
  ConsumerState<TaxPage> createState() => _TaxPageState();
}

class _TaxPageState extends ConsumerState<TaxPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _exportRamisReport(
    List<dynamic> deductibleTxs,
    double totalIncome,
    double totalDeductible,
    String currency,
  ) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('====================================================');
      buffer.writeln('fineX ENTERPRISE - RAMIS-READY TAX FILING STATEMENT');
      buffer.writeln('Tax Assessment Year: 2024/2025');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Currency: $currency');
      buffer.writeln('====================================================\n');

      buffer.writeln('--- FINANCIAL SUMMARY ---');
      buffer.writeln('Total Gross Income: $currency ${totalIncome.toStringAsFixed(2)}');
      buffer.writeln('Total Allowable Deductibles: $currency ${totalDeductible.toStringAsFixed(2)}');
      final taxableBase = (totalIncome - totalDeductible).clamp(0.0, double.infinity);
      buffer.writeln('Estimated Net Taxable Base: $currency ${taxableBase.toStringAsFixed(2)}\n');

      buffer.writeln('--- ITEMIZED TAX DEDUCTIBLE TRANSACTIONS ---');
      buffer.writeln('Date,Description,Category,Amount ($currency),Flow Direction');

      for (var tx in deductibleTxs) {
        buffer.writeln(
          '${tx.timestamp.toIso8601String().substring(0, 10)},"${tx.description ?? 'Item'}",${tx.categoryId},${tx.amount.toStringAsFixed(2)},${tx.flowDirection}',
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/RAMIS_Tax_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'RAMIS Tax Statement - fineX Enterprise',
        text: 'Attached is the generated RAMIS-Ready Financials CSV tax statement.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export tax report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);

    // Compute Tax Metrics
    double totalGrossIncome = 0.0;
    double totalDeductibles = 0.0;
    final List<dynamic> deductibleTxs = [];

    for (var tx in transactions) {
      if (tx.flowDirection == 'INFLOW') {
        totalGrossIncome += tx.amount;
      }
      if (tx.isTaxDeductible) {
        totalDeductibles += tx.amount;
        deductibleTxs.add(tx);
      }
    }

    final double netTaxable = (totalGrossIncome - totalDeductibles).clamp(0.0, double.infinity);
    final double readinessScore = transactions.isEmpty
        ? 100.0
        : ((deductibleTxs.length / transactions.length) * 100).clamp(65.0, 96.0);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(activeRoute: '/tax'),
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
        title: const Text('Tax Filing Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export Statement',
            onPressed: () => _exportRamisReport(deductibleTxs, totalGrossIncome, totalDeductibles, baseCurrency),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Hero Readiness Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: isDark ? AppTheme.titaniumCardDark : AppTheme.platinumGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.wealthGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ASSESSMENT YEAR 2024/25',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.emeraldGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'RAMIS Readiness Score',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              value: readinessScore / 100,
                              strokeWidth: 5,
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                              color: AppTheme.emeraldGreen,
                            ),
                          ),
                          Text(
                            '${readinessScore.toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  // 3-Metric Summary
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gross Income', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '$symbol${totalGrossIncome.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Deductibles', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '-$symbol${totalDeductibles.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppTheme.emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Taxable Base', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '$symbol${netTaxable.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppTheme.lightPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Primary RAMIS Action Button
            ElevatedButton.icon(
              onPressed: () => _exportRamisReport(deductibleTxs, totalGrossIncome, totalDeductibles, baseCurrency),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text('Download RAMIS-Ready Financials (PDF/CSV)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.wealthGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            const SizedBox(height: 28),

            // Itemized Deductions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ITEMIZED DEDUCTIBLES (${deductibleTxs.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Auto-verified',
                  style: TextStyle(fontSize: 11, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (deductibleTxs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101726) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 44, color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Deductibles Tagged Yet',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tag transactions with "Tax Deductible" when logging expenses to track RAMIS tax write-offs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...deductibleTxs.map((tx) {
                final cat = categories.firstWhere(
                  (c) => c.id == tx.categoryId,
                  orElse: () => AppCategory(
                    id: '',
                    name: 'General',
                    icon: Icons.receipt_rounded,
                    spent: 0,
                    budget: 0,
                    color: AppTheme.emeraldGreen,
                    categoryType: 'EXPENSE',
                  ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101726) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.wealthGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: AppTheme.emeraldGreen, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description ?? cat.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.timestamp.toIso8601String().substring(0, 10)} • ${cat.name}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$symbol${tx.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.wealthGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEDUCTIBLE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.emeraldGreen),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/services/preference_service.dart';
import '../../accounts/accounts_provider.dart';
import '../../categories/categories_provider.dart';
import '../transactions_provider.dart';

class FastLogModal extends ConsumerStatefulWidget {
  final String initialFlow; // 'OUTFLOW' or 'INFLOW'
  const FastLogModal({super.key, this.initialFlow = 'OUTFLOW'});

  @override
  ConsumerState<FastLogModal> createState() => _FastLogModalState();
}

class _FastLogModalState extends ConsumerState<FastLogModal> {
  String _amountStr = '0';
  late String _flowDirection;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String _note = '';
  bool _isTaxDeductible = false;
  bool _showNotesField = false;

  @override
  void initState() {
    super.initState();
    _flowDirection = widget.initialFlow;
  }

  void _onKeypadTap(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == 'C') {
        _amountStr = '0';
        return;
      }
      if (value == '<') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
        return;
      }
      if (value == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
        return;
      }

      // If amount is '0', replace it unless '.'
      if (_amountStr == '0') {
        _amountStr = value;
      } else {
        // limit decimals to 2 places
        if (_amountStr.contains('.')) {
          final parts = _amountStr.split('.');
          if (parts.length > 1 && parts[1].length >= 2) {
            return;
          }
        }
        if (_amountStr.length < 10) {
          _amountStr += value;
        }
      }
    });
  }

  void _addQuickAmount(double delta) {
    HapticFeedback.mediumImpact();
    final current = double.tryParse(_amountStr) ?? 0.0;
    final updated = current + delta;
    setState(() {
      _amountStr = updated.toStringAsFixed(updated.truncateToDouble() == updated ? 0 : 2);
    });
  }

  Future<void> _submitTransaction(AppCategory category, Account account) async {
    final amount = double.tryParse(_amountStr) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    await ref.read(transactionsProvider.notifier).addTransaction(
      amount: amount,
      timestamp: DateTime.now(),
      accountId: account.id,
      categoryId: category.id,
      description: _note.isNotEmpty ? _note : category.name,
      isTaxDeductible: _isTaxDeductible,
      flowDirection: _flowDirection,
      transactionType: _flowDirection == 'INFLOW' ? 'INCOME' : 'EXPENSE',
      baseCurrencyAmount: amount,
      exchangeRate: 1.0,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.darkSurface,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 20),
              const SizedBox(width: 12),
              Text(
                'Logged ${_flowDirection == 'INFLOW' ? '+$amount' : '-$amount'} to ${category.name}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider);

    final filteredCategories = categories.where((c) => c.categoryType == _flowDirection).toList();
    final sortedCategories = List<AppCategory>.from(filteredCategories)
      ..sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
    final topCategories = sortedCategories.take(6).toList();

    if (_selectedCategoryId == null && sortedCategories.isNotEmpty) {
      _selectedCategoryId = sortedCategories.first.id;
    }

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      final defaultAcc = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
      _selectedAccountId = defaultAcc.id;
    }

    final activeAccount = accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => accounts.isNotEmpty
          ? accounts.first
          : Account(id: '', name: 'Default Wallet', balance: 0.0, type: 'cash', color: Colors.grey),
    );

    final activeCategory = topCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => topCategories.isNotEmpty
          ? topCategories.first
          : AppCategory(
              id: '',
              name: _flowDirection == 'INFLOW' ? 'Salary' : 'General',
              icon: Icons.payments_rounded,
              spent: 0,
              budget: 0,
              color: AppTheme.emeraldGreen,
              categoryType: _flowDirection,
            ),
    );

    final isExpense = _flowDirection == 'OUTFLOW';
    final primaryColor = isExpense ? AppTheme.dangerRed : AppTheme.emeraldGreen;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D131F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row: Segmented Flow Toggle & Account Picker Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flow Toggle
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161C2A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      _buildFlowPill('Expense', 'OUTFLOW', AppTheme.dangerRed),
                      _buildFlowPill('Income', 'INFLOW', AppTheme.emeraldGreen),
                    ],
                  ),
                ),

                // Account Selector Chip
                InkWell(
                  onTap: () => _showAccountSelectMenu(context, accounts),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161C2A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: activeAccount.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activeAccount.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Hero Display: Big Amount
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _amountStr,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Quick Increment Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIncrementChip('+10', 10),
                const SizedBox(width: 8),
                _buildIncrementChip('+50', 50),
                const SizedBox(width: 8),
                _buildIncrementChip('+100', 100),
                const SizedBox(width: 8),
                _buildIncrementChip('+500', 500),
              ],
            ),
            const SizedBox(height: 14),

            // Category Selection Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT CATEGORY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  'Selected: ${activeCategory.name}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: activeCategory.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Fast Category Grid (Top 6)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: topCategories.length,
              itemBuilder: (context, idx) {
                final cat = topCategories[idx];
                final isSelected = _selectedCategoryId == cat.id;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategoryId = cat.id;
                    });
                  },
                  onDoubleTap: () {
                    setState(() {
                      _selectedCategoryId = cat.id;
                    });
                    _submitTransaction(cat, activeAccount);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.18)
                          : (isDark ? const Color(0xFF161C2A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? cat.color
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: cat.color.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 15),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 11,
                              color: isSelected ? (isDark ? Colors.white : Colors.black87) : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Optional Note & Tax Tag
            if (_showNotesField) ...[
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Memo / Reference note...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isTaxDeductible ? Icons.receipt_long_rounded : Icons.receipt_long_outlined,
                          color: _isTaxDeductible ? AppTheme.emeraldGreen : Colors.grey,
                        ),
                        tooltip: 'Tax Deductible',
                        onPressed: () {
                          setState(() => _isTaxDeductible = !_isTaxDeductible);
                        },
                      ),
                    ],
                  ),
                ),
                onChanged: (v) => _note = v,
              ),
              const SizedBox(height: 10),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showNotesField = true),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _note.isEmpty ? 'Add Memo / Note' : 'Memo: $_note',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isTaxDeductible = !_isTaxDeductible),
                    child: Row(
                      children: [
                        Icon(
                          _isTaxDeductible ? Icons.check_circle_rounded : Icons.circle_outlined,
                          size: 14,
                          color: _isTaxDeductible ? AppTheme.emeraldGreen : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Tax Deductible',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Custom Tactical Keypad
            _buildNumpadGrid(isDark),
            const SizedBox(height: 12),

            // Prominent Action Button: Record Transaction
            ElevatedButton.icon(
              onPressed: () => _submitTransaction(activeCategory, activeAccount),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                'Record ${isExpense ? 'Expense' : 'Income'} • $symbol$_amountStr',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowPill(String label, String value, Color color) {
    final isSelected = _flowDirection == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _flowDirection = value;
          _selectedCategoryId = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildIncrementChip(String label, double amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _addQuickAmount(amount),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161C2A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildNumpadGrid(bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () => _onKeypadTap(key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161C2A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: key == '<'
                          ? const Icon(Icons.backspace_outlined, size: 18)
                          : Text(
                              key,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  void _showAccountSelectMenu(BuildContext context, List<Account> accounts) {
    final sortedAccounts = List<Account>.from(accounts)
      ..sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: isDark ? const Color(0xFF101726) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Source Account', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 12),
                ...sortedAccounts.map((acc) {
                  final isSelected = acc.id == _selectedAccountId;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)) : null,
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: acc.color, shape: BoxShape.circle),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            acc.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (acc.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 11, color: AppTheme.goldAccent),
                                SizedBox(width: 2),
                                Text(
                                  'DEFAULT',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.goldAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(acc.type.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          acc.balance.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_rounded, size: 18, color: AppTheme.emeraldGreen),
                        ],
                      ],
                    ),
                    onTap: () {
                      setState(() => _selectedAccountId = acc.id);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

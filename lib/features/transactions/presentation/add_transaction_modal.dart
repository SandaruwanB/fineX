import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/flow_segmented_control.dart';
import '../../../core/widgets/split_transaction_list.dart';
import '../../accounts/accounts_provider.dart';
import '../../categories/categories_provider.dart';
import '../transaction_model.dart';
import '../transactions_provider.dart';
import '../../../core/services/preference_service.dart';
import '../../../core/constants/currencies.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  const AddTransactionModal({super.key});

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _flowDirection = 'EXPENSE'; 
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedTargetAccountId;
  bool _isSplitEnabled = false;

  final List<TransactionSplitDraft> _splits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = ref.read(accountsProvider);
      if (accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = accounts.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAddSplitItem(List<AppCategory> filteredCats) {
    if (filteredCats.isEmpty) return;
    setState(() {
      _splits.add(TransactionSplitDraft(
        amount: 0.0,
        categoryId: filteredCats.first.id,
      ));
    });
  }

  void _onDeleteSplitItem(int idx) {
    setState(() {
      _splits.removeAt(idx);
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than zero.')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account.')),
      );
      return;
    }

    if (_flowDirection == 'TRANSFER') {
      if (_selectedTargetAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a target destination account.')),
        );
        return;
      }
      if (_selectedAccountId == _selectedTargetAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts cannot be the same.')),
        );
        return;
      }
    } else {
      if (!_isSplitEnabled && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category.')),
        );
        return;
      }

      if (_isSplitEnabled) {
        if (_splits.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one split line item.')),
          );
          return;
        }

        final double allocated = _splits.fold(0.0, (sum, item) => sum + item.amount);
        if ((amount - allocated).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Allocated split items total must exactly equal transaction amount.')),
          );
          return;
        }
      }
    }

    List<TransactionSplit> finalSplits = [];
    if (_isSplitEnabled && _flowDirection != 'TRANSFER') {
      for (var draft in _splits) {
        finalSplits.add(TransactionSplit(
          id: DateTime.now().millisecondsSinceEpoch.toString() + draft.hashCode.toString(),
          transactionId: '',
          categoryId: draft.categoryId,
          amount: draft.amount,
          flowDirection: _flowDirection,
          description: draft.description.isNotEmpty ? draft.description : null,
        ));
      }
    }

    // Save
    await ref.read(transactionsProvider.notifier).addTransaction(
          flowDirection: _flowDirection == 'TRANSFER' ? 'TRANSFER' : _flowDirection,
          transactionType: _flowDirection == 'TRANSFER'
              ? 'TRANSFER'
              : (_flowDirection == 'INCOME' ? 'SALARY' : 'OPERATING_EXPENSE'),
          amount: amount,
          categoryId: _flowDirection == 'TRANSFER' ? null : (_isSplitEnabled ? null : _selectedCategoryId),
          accountId: _selectedAccountId!,
          transferTargetAccountId: _flowDirection == 'TRANSFER' ? _selectedTargetAccountId : null,
          baseCurrencyAmount: amount,
          exchangeRate: 1.0,
          timestamp: DateTime.now(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          splits: finalSplits,
        );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider);
    final symbol = worldCurrencies[baseCurrency] ?? '\$';

    final filteredCategories = categories.where((cat) => cat.categoryType == _flowDirection).toList();

    if (_flowDirection != 'TRANSFER' && filteredCategories.isNotEmpty) {
      if (_selectedCategoryId == null || !filteredCategories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = filteredCategories.first.id;
      }
    }

    Color activeAccent;
    if (_flowDirection == 'INCOME') {
      activeAccent = AppTheme.emeraldGreen;
    } else if (_flowDirection == 'TRANSFER') {
      activeAccent = const Color(0xFF6366F1);
    } else {
      activeAccent = const Color(0xFFF43F5E);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
              const SizedBox(height: 20),

              Text(
                'Record Transaction',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 20),

              FlowSegmentedControl(
                selectedValue: _flowDirection,
                onValueChanged: (val) {
                  setState(() {
                    _flowDirection = val;
                    _isSplitEnabled = false;
                    _splits.clear();
                  });
                },
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: activeAccent,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '$symbol ',
                  prefixStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: activeAccent,
                  ),
                  labelText: 'Amount',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter value';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Invalid amount';
                  return null;
                },
                onChanged: (val) {
                  setState(() {}); 
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Source Account',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text(acc.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedAccountId = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              if (_flowDirection == 'TRANSFER') ...[
                DropdownButtonFormField<String>(
                  value: _selectedTargetAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Destination Account',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text(acc.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTargetAccountId = val;
                    });
                  },
                ),
              ] else ...[
                if (!_isSplitEnabled) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    items: filteredCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(cat.icon, color: cat.color, size: 20),
                            const SizedBox(width: 12),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Split / Itemize Bill?',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Switch(
                      value: _isSplitEnabled,
                      activeThumbColor: activeAccent,
                      activeTrackColor: activeAccent.withValues(alpha: 0.5),
                      onChanged: (val) {
                        setState(() {
                          _isSplitEnabled = val;
                          if (val) {
                            _splits.clear();
                            _onAddSplitItem(filteredCategories);
                          }
                        });
                      },
                    ),
                  ],
                ),

                if (_isSplitEnabled) ...[
                  const SizedBox(height: 12),
                  SplitTransactionList(
                    totalAmount: double.tryParse(_amountController.text.trim()) ?? 0.0,
                    flowDirection: _flowDirection,
                    categories: filteredCategories,
                    splits: _splits,
                    onAddSplit: () => _onAddSplitItem(filteredCategories),
                    onDeleteSplit: _onDeleteSplitItem,
                    onSplitsChanged: () => setState(() {}),
                    currencySymbol: symbol,
                  ),
                ],
              ],

              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Memo / Notes',
                  hintText: 'e.g. Weekly grocery check',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Record'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

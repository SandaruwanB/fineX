import 'package:flutter/material.dart';
import '../../features/categories/categories_provider.dart';
import '../theme/app_theme.dart';

class TransactionSplitDraft {
    double amount;
    String categoryId;
    String description;
    bool isTaxDeductible;

    TransactionSplitDraft({
        required this.amount,
        required this.categoryId,
        this.description = '',
        this.isTaxDeductible = false,
    });
}

class SplitTransactionList extends StatefulWidget {
    final double totalAmount;
    final String flowDirection;
    final List<AppCategory> categories;
    final List<TransactionSplitDraft> splits;
    final VoidCallback onAddSplit;
    final Function(int) onDeleteSplit;
    final VoidCallback onSplitsChanged;
    final String currencySymbol;

    const SplitTransactionList({
        super.key,
        required this.totalAmount,
        required this.flowDirection,
        required this.categories,
        required this.splits,
        required this.onAddSplit,
        required this.onDeleteSplit,
        required this.onSplitsChanged,
        required this.currencySymbol,
    });

    @override
    State<SplitTransactionList> createState() => _SplitTransactionListState();
}

class _SplitTransactionListState extends State<SplitTransactionList> {
    @override
    Widget build(BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final double allocated = widget.splits.fold(0.0, (sum, item) => sum + item.amount);
        final double remaining = widget.totalAmount - allocated;
        final isMatched = remaining.abs() < 0.01;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        const Text(
                            'Splits & Itemization',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        TextButton.icon(
                            onPressed: widget.onAddSplit,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Item'),
                            style: TextButton.styleFrom(
                            foregroundColor: widget.flowDirection == 'INCOME'
                                ? AppTheme.emeraldGreen
                                : const Color(0xFFF43F5E),
                            ),
                        ),
                    ],
                ),
                const SizedBox(height: 8),

                ...widget.splits.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                    children: [
                                        Expanded(
                                            flex: 3,
                                            child: DropdownButtonFormField<String>(
                                                value: widget.categories.any((c) => c.id == item.categoryId)
                                                    ? item.categoryId
                                                    : (widget.categories.isNotEmpty ? widget.categories.first.id : null),
                                                decoration: const InputDecoration(
                                                    labelText: 'Category',
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                ),
                                                items: widget.categories.map((cat) {
                                                    return DropdownMenuItem(
                                                        value: cat.id,
                                                        child: Row(
                                                            children: [
                                                                Icon(cat.icon, size: 16, color: cat.color),
                                                                const SizedBox(width: 8),
                                                                Text(cat.name, style: const TextStyle(fontSize: 12)),
                                                            ],
                                                        ),
                                                    );
                                                }).toList(),
                                                onChanged: (val) {
                                                    if (val != null) {
                                                        setState(() {
                                                            item.categoryId = val;
                                                        });
                                                        widget.onSplitsChanged();
                                                    }
                                                },
                                            ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                            initialValue: item.amount > 0 ? item.amount.toStringAsFixed(2) : '',
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                                labelText: 'Amount',
                                                prefixText: widget.currencySymbol,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                border: const OutlineInputBorder(),
                                            ),
                                                onChanged: (val) {
                                                    setState(() {
                                                        item.amount = double.tryParse(val) ?? 0.0;
                                                    });
                                                widget.onSplitsChanged();
                                            },
                                        ),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.delete_rounded, color: AppTheme.dangerRed, size: 20),
                                        onPressed: () => widget.onDeleteSplit(idx),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                                children: [
                                    Expanded(
                                        child: TextFormField(
                                            initialValue: item.description,
                                            decoration: const InputDecoration(
                                                labelText: 'Split Description',
                                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                border: OutlineInputBorder(),
                                            ),
                                                onChanged: (val) {
                                                    item.description = val;
                                                    widget.onSplitsChanged();
                                                },
                                            ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                            children: [
                                                Checkbox(
                                                    value: item.isTaxDeductible,
                                                    onChanged: (val) {
                                                        setState(() {
                                                            item.isTaxDeductible = val ?? false;
                                                        });
                                                        widget.onSplitsChanged();
                                                    },
                                                ),
                                                const Text('Tax Deductible', style: TextStyle(fontSize: 11)),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    );
                }),

                const SizedBox(height: 8),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: isMatched
                            ? AppTheme.emeraldGreen.withValues(alpha: 0.1)
                            : AppTheme.dangerRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                                'Total: ${widget.currencySymbol}${widget.totalAmount.toStringAsFixed(2)}  |  Allocated: ${widget.currencySymbol}${allocated.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                ),
                            ),
                            Text(
                                isMatched
                                    ? 'Balances Match!'
                                    : 'Remaining: ${widget.currencySymbol}${remaining.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isMatched ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        );
    }
}

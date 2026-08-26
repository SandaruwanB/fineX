import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FlowSegmentedControl extends StatelessWidget {
    final String selectedValue; // 'EXPENSE' | 'INCOME' | 'TRANSFER'
    final ValueChanged<String> onValueChanged;

    const FlowSegmentedControl({
        super.key,
        required this.selectedValue,
        required this.onValueChanged,
    });

    @override
    Widget build(BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
    
        Color activeColor;
        if (selectedValue == 'INCOME') {
            activeColor = AppTheme.emeraldGreen;
        } else if (selectedValue == 'TRANSFER') {
            activeColor = const Color(0xFF6366F1);
        } else {
            activeColor = const Color(0xFFF43F5E);
        }

        final segments = [
            {'label': 'Expense', 'value': 'EXPENSE'},
            {'label': 'Income', 'value': 'INCOME'},
            {'label': 'Transfer', 'value': 'TRANSFER'},
        ];

            return Container(
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                    children: segments.map((seg) {
                        final isSelected = selectedValue == seg['value'];
                        return Expanded(
                            child: GestureDetector(
                            onTap: () => onValueChanged(seg['value']!),
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                    color: isSelected ? activeColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                    seg['label']!,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                ),
                            ),
                        ),
                    );
                }).toList(),
            ),
        );
    }
}

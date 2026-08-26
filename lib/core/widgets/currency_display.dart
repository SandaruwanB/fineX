import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preference_service.dart';
import '../constants/currencies.dart';

class CurrencyDisplay extends ConsumerWidget {
    final double amount;
    final TextStyle? style;
    final bool showSign;

    const CurrencyDisplay({
        super.key,
        required this.amount,
        this.style,
        this.showSign = true,
    });

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final isPrivacyEnabled = ref.watch(privacyModeProvider);
        final baseCurrency = ref.watch(baseCurrencyProvider);
        final textStyle = style ?? Theme.of(context).textTheme.bodyMedium;

        final symbol = worldCurrencies[baseCurrency] ?? '\$';

        if (isPrivacyEnabled) {
            return Text(
                showSign ? '$symbol ••••' : '••••',
                style: textStyle?.copyWith(letterSpacing: 2),
            );
        }

        final isNegative = amount < 0;
        final absAmount = amount.abs();

        final parts = absAmount.toStringAsFixed(2).split('.');
        final integerPart = parts[0];
        final decimalPart = parts[1];

        final formattedInteger = integerPart.replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
        );

        final formattedAmount = '$symbol$formattedInteger.$decimalPart';
        final signStr = isNegative ? '-' : '';

        return Text(
            showSign ? '$signStr$formattedAmount' : '$signStr$formattedInteger.$decimalPart',
            style: textStyle,
        );
    }
}

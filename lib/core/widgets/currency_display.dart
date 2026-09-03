import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preference_service.dart';
import '../services/number_format_service.dart';
import '../constants/currencies.dart';

class CurrencyDisplay extends ConsumerWidget {
  final double amount;
  final TextStyle? style;
  final bool showSign;
  final bool withSymbol;

  const CurrencyDisplay({
    super.key,
    required this.amount,
    this.style,
    this.showSign = true,
    this.withSymbol = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivacyEnabled = ref.watch(privacyModeProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final separatorFormat = ref.watch(numberSeparatorFormatProvider);
    final decimalDigits = ref.watch(decimalDigitsProvider);
    final withSpace = ref.watch(currencySpacingProvider);
    final textStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    final symbol = worldCurrencies[baseCurrency] ?? '\$';

    if (isPrivacyEnabled) {
      final space = withSpace ? ' ' : '';
      return Text(
        showSign && withSymbol ? '$symbol$space••••' : '••••',
        style: textStyle?.copyWith(letterSpacing: 2),
      );
    }

    final formatted = NumberFormatService.formatAmount(
      amount: amount,
      separatorFormat: separatorFormat,
      decimalDigits: decimalDigits,
      withSpace: withSpace,
      currencySymbol: withSymbol ? symbol : null,
      showSign: showSign,
    );

    return Text(
      formatted,
      style: textStyle,
    );
  }
}

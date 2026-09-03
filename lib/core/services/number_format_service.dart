import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'preference_service.dart';
import '../constants/currencies.dart';

enum NumberSeparatorFormat {
  commaDot,
  dotComma,
  spaceDot,
  spaceComma,
  indianLakhs,
}

extension NumberSeparatorFormatExtension on NumberSeparatorFormat {
  String get id {
    switch (this) {
      case NumberSeparatorFormat.commaDot:
        return 'commaDot';
      case NumberSeparatorFormat.dotComma:
        return 'dotComma';
      case NumberSeparatorFormat.spaceDot:
        return 'spaceDot';
      case NumberSeparatorFormat.spaceComma:
        return 'spaceComma';
      case NumberSeparatorFormat.indianLakhs:
        return 'indianLakhs';
    }
  }

  String get title {
    switch (this) {
      case NumberSeparatorFormat.commaDot:
        return 'Standard (1,234,567.89)';
      case NumberSeparatorFormat.dotComma:
        return 'European (1.234.567,89)';
      case NumberSeparatorFormat.spaceDot:
        return 'Space & Dot (1 234 567.89)';
      case NumberSeparatorFormat.spaceComma:
        return 'Space & Comma (1 234 567,89)';
      case NumberSeparatorFormat.indianLakhs:
        return 'South Asian Lakhs (1,23,456.78)';
    }
  }

  String get subtitle {
    switch (this) {
      case NumberSeparatorFormat.commaDot:
        return 'Comma thousands, period decimal';
      case NumberSeparatorFormat.dotComma:
        return 'Period thousands, comma decimal';
      case NumberSeparatorFormat.spaceDot:
        return 'Space thousands, period decimal';
      case NumberSeparatorFormat.spaceComma:
        return 'Space thousands, comma decimal';
      case NumberSeparatorFormat.indianLakhs:
        return 'Lakh / Crore grouping system';
    }
  }

  static NumberSeparatorFormat fromId(String id) {
    switch (id) {
      case 'dotComma':
        return NumberSeparatorFormat.dotComma;
      case 'spaceDot':
        return NumberSeparatorFormat.spaceDot;
      case 'spaceComma':
        return NumberSeparatorFormat.spaceComma;
      case 'indianLakhs':
        return NumberSeparatorFormat.indianLakhs;
      case 'commaDot':
      default:
        return NumberSeparatorFormat.commaDot;
    }
  }
}

class NumberFormatService {
  static String formatAmount({
    required double amount,
    required NumberSeparatorFormat separatorFormat,
    required int decimalDigits,
    required bool withSpace,
    String? currencySymbol,
    bool showSign = true,
  }) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final fixedStr = absAmount.toStringAsFixed(decimalDigits);
    final parts = fixedStr.split('.');
    final integerDigits = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    String formattedInteger;
    String decimalSeparator;

    switch (separatorFormat) {
      case NumberSeparatorFormat.commaDot:
        decimalSeparator = '.';
        formattedInteger = _formatStandardGrouping(integerDigits, ',');
        break;
      case NumberSeparatorFormat.dotComma:
        decimalSeparator = ',';
        formattedInteger = _formatStandardGrouping(integerDigits, '.');
        break;
      case NumberSeparatorFormat.spaceDot:
        decimalSeparator = '.';
        formattedInteger = _formatStandardGrouping(integerDigits, ' ');
        break;
      case NumberSeparatorFormat.spaceComma:
        decimalSeparator = ',';
        formattedInteger = _formatStandardGrouping(integerDigits, ' ');
        break;
      case NumberSeparatorFormat.indianLakhs:
        decimalSeparator = '.';
        formattedInteger = _formatIndianGrouping(integerDigits, ',');
        break;
    }

    String numberStr = formattedInteger;
    if (decimalDigits > 0 && decimalPart.isNotEmpty) {
      numberStr += '$decimalSeparator$decimalPart';
    }

    final signStr = isNegative ? '-' : '';
    if (currencySymbol == null || currencySymbol.isEmpty) {
      return '$signStr$numberStr';
    }

    final space = withSpace ? ' ' : '';
    return showSign ? '$signStr$currencySymbol$space$numberStr' : '$currencySymbol$space$numberStr';
  }

  static String _formatStandardGrouping(String digits, String separator) {
    return digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}$separator',
    );
  }

  static String _formatIndianGrouping(String digits, String separator) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    final remaining = digits.substring(0, digits.length - 3);
    final formattedRemaining = remaining.replaceAllMapped(
      RegExp(r'(\d{1,2})(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]}$separator',
    );
    return '$formattedRemaining$separator$last3';
  }
}

final currencyFormatterProvider = Provider<String Function(double, {bool showSign})>((ref) {
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final separatorFormat = ref.watch(numberSeparatorFormatProvider);
  final decimalDigits = ref.watch(decimalDigitsProvider);
  final withSpace = ref.watch(currencySpacingProvider);
  final symbol = worldCurrencies[baseCurrency] ?? '\$';

  return (double amount, {bool showSign = true}) {
    return NumberFormatService.formatAmount(
      amount: amount,
      separatorFormat: separatorFormat,
      decimalDigits: decimalDigits,
      withSpace: withSpace,
      currencySymbol: symbol,
      showSign: showSign,
    );
  };
});

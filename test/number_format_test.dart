import 'package:flutter_test/flutter_test.dart';
import 'package:finex/core/services/number_format_service.dart';

void main() {
  group('NumberFormatService Tests', () {
    test('Standard comma format with 2 decimals and space', () {
      final formatted = NumberFormatService.formatAmount(
        amount: 75000.00,
        separatorFormat: NumberSeparatorFormat.commaDot,
        decimalDigits: 2,
        withSpace: true,
        currencySymbol: 'Rs',
      );
      expect(formatted, 'Rs 75,000.00');
    });

    test('European period format with 2 decimals and space', () {
      final formatted = NumberFormatService.formatAmount(
        amount: 1234567.89,
        separatorFormat: NumberSeparatorFormat.dotComma,
        decimalDigits: 2,
        withSpace: true,
        currencySymbol: '€',
      );
      expect(formatted, '€ 1.234.567,89');
    });

    test('Space thousand separator with comma decimal', () {
      final formatted = NumberFormatService.formatAmount(
        amount: 54321.50,
        separatorFormat: NumberSeparatorFormat.spaceComma,
        decimalDigits: 2,
        withSpace: true,
        currencySymbol: 'kr',
      );
      expect(formatted, 'kr 54 321,50');
    });

    test('Indian Lakhs separator format', () {
      final formatted = NumberFormatService.formatAmount(
        amount: 1234567.89,
        separatorFormat: NumberSeparatorFormat.indianLakhs,
        decimalDigits: 2,
        withSpace: true,
        currencySymbol: '₹',
      );
      expect(formatted, '₹ 12,34,567.89');
    });

    test('Zero decimals rounding', () {
      final formatted = NumberFormatService.formatAmount(
        amount: 75000.45,
        separatorFormat: NumberSeparatorFormat.commaDot,
        decimalDigits: 0,
        withSpace: true,
        currencySymbol: 'Rs',
      );
      expect(formatted, 'Rs 75,000');
    });

    test('Three decimals high precision', () {
      final formatted = NumberFormatService.formatAmount(
        amount: 123.456,
        separatorFormat: NumberSeparatorFormat.commaDot,
        decimalDigits: 3,
        withSpace: true,
        currencySymbol: '\$',
      );
      expect(formatted, '\$ 123.456');
    });

    test('Negative amount sign formatting', () {
      final formatted = NumberFormatService.formatAmount(
        amount: -2500.50,
        separatorFormat: NumberSeparatorFormat.commaDot,
        decimalDigits: 2,
        withSpace: true,
        currencySymbol: '\$',
      );
      expect(formatted, '-\$ 2,500.50');
    });

    test('No space option', () {
      final formatted = NumberFormatService.formatAmount(
        amount: 75000.00,
        separatorFormat: NumberSeparatorFormat.commaDot,
        decimalDigits: 2,
        withSpace: false,
        currencySymbol: 'Rs',
      );
      expect(formatted, 'Rs75,000.00');
    });
  });
}

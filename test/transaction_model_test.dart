import 'package:flutter_test/flutter_test.dart';
import 'package:finex/features/transactions/transaction_model.dart';

void main() {
  group('Transaction & Split Model Tests', () {
    test('Transaction mapping and roundtrip serialization matches', () {
      final now = DateTime.utc(2026, 8, 26, 12, 0, 0);
      final transaction = Transaction(
        id: 'tx_123',
        flowDirection: 'INFLOW',
        transactionType: 'SALARY',
        amount: 5000.0,
        categoryId: 'salary_cat',
        accountId: 'acc_chase',
        transferTargetAccountId: null,
        baseCurrencyAmount: 5000.0,
        exchangeRate: 1.0,
        timestamp: now,
        description: 'Monthly Paycheck',
      );

      final map = transaction.toMap();
      expect(map['id'], 'tx_123');
      expect(map['flow_direction'], 'INFLOW');
      expect(map['amount'], 5000.0);
      expect(map['timestamp'], now.toIso8601String());

      final roundtrip = Transaction.fromMap(map);
      expect(roundtrip.id, 'tx_123');
      expect(roundtrip.flowDirection, 'INFLOW');
      expect(roundtrip.amount, 5000.0);
      expect(roundtrip.timestamp, now);
      expect(roundtrip.description, 'Monthly Paycheck');
    });

    test('TransactionSplit mapping and roundtrip serialization matches', () {
      final split = TransactionSplit(
        id: 'split_1',
        transactionId: 'tx_123',
        categoryId: 'tax_deduction',
        amount: 1200.0,
        flowDirection: 'OUTFLOW',
        description: 'Federal Withholding Tax',
      );

      final map = split.toMap();
      expect(map['id'], 'split_1');
      expect(map['transaction_id'], 'tx_123');
      expect(map['amount'], 1200.0);
      expect(map['flow_direction'], 'OUTFLOW');

      final roundtrip = TransactionSplit.fromMap(map);
      expect(roundtrip.id, 'split_1');
      expect(roundtrip.transactionId, 'tx_123');
      expect(roundtrip.amount, 1200.0);
      expect(roundtrip.flowDirection, 'OUTFLOW');
      expect(roundtrip.description, 'Federal Withholding Tax');
    });
  });
}

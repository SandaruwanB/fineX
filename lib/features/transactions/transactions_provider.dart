import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/db_helper.dart';
import '../accounts/accounts_provider.dart';
import 'transaction_model.dart';

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final Ref _ref;

  TransactionsNotifier(this._ref) : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final txList = await DbHelper.getTransactions();
    final List<Transaction> transactions = [];

    for (var txMap in txList) {
      final txId = txMap['id'] as String;
      final splitsList = await DbHelper.getTransactionSplits(txId);
      final splits = splitsList.map((item) => TransactionSplit.fromMap(item)).toList();
      transactions.add(Transaction.fromMap(txMap, splits: splits));
    }

    state = transactions;
  }

  Future<void> addTransaction({
    required String flowDirection,
    required String transactionType,
    required double amount,
    String? categoryId,
    required String accountId,
    String? transferTargetAccountId,
    required double baseCurrencyAmount,
    required double exchangeRate,
    required DateTime timestamp,
    String? description,
    List<TransactionSplit> splits = const [],
  }) async {
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
    final transaction = Transaction(
      id: transactionId,
      flowDirection: flowDirection,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      accountId: accountId,
      transferTargetAccountId: transferTargetAccountId,
      baseCurrencyAmount: baseCurrencyAmount,
      exchangeRate: exchangeRate,
      timestamp: timestamp,
      description: description,
    );

    final mappedSplits = splits.map((s) => s.copyWith(transactionId: transactionId)).toList();

    await DbHelper.insertTransactionWithReconciliation(
      transaction.toMap(),
      mappedSplits.map((s) => s.toMap()).toList(),
    );

    await loadTransactions();

    await _ref.read(accountsProvider.notifier).loadAccounts();
  }

  Future<void> deleteTransaction(String id) async {
    await DbHelper.deleteTransactionWithReconciliation(id);
    
    await loadTransactions();

    await _ref.read(accountsProvider.notifier).loadAccounts();
  }

  Future<double> getNetCashFlow(DateTime start, DateTime end) async {
    return await DbHelper.getNetCashFlow(
      start.toIso8601String(),
      end.toIso8601String(),
    );
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown(DateTime start, DateTime end) async {
    return await DbHelper.getCategoryBreakdown(
      start.toIso8601String(),
      end.toIso8601String(),
    );
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier(ref);
});

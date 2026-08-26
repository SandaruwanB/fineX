class Transaction {
  final String id;
  final String flowDirection; 
  final String transactionType; 
  final double amount;
  final String? categoryId; 
  final String accountId; 
  final String? transferTargetAccountId; 
  final double baseCurrencyAmount;
  final double exchangeRate;
  final DateTime timestamp;
  final String? description;
  final List<TransactionSplit> splits;

  Transaction({
    required this.id,
    required this.flowDirection,
    required this.transactionType,
    required this.amount,
    this.categoryId,
    required this.accountId,
    this.transferTargetAccountId,
    required this.baseCurrencyAmount,
    required this.exchangeRate,
    required this.timestamp,
    this.description,
    this.splits = const [],
  });

  Transaction copyWith({
    String? id,
    String? flowDirection,
    String? transactionType,
    double? amount,
    String? categoryId,
    String? accountId,
    String? transferTargetAccountId,
    double? baseCurrencyAmount,
    double? exchangeRate,
    DateTime? timestamp,
    String? description,
    List<TransactionSplit>? splits,
  }) {
    return Transaction(
      id: id ?? this.id,
      flowDirection: flowDirection ?? this.flowDirection,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      transferTargetAccountId: transferTargetAccountId ?? this.transferTargetAccountId,
      baseCurrencyAmount: baseCurrencyAmount ?? this.baseCurrencyAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      splits: splits ?? this.splits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flow_direction': flowDirection,
      'transaction_type': transactionType,
      'amount': amount,
      'category_id': categoryId,
      'account_id': accountId,
      'transfer_target_account_id': transferTargetAccountId,
      'base_currency_amount': baseCurrencyAmount,
      'exchange_rate': exchangeRate,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, {List<TransactionSplit> splits = const []}) {
    return Transaction(
      id: map['id'] as String,
      flowDirection: map['flow_direction'] as String,
      transactionType: map['transaction_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String?,
      accountId: map['account_id'] as String,
      transferTargetAccountId: map['transfer_target_account_id'] as String?,
      baseCurrencyAmount: (map['base_currency_amount'] as num).toDouble(),
      exchangeRate: (map['exchange_rate'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String?,
      splits: splits,
    );
  }
}

class TransactionSplit {
  final String id;
  final String transactionId;
  final String categoryId;
  final double amount;
  final String flowDirection; 
  final String? description;

  TransactionSplit({
    required this.id,
    required this.transactionId,
    required this.categoryId,
    required this.amount,
    required this.flowDirection,
    this.description,
  });

  TransactionSplit copyWith({
    String? id,
    String? transactionId,
    String? categoryId,
    double? amount,
    String? flowDirection,
    String? description,
  }) {
    return TransactionSplit(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      flowDirection: flowDirection ?? this.flowDirection,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'category_id': categoryId,
      'amount': amount,
      'flow_direction': flowDirection,
      'description': description,
    };
  }

  factory TransactionSplit.fromMap(Map<String, dynamic> map) {
    return TransactionSplit(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      flowDirection: map['flow_direction'] as String,
      description: map['description'] as String?,
    );
  }
}

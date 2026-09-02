import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/db_helper.dart';

class Account {
  final String id;
  final String name;
  final double balance;
  final String type; // 'checking' | 'savings' | 'credit' | 'cash'
  final Color color;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.color,
  });

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? type,
    Color? color,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type,
      'color': color.toARGB32(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: map['balance'] as double,
      type: map['type'] as String,
      color: Color(map['color'] as int),
    );
  }
}

class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier() : super([]) {
    loadAccounts();
  }

  static final List<Account> _initialAccounts = [
    Account(
      id: '1',
      name: 'Chase Checking',
      balance: 14250.40,
      type: 'checking',
      color: const Color(0xFF10B981),
    ),
    Account(
      id: '2',
      name: 'Ally Savings',
      balance: 85000.00,
      type: 'savings',
      color: const Color(0xFF3B82F6),
    ),
    Account(
      id: '3',
      name: 'Amex Gold Card',
      balance: -1240.20,
      type: 'credit',
      color: const Color(0xFFF59E0B),
    ),
  ];

  Future<void> loadAccounts() async {
    final list = await DbHelper.getAccounts();
    if (list.isEmpty) {
      for (var acc in _initialAccounts) {
        await DbHelper.insertAccount(acc.toMap());
      }
      state = _initialAccounts;
    } else {
      state = list.map((item) => Account.fromMap(item)).toList();
    }
  }

  Future<void> addAccount(String name, double balance, String type, Color color) async {
    final newAccount = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      balance: balance,
      type: type,
      color: color,
    );
    
    await DbHelper.insertAccount(newAccount.toMap());
    state = [...state, newAccount];
  }

  Future<void> deleteAccount(String id) async {
    await DbHelper.deleteAccount(id);
    state = state.where((acc) => acc.id != id).toList();
  }

  void refreshFromDatabase(List<Account> loadedAccounts) {
    state = loadedAccounts;
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>((ref) {
  return AccountsNotifier();
});

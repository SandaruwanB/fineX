import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier() : super(_initialAccounts);

  static final List<Account> _initialAccounts = [
    Account(
      id: '1',
      name: 'Chase Checking',
      balance: 14250.40,
      type: 'checking',
      color: const Color(0xFF10B981), // Emerald
    ),
    Account(
      id: '2',
      name: 'Ally Savings',
      balance: 85000.00,
      type: 'savings',
      color: const Color(0xFF3B82F6), // Blue
    ),
    Account(
      id: '3',
      name: 'Amex Gold Card',
      balance: -1240.20,
      type: 'credit',
      color: const Color(0xFFF59E0B), // Gold/Amber
    ),
  ];

  void addAccount(String name, double balance, String type, Color color) {
    final newAccount = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      balance: balance,
      type: type,
      color: color,
    );
    state = [...state, newAccount];
  }

  void deleteAccount(String id) {
    state = state.where((acc) => acc.id != id).toList();
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>((ref) {
  return AccountsNotifier();
});

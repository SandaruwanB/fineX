import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/db_helper.dart';

class Account {
  final String id;
  final String name;
  final double balance;
  final String type; // 'checking' | 'savings' | 'credit' | 'cash' | 'loan'
  final Color color;
  final bool isDefault;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.color,
    this.isDefault = false,
  });

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? type,
    Color? color,
    bool? isDefault,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type,
      'color': color.toARGB32(),
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      type: map['type'] as String,
      color: Color(map['color'] as int),
      isDefault: map['is_default'] == 1 || map['is_default'] == true,
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
      isDefault: true,
    ),
    Account(
      id: '2',
      name: 'Ally Savings',
      balance: 85000.00,
      type: 'savings',
      color: const Color(0xFF3B82F6),
      isDefault: false,
    ),
    Account(
      id: '3',
      name: 'Amex Gold Card',
      balance: -1240.20,
      type: 'credit',
      color: const Color(0xFFF59E0B),
      isDefault: false,
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
      final loaded = list.map((item) => Account.fromMap(item)).toList();
      // Ensure at least one account is marked default if list is not empty
      if (loaded.isNotEmpty && !loaded.any((a) => a.isDefault)) {
        final firstId = loaded.first.id;
        await DbHelper.setDefaultAccount(firstId);
        state = loaded.map((a) => a.id == firstId ? a.copyWith(isDefault: true) : a).toList();
      } else {
        state = loaded;
      }
    }
  }

  Future<void> setDefaultAccount(String id) async {
    await DbHelper.setDefaultAccount(id);
    state = state.map((acc) => acc.copyWith(isDefault: acc.id == id)).toList();
  }

  Future<void> addAccount(
    String name,
    double balance,
    String type,
    Color color, {
    bool isDefault = false,
  }) async {
    final willBeDefault = isDefault || state.isEmpty;
    final newAccount = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      balance: balance,
      type: type,
      color: color,
      isDefault: willBeDefault,
    );

    if (willBeDefault && state.isNotEmpty) {
      // Set all other accounts as non-default in DB
      await DbHelper.setDefaultAccount(newAccount.id);
    }

    await DbHelper.insertAccount(newAccount.toMap());

    if (willBeDefault) {
      state = [
        ...state.map((a) => a.copyWith(isDefault: false)),
        newAccount,
      ];
    } else {
      state = [...state, newAccount];
    }
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    required String type,
    required Color color,
    bool? isDefault,
  }) async {
    final existingIndex = state.indexWhere((acc) => acc.id == id);
    if (existingIndex == -1) return;

    final existing = state[existingIndex];
    final bool updatedDefault = isDefault ?? existing.isDefault;

    final updated = existing.copyWith(
      name: name,
      type: type,
      color: color,
      isDefault: updatedDefault,
    );

    if (updatedDefault && !existing.isDefault) {
      await DbHelper.setDefaultAccount(id);
      state = state.map((a) {
        if (a.id == id) {
          return updated;
        } else {
          return a.copyWith(isDefault: false);
        }
      }).toList();
    } else {
      await DbHelper.updateAccount(id, {
        'name': name,
        'type': type,
        'color': color.toARGB32(),
        'is_default': updatedDefault ? 1 : 0,
      });

      final updatedList = List<Account>.from(state);
      updatedList[existingIndex] = updated;
      state = updatedList;
    }
  }

  Future<void> deleteAccount(String id) async {
    final target = state.firstWhere((acc) => acc.id == id, orElse: () => state.first);
    final wasDefault = target.isDefault;

    await DbHelper.deleteAccount(id);
    final remaining = state.where((acc) => acc.id != id).toList();

    if (wasDefault && remaining.isNotEmpty) {
      final newDefaultId = remaining.first.id;
      await DbHelper.setDefaultAccount(newDefaultId);
      state = remaining.map((a) => a.id == newDefaultId ? a.copyWith(isDefault: true) : a).toList();
    } else {
      state = remaining;
    }
  }

  void refreshFromDatabase(List<Account> loadedAccounts) {
    state = loadedAccounts;
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>((ref) {
  return AccountsNotifier();
});
